import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_order_details_page.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Marketplace Platform Phase 3 (Multi-Seller Cart + Split Checkout,
/// 2026-08-15) — shown once a split checkout finishes placing MORE THAN ONE
/// order (a single-seller checkout never reaches this page at all; it
/// still lands directly on [MarketplaceOrderDetailsPage], exactly as
/// before this phase — see marketplace_checkout_page.dart's own header).
///
/// Every order in [orderIds] is already confirmed on the backend by the
/// time this page is reached — this is a summary/navigation hub only, never
/// a retry or place-order surface itself. A one-time (not live-streamed)
/// read per order, bounded by how many sellers were in that ONE checkout
/// attempt (small N, matches the low-read architecture law — this is not a
/// recurring list read).
class _OrderSummary {
  const _OrderSummary({
    required this.orderId,
    required this.storeNameEn,
    required this.storeNameAr,
    required this.orderName,
    required this.amountTotal,
    required this.currencyName,
  });

  final String orderId;
  final String? storeNameEn;
  final String? storeNameAr;
  final String? orderName;
  final double? amountTotal;
  final String? currencyName;

  String? localizedStoreName(String lang) {
    if (lang == 'ar' && (storeNameAr ?? '').isNotEmpty) return storeNameAr;
    return (storeNameEn ?? '').isNotEmpty ? storeNameEn : storeNameAr;
  }
}

final _orderSummariesProvider = FutureProvider.autoDispose
    .family<List<_OrderSummary>, List<String>>((ref, orderIds) async {
  final docs = await Future.wait(orderIds.map(
    (id) => FirebaseFirestore.instance
        .collection('marketplace_orders')
        .doc(id)
        .get(),
  ));
  return [
    for (var i = 0; i < orderIds.length; i++)
      if (docs[i].data() case final data?)
        _OrderSummary(
          orderId: orderIds[i],
          storeNameEn: data['storeNameEn']?.toString(),
          storeNameAr: data['storeNameAr']?.toString(),
          orderName: (data['order'] is Map)
              ? (data['order'] as Map)['name']?.toString()
              : null,
          amountTotal: (data['order'] is Map &&
                  (data['order'] as Map)['amountTotal'] is num)
              ? ((data['order'] as Map)['amountTotal'] as num).toDouble()
              : null,
          currencyName: (data['order'] is Map)
              ? (data['order'] as Map)['currencyName']?.toString()
              : null,
        )
      else
        _OrderSummary(
          orderId: orderIds[i],
          storeNameEn: null,
          storeNameAr: null,
          orderName: null,
          amountTotal: null,
          currencyName: null,
        ),
  ];
});

class MarketplaceMultiOrderSummaryPage extends ConsumerWidget {
  const MarketplaceMultiOrderSummaryPage({super.key, required this.orderIds});

  final List<String> orderIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final summariesAsync = ref.watch(_orderSummariesProvider(orderIds));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_multi_order_summary_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = _SummaryBody(
            orderIds: orderIds,
            summariesAsync: summariesAsync,
            lang: lang,
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

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.orderIds,
    required this.summariesAsync,
    required this.lang,
  });

  final List<String> orderIds;
  final AsyncValue<List<_OrderSummary>> summariesAsync;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle,
                  size: 40, color: PatientAppColors.statusConfirmed),
              const SizedBox(height: 12),
              Text(
                'marketplace_multi_order_summary_heading'
                    .tr(namedArgs: {'count': '${orderIds.length}'}),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PatientAppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'marketplace_multi_order_summary_subheading'.tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        Expanded(
          child: summariesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            // A read failure never hides the orders themselves — every
            // orderId is already known and each is individually reachable
            // via its own order-details page, so this degrades to a plain
            // list of ids rather than blocking the confirmation entirely.
            error: (_, __) => _OrderList(
              summaries: orderIds
                  .map((id) => _OrderSummary(
                        orderId: id,
                        storeNameEn: null,
                        storeNameAr: null,
                        orderName: null,
                        amountTotal: null,
                        currencyName: null,
                      ))
                  .toList(),
              lang: lang,
            ),
            data: (summaries) => _OrderList(summaries: summaries, lang: lang),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientAppColors.brandTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text('marketplace_multi_order_summary_done'.tr(),
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.summaries, required this.lang});

  final List<_OrderSummary> summaries;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: summaries.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = summaries[i];
        final storeName = s.localizedStoreName(lang) ?? '';
        final total = s.amountTotal;
        final priceText = total == null
            ? null
            : '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} ${s.currencyName ?? ''}'
                .trim();

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MarketplaceOrderDetailsPage(orderId: s.orderId),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long,
                        size: 20, color: PatientAppColors.brandTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName.isEmpty
                              ? (s.orderName ?? s.orderId)
                              : storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        if (s.orderName != null) ...[
                          const SizedBox(height: 2),
                          Text(s.orderName!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ],
                    ),
                  ),
                  if (priceText != null) ...[
                    Text(priceText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: PatientAppColors.brandTeal,
                        )),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.black38),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
