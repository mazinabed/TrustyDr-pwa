import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_order_details_page.dart';
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

// Active vs Past split uses ONLY the real, deployed `status` field written
// by placeMarketplaceOrder/cancelMarketplaceOrder (pending/confirmed/
// failed/cancelled) — no invented status. 'confirmed' means the Odoo
// sale.order was created; this app has no separate fulfillment-tracking
// webhook back from Odoo yet, so a 'confirmed' order stays under Active
// for its whole lifecycle today (matching the actual deployed status
// mapping, not a guessed future one).
bool _isActive(String status) => status == 'pending' || status == 'confirmed';

class MarketplaceOrdersPage extends ConsumerStatefulWidget {
  const MarketplaceOrdersPage({super.key});

  @override
  ConsumerState<MarketplaceOrdersPage> createState() =>
      _MarketplaceOrdersPageState();
}

class _MarketplaceOrdersPageState extends ConsumerState<MarketplaceOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_myMarketplaceOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_my_orders_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: PatientAppColors.brandTeal,
          unselectedLabelColor: Colors.black45,
          indicatorColor: PatientAppColors.brandTeal,
          tabs: [
            Tab(text: 'marketplace_orders_tab_active'.tr()),
            Tab(text: 'marketplace_orders_tab_past'.tr()),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Center(child: Text('marketplace_checkout_generic_error'.tr())),
            data: (docs) {
              final active = docs
                  .where((d) => _isActive((d.data()['status'] ?? '').toString()))
                  .toList();
              final past = docs
                  .where(
                      (d) => !_isActive((d.data()['status'] ?? '').toString()))
                  .toList();
              return TabBarView(
                controller: _tabController,
                children: [
                  _OrderList(
                    docs: active,
                    emptyLabelKey: 'marketplace_no_active_orders',
                  ),
                  _OrderList(
                    docs: past,
                    emptyLabelKey: 'marketplace_no_past_orders',
                  ),
                ],
              );
            },
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

class _OrderList extends StatelessWidget {
  const _OrderList({required this.docs, required this.emptyLabelKey});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String emptyLabelKey;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Center(
        child: Text(emptyLabelKey.tr(),
            style: const TextStyle(color: Colors.black54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) =>
          _OrderCard(doc: docs[index].data(), orderId: docs[index].id),
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
    final lang = context.locale.languageCode;
    final order = Map<String, dynamic>.from(doc['order'] as Map? ?? {});
    final localStatus = (doc['status'] ?? '').toString();
    final name = (order['name'] ?? '').toString();
    final amountTotal = order['amountTotal'];
    final currencyName = (order['currencyName'] ?? '').toString();
    final isDelivery = doc['deliveryCarrierEngineId'] != null;
    final storeName = lang == 'ar'
        ? ((doc['storeNameAr'] ?? doc['storeNameEn']) ?? '').toString()
        : ((doc['storeNameEn'] ?? doc['storeNameAr']) ?? '').toString();
    final createdAt = doc['createdAt'];
    final createdAtText = createdAt is Timestamp
        ? DateFormat.yMMMd(lang).add_jm().format(createdAt.toDate())
        : '';
    final requestedLines = doc['requestedLines'];
    final itemCount = order['lines'] is List
        ? (order['lines'] as List).length
        : (requestedLines is List ? requestedLines.length : 0);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarketplaceOrderDetailsPage(orderId: orderId),
        ),
      ),
      child: Container(
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
                Expanded(
                  child: Text(name.isNotEmpty ? name : orderId.substring(0, 8),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
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
            if (storeName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(storeName,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
            if (createdAtText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(createdAtText,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isDelivery ? Icons.local_shipping : Icons.storefront,
                    size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  isDelivery
                      ? 'marketplace_order_delivery_label'.tr()
                      : 'marketplace_order_pickup_label'.tr(),
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                if (itemCount > 0) ...[
                  const SizedBox(width: 10),
                  Text('marketplace_order_item_count'.tr(
                          namedArgs: {'count': itemCount.toString()}),
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black54)),
                ],
              ],
            ),
            if (amountTotal != null) ...[
              const SizedBox(height: 6),
              Text('$amountTotal $currencyName'.trim(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('marketplace_order_view_details'.tr(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PatientAppColors.brandTeal)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 16, color: PatientAppColors.brandTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
