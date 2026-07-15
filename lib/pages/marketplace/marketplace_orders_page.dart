import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.doc, required this.orderId});

  final Map<String, dynamic> doc;
  final String orderId;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _cancelling = false;

  // Thin, patient-facing label over the locally-cached status only — no
  // per-order live Odoo read just to render a list (low-read architecture).
  // The real, live picking-state boundary is enforced server-side, in
  // cancelMarketplaceOrder itself, every time a cancellation is actually
  // attempted — never re-derived here.
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

  // Optimistic only — a confirmed order MAY still be past the real
  // fulfillment boundary; cancelMarketplaceOrder re-verifies live against
  // Odoo on every call and rejects with a clear error if it's too late
  // (surfaced via the catch block below), rather than this list
  // pre-computing a live picking state per order just to decide whether to
  // show the button.
  bool _cancellable(String localStatus) => localStatus == 'confirmed';

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('cancelMarketplaceOrder');
      await callable.call<Map<String, dynamic>>(
          <String, dynamic>{'orderId': widget.orderId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('marketplace_order_cancelled'.tr())),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.message ?? 'marketplace_checkout_generic_error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = Map<String, dynamic>.from(widget.doc['order'] as Map? ?? {});
    final localStatus = (widget.doc['status'] ?? '').toString();
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
              Text(name.isNotEmpty ? name : widget.orderId.substring(0, 8),
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
          if (_cancellable(localStatus)) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _cancelling ? null : _cancel,
                child: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('marketplace_cancel_order'.tr(),
                        style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
