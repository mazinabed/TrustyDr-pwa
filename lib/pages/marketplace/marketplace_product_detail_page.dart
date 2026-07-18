import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_action.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_image_gallery.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Product details (Patient Marketplace). All display fields come from the
/// already-fetched [MarketplaceProduct] (the Marketplace projection, never
/// a fresh Odoo/Commerce read here) — the same "never trust the cache at
/// order time" law applies once this product reaches checkout, enforced
/// server-side, not on this page.
///
/// Add to Cart is guest-allowed (Phase 1 rule: "Guests can browse and may
/// build a local cart") — no [ensureMarketplaceLogin] gate here. Only
/// checkout itself is auth-gated.
class MarketplaceProductDetailPage extends ConsumerStatefulWidget {
  const MarketplaceProductDetailPage({super.key, required this.product});

  final MarketplaceProduct product;

  @override
  ConsumerState<MarketplaceProductDetailPage> createState() =>
      _MarketplaceProductDetailPageState();
}

class _MarketplaceProductDetailPageState
    extends ConsumerState<MarketplaceProductDetailPage> {
  int _quantity = 1;

  bool get _outOfStock => widget.product.availabilityBadge == 'out_of_stock';

  Future<void> _addToCart() async {
    final lang = context.locale.languageCode;
    final storeName = widget.product.localizedStoreName(lang) ?? '';
    final notifier = ref.read(marketplaceCartProvider.notifier);

    try {
      await notifier.addItem(
        product: widget.product,
        storeNameEn: widget.product.storeNameEn ?? storeName,
        storeNameAr: widget.product.storeNameAr ?? storeName,
        quantity: _quantity,
      );
      _showAddedSnackBar();
    } on CartStoreConflictException catch (e) {
      if (!mounted) return;
      final currentName = lang == 'ar' && e.currentStoreNameAr.isNotEmpty
          ? e.currentStoreNameAr
          : e.currentStoreNameEn;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('marketplace_cart_switch_store_title'.tr()),
          content: Text('marketplace_cart_switch_store_body'
              .tr(namedArgs: {'store': currentName})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('marketplace_cart_switch_store_confirm'.tr()),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await notifier.replaceCartWith(
          product: widget.product,
          storeNameEn: widget.product.storeNameEn ?? storeName,
          storeNameAr: widget.product.storeNameAr ?? storeName,
          quantity: _quantity,
        );
        _showAddedSnackBar();
      }
    }
  }

  void _showAddedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Expanded(child: Text('marketplace_added_to_cart'.tr())),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceCartPage()),
              ),
              child: Text(
                'marketplace_view_cart'.tr(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = _ProductDetailBody(product: widget.product);
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!_outOfStock) ...[
                _QuantityStepper(
                  quantity: _quantity,
                  onChanged: (q) => setState(() => _quantity = q),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _outOfStock
                          ? Colors.grey[300]
                          : PatientAppColors.brandTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _outOfStock ? null : _addToCart,
                    child: Text(
                      _outOfStock
                          ? 'marketplace_availability_out_of_stock'.tr()
                          : 'marketplace_add_to_cart'.tr(),
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final MarketplaceProduct product;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final price = product.displayPrice.toStringAsFixed(
      product.displayPrice.truncateToDouble() == product.displayPrice ? 0 : 2,
    );
    final currency = product.currencyName ?? '';
    final galleryImageUrls =
        product.galleryImageUrls.where((u) => u.startsWith('http')).toList();
    final name = product.localizedName(lang);
    final description = product.localizedDescription(lang);
    final categoryName = product.localizedCategoryName(lang);
    final storeName = product.localizedStoreName(lang);
    // Only the single-image height (300) grows when a thumbnail strip is
    // actually shown — a 1-image (or 0-image) product's header looks
    // exactly as it did before this feature.
    final expandedHeight = galleryImageUrls.length > 1 ? 364.0 : 300.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          backgroundColor: Colors.white,
          leading: BackButton(
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 4),
              child: MarketplaceCartAction(iconColor: Colors.black87),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background:
                MarketplaceProductImageGallery(imageUrls: galleryImageUrls),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brandName != null && product.brandName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      product.brandName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PatientAppColors.brandTeal,
                      ),
                    ),
                  ),
                if (storeName != null && storeName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      storeName,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black45),
                    ),
                  ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$price $currency'.trim(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: PatientAppColors.brandTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (product.availabilityL10nKey.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PatientAppColors.statusConfirmed
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.availabilityL10nKey.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PatientAppColors.statusConfirmed,
                          ),
                        ),
                      ),
                  ],
                ),
                if (categoryName != null && categoryName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryName,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'marketplace_product_description'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
