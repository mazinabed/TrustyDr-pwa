import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';
import 'package:trustydr/widgets/workflow_timeline.dart';

/// One order's full detail (Milestone 6 — My Orders). Reads a SINGLE
/// marketplace_orders/{orderId} document — the same provider-only,
/// patientId-scoped Firestore access pattern as the order-list page, never
/// a runtime join to any other collection (Odoo's sale.order confirmation
/// data is already denormalized onto this doc's own `order` field at
/// placeMarketplaceOrder time — firestore-safety.md §7). A live status read
/// (getMarketplaceOrderStatus) is layered on top ONLY on this single-order
/// details screen — appropriate here (one document, patient-initiated),
/// never done from the list page (low-read architecture).
///
/// A single-document `.doc().snapshots()` needs no composite index (unlike
/// the order-list page's query), so it isn't exposed to that specific
/// failure mode — but the same "never wipe an already-loaded screen on a
/// transient refresh error" rule still applies, so errors keep the last
/// good snapshot instead of flipping the page to "not found."
final _orderDetailsProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>?, String>((ref, orderId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  final controller =
      StreamController<DocumentSnapshot<Map<String, dynamic>>?>();
  DocumentSnapshot<Map<String, dynamic>>? lastGood;

  final subscription = FirebaseFirestore.instance
      .collection('marketplace_orders')
      .doc(orderId)
      .snapshots()
      .listen(
    (snap) {
      lastGood = snap;
      if (!controller.isClosed) controller.add(snap);
    },
    onError: (Object error, StackTrace stack) {
      debugPrint(
          '[marketplace_order_details] live refresh failed (${error.runtimeType}); keeping last known snapshot.');
      if (!controller.isClosed) controller.add(lastGood);
    },
  );
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Live Odoo state/pickingState — read once per page visit, only for a
/// 'confirmed' order. Failure degrades to showing the locally-cached status
/// only (never blocks the rest of the page from rendering).
final _liveStatusProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, orderId) async {
  try {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getMarketplaceOrderStatus');
    final result = await callable
        .call<Map<String, dynamic>>(<String, dynamic>{'orderId': orderId});
    final live = result.data['live'];
    return live is Map ? Map<String, dynamic>.from(live) : null;
  } catch (_) {
    return null;
  }
});

class MarketplaceOrderDetailsPage extends ConsumerWidget {
  const MarketplaceOrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(_orderDetailsProvider(orderId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_order_details_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = docAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Center(child: Text('marketplace_checkout_generic_error'.tr())),
            data: (snap) {
              final user = FirebaseAuth.instance.currentUser;
              final data = snap?.data();
              // Belt-and-suspenders on top of the Firestore rule itself —
              // never render another patient's order even transiently.
              if (data == null ||
                  user == null ||
                  data['patientId'] != user.uid) {
                return Center(
                    child: Text('marketplace_order_details_not_found'.tr()));
              }
              return _OrderDetailsBody(orderId: orderId, data: data);
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

class _OrderDetailsBody extends ConsumerWidget {
  const _OrderDetailsBody({required this.orderId, required this.data});

  final String orderId;
  final Map<String, dynamic> data;

  String _fmt(num? v) {
    if (v == null) return '';
    final d = v.toDouble();
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }

  /// Safe numeric coercion — `as num?` throws on a non-null, non-num value
  /// (a real risk for a legacy/malformed document); `is num` never does.
  num? _num(dynamic v) => v is num ? v : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      return _buildBody(context, ref);
    } catch (e) {
      // One malformed/legacy order must not crash the whole page — log
      // sanitized (error type + orderId only, never field contents) and
      // fall back to a minimal, still-useful view.
      debugPrint(
          '[marketplace_order_details] failed to render order $orderId: ${e.runtimeType}');
      return Center(child: Text('marketplace_order_details_not_found'.tr()));
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final orderRaw = data['order'];
    final order =
        orderRaw is Map ? Map<String, dynamic>.from(orderRaw) : const {};
    final localStatus = (data['status'] ?? '').toString();
    final isDelivery = data['deliveryCarrierEngineId'] != null;
    final deliveryAddressRaw = data['deliveryAddress'];
    final deliveryAddress = deliveryAddressRaw is Map
        ? Map<String, dynamic>.from(deliveryAddressRaw)
        : null;
    final storeName = lang == 'ar'
        ? ((data['storeNameAr'] ?? data['storeNameEn']) ?? '').toString()
        : ((data['storeNameEn'] ?? data['storeNameAr']) ?? '').toString();
    final createdAt = data['createdAt'];
    final createdAtText = createdAt is Timestamp
        ? DateFormat.yMMMd(context.locale.languageCode)
            .add_jm()
            .format(createdAt.toDate())
        : '';
    final currencyName = (order['currencyName'] ?? '').toString();
    final linesRaw = order['lines'];
    final lines = linesRaw is List
        ? linesRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];
    final liveStatusAsync = localStatus == 'confirmed'
        ? ref.watch(_liveStatusProvider(orderId))
        : null;
    // Phase 2 (Workflow & Notification Platform) -- the pharmacy operations
    // fulfillment stage (accepted/preparing/readyForPickup/outForDelivery/
    // completed, or a terminal rejected/cancelled/deliveryFailed), already
    // written by pharmacyOrderActions.js onto this SAME document (never a
    // separate read/collection -- see fulfillmentStatusHistory below). This
    // is distinct from `status` above, which only tracks the order's own
    // Odoo confirmation state (pending/confirmed/failed/cancelled), not the
    // pharmacy's operational queue.
    final fulfillmentStatus = (data['fulfillmentStatus'] ?? '').toString();
    final fulfillmentHistoryRaw = data['fulfillmentStatusHistory'];
    final fulfillmentHistory = fulfillmentHistoryRaw is List
        ? fulfillmentHistoryRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      (order['name'] ?? orderId).toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabelKeyPublic(localStatus).tr(),
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: PatientAppColors.brandTeal),
                    ),
                  ),
                ],
              ),
              if (storeName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(storeName,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
              if (createdAtText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(createdAtText,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(isDelivery ? Icons.local_shipping : Icons.storefront,
                      size: 15, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    isDelivery
                        ? 'marketplace_order_delivery_label'.tr()
                        : 'marketplace_order_pickup_label'.tr(),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (fulfillmentStatus.isNotEmpty && fulfillmentStatus != 'new') ...[
          const SizedBox(height: 16),
          Text('marketplace_order_progress_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildFulfillmentTimeline(
              fulfillmentStatus: fulfillmentStatus,
              isDelivery: isDelivery,
              lastUpdatedAt: fulfillmentHistory.isNotEmpty
                  ? fulfillmentHistory.last['at']
                  : null,
              context: context,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (lines.isNotEmpty) ...[
          Text('marketplace_order_details_items_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: lines
                  .map((l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (l['name'] ?? '').toString(),
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ),
                            Text('x${l['quantity'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Colors.black54)),
                            const SizedBox(width: 10),
                            Text(
                              '${_fmt(_num(l['priceTotal']))} $currencyName'
                                  .trim(),
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _row('marketplace_checkout_subtotal_label'.tr(),
                  '${_fmt(_num(order['amountUntaxed']))} $currencyName'.trim()),
              const SizedBox(height: 6),
              _row('marketplace_order_details_tax_label'.tr(),
                  '${_fmt(_num(order['amountTax']))} $currencyName'.trim()),
              const SizedBox(height: 6),
              _row(
                'marketplace_checkout_delivery_fee_label'.tr(),
                order['deliveryAmount'] != null
                    ? '${_fmt(_num(order['deliveryAmount']))} $currencyName'
                        .trim()
                    : 'marketplace_checkout_free'.tr(),
              ),
              const Divider(height: 20),
              _row(
                'marketplace_checkout_total_label'.tr(),
                '${_fmt(_num(order['amountTotal']))} $currencyName'.trim(),
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('marketplace_order_details_contact_section'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((data['patientName'] ?? '').toString(),
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${'marketplace_order_details_contact_phone'.tr()}: '
                '${(deliveryAddress?['phone'] ?? data['patientPhone'] ?? '').toString()}',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ],
          ),
        ),
        if (isDelivery && deliveryAddress != null) ...[
          const SizedBox(height: 16),
          Text('marketplace_order_details_delivery_address_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${deliveryAddress['province'] ?? ''}, ${deliveryAddress['city'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text((deliveryAddress['full'] ?? '').toString(),
                    style:
                        const TextStyle(fontSize: 12.5, color: Colors.black54)),
                if ((deliveryAddress['note'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text((deliveryAddress['note'] ?? '').toString(),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ],
            ),
          ),
        ] else if (!isDelivery) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.black38),
              const SizedBox(width: 6),
              Expanded(
                child: Text('marketplace_order_details_pickup_notice'.tr(),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ),
            ],
          ),
        ],
        if (localStatus == 'confirmed' && liveStatusAsync != null) ...[
          const SizedBox(height: 16),
          Text('marketplace_order_details_status_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          liveStatusAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (live) {
              final labelKey = _liveStatusLabelKey(
                (live?['state'])?.toString(),
                (live?['pickingState'])?.toString(),
              );
              if (labelKey == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labelKey.tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 20),
        // Self-cancellation is intentionally disabled (2026-07-16 Odoo
        // action_cancel reliability issue — see cancelMarketplaceOrder's own
        // doc comment in doctor_functions). No Cancel button here.
        Row(
          children: [
            const Icon(Icons.support_agent, size: 16, color: Colors.black38),
            const SizedBox(width: 6),
            Expanded(
              child: Text('marketplace_order_details_cancel_notice'.tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ),
          ],
        ),
      ],
    );
  }

  // Phase 2 (Workflow & Notification Platform) -- generic WorkflowTimeline,
  // fed the pharmacy fulfillment stage list. Pickup and delivery orders
  // diverge after 'preparing' (readyForPickup vs outForDelivery), matching
  // pharmacyOrderActions.js's own two paths. Terminal negative outcomes
  // (rejected/cancelled/deliveryFailed) render as a single distinct row
  // instead of a partial happy-path stepper.
  static const _terminalStages = {'rejected', 'cancelled', 'deliveryFailed'};

  Widget _buildFulfillmentTimeline({
    required String fulfillmentStatus,
    required bool isDelivery,
    required dynamic lastUpdatedAt,
    required BuildContext context,
  }) {
    Widget timeline;
    if (_terminalStages.contains(fulfillmentStatus)) {
      final labelKey = switch (fulfillmentStatus) {
        'rejected' => 'marketplace_order_stage_rejected',
        'deliveryFailed' => 'marketplace_order_stage_delivery_failed',
        _ => 'marketplace_order_stage_cancelled',
      };
      timeline = WorkflowTimeline(terminalLabel: labelKey.tr());
    } else {
      timeline = WorkflowTimeline(
        currentStage: fulfillmentStatus,
        steps: [
          WorkflowTimelineStep(
            key: 'accepted',
            label: 'marketplace_order_stage_accepted'.tr(),
          ),
          WorkflowTimelineStep(
            key: 'preparing',
            label: 'marketplace_order_stage_preparing'.tr(),
          ),
          isDelivery
              ? WorkflowTimelineStep(
                  key: 'outForDelivery',
                  label: 'marketplace_order_stage_out_for_delivery'.tr(),
                )
              : WorkflowTimelineStep(
                  key: 'readyForPickup',
                  label: 'marketplace_order_stage_ready_for_pickup'.tr(),
                ),
          WorkflowTimelineStep(
            key: 'completed',
            label: 'marketplace_order_stage_completed'.tr(),
          ),
        ],
      );
    }

    final updatedText = lastUpdatedAt is Timestamp
        ? DateFormat.yMMMd(context.locale.languageCode)
            .add_jm()
            .format(lastUpdatedAt.toDate())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        timeline,
        if (updatedText != null) ...[
          const SizedBox(height: 4),
          Text(
            'marketplace_order_last_updated'.tr(args: [updatedText]),
            style: const TextStyle(fontSize: 11.5, color: Colors.black45),
          ),
        ],
      ],
    );
  }

  String _statusLabelKeyPublic(String s) {
    switch (s) {
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

  // Maps Odoo's own native sale.order.state + stock.picking.state (Odoo 17
  // — no 'done' state on sale.order; the delivery/fulfillment signal lives
  // entirely on the picking) to a LOCALIZED supplementary label — never
  // raw Odoo strings shown to the patient. This is purely supplementary
  // detail layered on top of the primary, always-localized status badge
  // above (driven by our own `status` field); it never changes Active/Past
  // bucketing. Verified against odooDriver.ts's own getSalesOrderStatus
  // (reads sale.order.state + the first linked stock.picking.state) rather
  // than guessed. Both pickup and delivery orders get a stock.picking on
  // confirmation (Odoo creates one for any stockable product regardless of
  // delivery carrier) — pickup vs delivery is distinguished by the
  // separate is_delivery order line + partner_shipping_id, not by picking
  // presence, so this mapping intentionally does not vary by isDelivery.
  String? _liveStatusLabelKey(String? state, String? pickingState) {
    if (state == 'cancel') return 'marketplace_live_status_cancelled';
    if (state == 'sale') {
      if (pickingState == 'done') return 'marketplace_live_status_fulfilled';
      if (pickingState == 'assigned') return 'marketplace_live_status_ready';
      // null/draft/waiting/confirmed all mean stock hasn't been fully
      // reserved/handed over yet — still "being prepared."
      return 'marketplace_live_status_preparing';
    }
    // draft/sent (pre-confirmation) never reaches the patient — every
    // order created by createPatientOrder is action_confirm'd immediately.
    return null;
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 14.5 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: bold ? Colors.black87 : Colors.black54,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
