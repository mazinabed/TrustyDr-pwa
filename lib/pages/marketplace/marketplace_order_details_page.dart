import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// One order's full detail (Milestone 6 — My Orders). Reads a SINGLE
/// marketplace_orders/{orderId} document — the same provider-only,
/// patientId-scoped Firestore access pattern as the order-list page, never
/// a runtime join to any other collection (Odoo's sale.order confirmation
/// data is already denormalized onto this doc's own `order` field at
/// placeMarketplaceOrder time — firestore-safety.md §7). A live status read
/// (getMarketplaceOrderStatus) is layered on top ONLY on this single-order
/// details screen — appropriate here (one document, patient-initiated),
/// never done from the list page (low-read architecture).
final _orderDetailsProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>?, String>((ref, orderId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('marketplace_orders')
      .doc(orderId)
      .snapshots();
});

/// Live Odoo state/pickingState — read once per page visit, only for a
/// 'confirmed' order. Failure degrades to showing the locally-cached status
/// only (never blocks the rest of the page from rendering).
final _liveStatusProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, orderId) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final order = Map<String, dynamic>.from(data['order'] as Map? ?? {});
    final localStatus = (data['status'] ?? '').toString();
    final isDelivery = data['deliveryCarrierEngineId'] != null;
    final deliveryAddress = data['deliveryAddress'] is Map
        ? Map<String, dynamic>.from(data['deliveryAddress'] as Map)
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
    final lines = order['lines'] is List
        ? List<Map<String, dynamic>>.from(
            (order['lines'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
        : const <Map<String, dynamic>>[];
    final liveStatusAsync = localStatus == 'confirmed'
        ? ref.watch(_liveStatusProvider(orderId))
        : null;

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
              if (createdAtText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(createdAtText,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
                              '${_fmt(l['priceTotal'] as num?)} $currencyName'
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
                  '${_fmt(order['amountUntaxed'] as num?)} $currencyName'.trim()),
              const SizedBox(height: 6),
              _row('marketplace_order_details_tax_label'.tr(),
                  '${_fmt(order['amountTax'] as num?)} $currencyName'.trim()),
              const SizedBox(height: 6),
              _row(
                'marketplace_checkout_delivery_fee_label'.tr(),
                order['deliveryAmount'] != null
                    ? '${_fmt(order['deliveryAmount'] as num?)} $currencyName'.trim()
                    : 'marketplace_checkout_free'.tr(),
              ),
              const Divider(height: 20),
              _row(
                'marketplace_checkout_total_label'.tr(),
                '${_fmt(order['amountTotal'] as num?)} $currencyName'.trim(),
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
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
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
            data: (live) => live == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${live['state'] ?? ''} · ${live['pickingState'] ?? ''}'
                          .trim(),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
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
