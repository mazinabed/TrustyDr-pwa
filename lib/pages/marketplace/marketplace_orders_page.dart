import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Order History / tracking (Milestone 6). marketplace_orders is the
/// patient-facing order projection Healthcare itself owns and writes
/// server-side (placeMarketplaceOrder/cancelMarketplaceOrder) — reading it
/// directly via a Firestore stream, scoped by patientId, is the SAME
/// provider-only-Firestore-access pattern this app already uses for
/// appointments; this is not a new architectural exception, and it never
/// touches Commerce/Odoo directly (ADR-C002). The Firestore rule
/// (`resource.data.patientId == request.auth.uid`) is what actually
/// enforces the scoping — this query is a convenience, not the security
/// boundary.
final _myMarketplaceOrdersProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('marketplace_orders')
      .where('patientId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs);
});

class MarketplaceOrdersPage extends ConsumerWidget {
  const MarketplaceOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_myMarketplaceOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_my_orders_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Center(child: Text('marketplace_checkout_generic_error'.tr())),
            data: (docs) => docs.isEmpty
                ? Center(
                    child: Text('marketplace_no_orders'.tr(),
                        style: const TextStyle(color: Colors.black54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _OrderCard(
                        doc: docs[index].data(), orderId: docs[index].id),
                  ),
          );
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.doc, required this.orderId});

  final Map<String, dynamic> doc;
  final String orderId;

  // Thin, patient-facing label over the locally-cached status only — no
  // per-order live Odoo read just to render a list (low-read architecture).
  String _statusLabelKey(String localStatus) {
    switch (localStatus) {
      case 'pending':
        return 'marketplace_order_status_pending';
      case 'failed':
        return 'marketplace_order_status_failed';
      case 'cancelled':
        return 'marketplace_order_status_cancelled';
      case 'confirmed':
        return 'marketplace_order_status_preparing';
      default:
        return 'marketplace_order_status_preparing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = Map<String, dynamic>.from(doc['order'] as Map? ?? {});
    final localStatus = (doc['status'] ?? '').toString();
    final name = (order['name'] ?? '').toString();
    final amountTotal = order['amountTotal'];
    final currencyName = (order['currencyName'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.isNotEmpty ? name : orderId.substring(0, 8),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PatientAppColors.brandTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabelKey(localStatus).tr(),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: PatientAppColors.brandTeal),
                ),
              ),
            ],
          ),
          if (amountTotal != null) ...[
            const SizedBox(height: 6),
            Text('$amountTotal $currencyName'.trim(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
          // Patient self-cancellation is intentionally NOT wired to
          // cancelMarketplaceOrder here (2026-07-16): a real Odoo issue
          // means sale.order.action_cancel() does not reliably flip the
          // order's own state even when the backend correctly refuses to
          // report a false success (see doctor_functions'
          // cancelMarketplaceOrder — it now safely errors rather than
          // lying, but a genuine self-service cancel still can't be
          // guaranteed to work end-to-end). Show a contact-the-pharmacy
          // notice instead of a non-functional or misleading button until
          // that root cause is resolved.
          if (localStatus == 'confirmed') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Text('marketplace_contact_pharmacy_to_cancel'.tr(),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
