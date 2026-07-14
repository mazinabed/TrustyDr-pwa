import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Product details (Patient Marketplace, Phase 1C, browse-only). No cart,
/// no "add to order" — this milestone stops at browsing. All fields come
/// from the already-fetched [MarketplaceProduct] (the Marketplace
/// projection), never a fresh Odoo/Commerce read.
class MarketplaceProductDetailPage extends StatelessWidget {
  const MarketplaceProductDetailPage({super.key, required this.product});

  final MarketplaceProduct product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = _ProductDetailBody(product: product);
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
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
    final url = (product.imageUrl ?? '').trim();
    final name = product.localizedName(lang);
    final description = product.localizedDescription(lang);
    final categoryName = product.localizedCategoryName(lang);
    final storeName = product.localizedStoreName(lang);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.white,
          leading: BackButton(
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: url.startsWith('http')
                ? Container(
                    color: const Color(0xFFF5F6F8),
                    padding: const EdgeInsets.all(24),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderImage(),
                    ),
                  )
                : _placeholderImage(),
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

  Widget _placeholderImage() {
    return Container(
      color: PatientAppColors.brandTeal.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.medication_outlined,
          color: PatientAppColors.brandTeal.withValues(alpha: 0.4),
          size: 64,
        ),
      ),
    );
  }
}
