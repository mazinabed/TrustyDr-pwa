import 'dart:async';

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
///
/// Wraps the raw Firestore docs + a `isStale` flag rather than exposing the
/// stream's error state directly through the provider's AsyncValue. Root
/// cause of the "order appears then disappears" bug (live-tested
/// 2026-07-16): this collection had NO composite index for
/// (patientId ASC, createdAt DESC) in firestore.indexes.json — the
/// query's FIRST result the Flutter Firestore Web SDK serves is an
/// optimistic LOCAL-CACHE match (which needs no server-side index and can
/// include a document the Order Details page had already cached
/// individually), but the follow-up SERVER round-trip then rejects the
/// same query with FAILED_PRECONDITION (missing index) and fires the
/// listener's onError — which previously replaced the entire page with a
/// generic error, wiping the already-visible order. The index is now
/// declared (see firestore.indexes.json), but this wrapper is kept
/// regardless: ANY future transient stream error (a permission hiccup
/// during token refresh, a network blip) must never wipe an
/// already-loaded list — it now degrades to a small stale-data notice
/// instead of a full-page error, and the app never auto-retries the same
/// broken subscription in a loop (Firestore listeners don't self-retry
/// after a hard error; a fresh subscription only starts if this
/// autoDispose provider is torn down and rebuilt, e.g. by leaving and
/// re-entering the page).
class _OrdersSnapshot {
  const _OrdersSnapshot({required this.docs, this.isStale = false});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool isStale;
}

final _myMarketplaceOrdersProvider =
    StreamProvider.autoDispose<_OrdersSnapshot>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const _OrdersSnapshot(docs: []));

  final controller = StreamController<_OrdersSnapshot>();
  var lastGoodDocs = const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  final subscription = FirebaseFirestore.instance
      .collection('marketplace_orders')
      .where('patientId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen(
    (snap) {
      lastGoodDocs = snap.docs;
      if (!controller.isClosed) {
        controller.add(_OrdersSnapshot(docs: lastGoodDocs));
      }
    },
    onError: (Object error, StackTrace stack) {
      // Sanitized — error TYPE only, never document contents/PII.
      debugPrint(
          '[marketplace_orders] live refresh failed (${error.runtimeType}); keeping ${lastGoodDocs.length} already-loaded order(s) visible.');
      if (!controller.isClosed) {
        controller.add(_OrdersSnapshot(docs: lastGoodDocs, isStale: true));
      }
    },
  );
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
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
            // Loading is only ever hit once, before the very first
            // snapshot — every later refresh (including a failed one)
            // flows through `data` with the last-known docs, never back
            // to a full-page spinner or error.
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Center(child: Text('marketplace_checkout_generic_error'.tr())),
            data: (snapshot) {
              final docs = snapshot.docs;
              final active = docs
                  .where(
                      (d) => _isActive((d.data()['status'] ?? '').toString()))
                  .toList();
              final past = docs
                  .where(
                      (d) => !_isActive((d.data()['status'] ?? '').toString()))
                  .toList();
              return Column(
                children: [
                  if (snapshot.isStale)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: Colors.black45),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'marketplace_orders_stale_notice'.tr(),
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
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
                    ),
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
    final lang = context.locale.languageCode;
    // Parsed defensively, per-order — a single malformed/legacy document
    // (e.g. one predating the storeNameEn/patientName/deliveryAddress
    // fields, or any unexpected shape) is skipped and logged, never lets
    // one bad order take down the whole list.
    final parsed = <_ParsedOrder>[];
    for (final doc in docs) {
      final order = _ParsedOrder.tryParse(doc, lang);
      if (order != null) parsed.add(order);
    }

    if (parsed.isEmpty) {
      return Center(
        child: Text(emptyLabelKey.tr(),
            style: const TextStyle(color: Colors.black54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parsed.length,
      itemBuilder: (context, index) => _OrderCard(order: parsed[index]),
    );
  }
}

/// Defensive, pre-parsed view of one marketplace_orders document — all
/// null/type handling happens once, here, via [tryParse], so the widget
/// below never touches the raw Firestore map (and can never throw from a
/// bad legacy shape during build).
class _ParsedOrder {
  const _ParsedOrder({
    required this.orderId,
    required this.name,
    required this.localStatus,
    required this.amountTotal,
    required this.currencyName,
    required this.isDelivery,
    required this.storeName,
    required this.createdAtText,
    required this.itemCount,
  });

  final String orderId;
  final String name;
  final String localStatus;
  final num? amountTotal;
  final String currencyName;
  final bool isDelivery;
  final String storeName;
  final String createdAtText;
  final int itemCount;

  static _ParsedOrder? tryParse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String lang,
  ) {
    try {
      final raw = doc.data();
      final orderRaw = raw['order'];
      final order =
          orderRaw is Map ? Map<String, dynamic>.from(orderRaw) : const {};
      final localStatus = (raw['status'] ?? '').toString();
      final name = (order['name'] ?? '').toString();
      final amountTotalRaw = order['amountTotal'];
      final amountTotal = amountTotalRaw is num ? amountTotalRaw : null;
      final currencyName = (order['currencyName'] ?? '').toString();
      final isDelivery = raw['deliveryCarrierEngineId'] != null;
      final storeNameEn = raw['storeNameEn'];
      final storeNameAr = raw['storeNameAr'];
      final storeName = (lang == 'ar'
                  ? (storeNameAr ?? storeNameEn)
                  : (storeNameEn ?? storeNameAr))
              ?.toString() ??
          '';
      final createdAt = raw['createdAt'];
      final createdAtText = createdAt is Timestamp
          ? DateFormat.yMMMd(lang).add_jm().format(createdAt.toDate())
          : '';
      final linesRaw = order['lines'];
      final requestedLines = raw['requestedLines'];
      final itemCount = linesRaw is List
          ? linesRaw.length
          : (requestedLines is List ? requestedLines.length : 0);

      return _ParsedOrder(
        orderId: doc.id,
        name: name,
        localStatus: localStatus,
        amountTotal: amountTotal,
        currencyName: currencyName,
        isDelivery: isDelivery,
        storeName: storeName,
        createdAtText: createdAtText,
        itemCount: itemCount,
      );
    } catch (e) {
      // Sanitized — doc id + error type only, never field contents.
      debugPrint(
          '[marketplace_orders] skipped unparsable order ${doc.id}: ${e.runtimeType}');
      return null;
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _ParsedOrder order;

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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarketplaceOrderDetailsPage(orderId: order.orderId),
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
                  child: Text(
                      order.name.isNotEmpty
                          ? order.name
                          : order.orderId.substring(0, 8),
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
                    _statusLabelKey(order.localStatus).tr(),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: PatientAppColors.brandTeal),
                  ),
                ),
              ],
            ),
            if (order.storeName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(order.storeName,
                  style:
                      const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
            if (order.createdAtText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(order.createdAtText,
                  style:
                      const TextStyle(fontSize: 11.5, color: Colors.black45)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(order.isDelivery ? Icons.local_shipping : Icons.storefront,
                    size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  order.isDelivery
                      ? 'marketplace_order_delivery_label'.tr()
                      : 'marketplace_order_pickup_label'.tr(),
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                if (order.itemCount > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                      'marketplace_order_item_count'
                          .tr(namedArgs: {'count': order.itemCount.toString()}),
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black54)),
                ],
              ],
            ),
            if (order.amountTotal != null) ...[
              const SizedBox(height: 6),
              Text('${order.amountTotal} ${order.currencyName}'.trim(),
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
