import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_checkout_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart'
    show MarketplaceLogoFallback;
import 'package:trustydr/pages/marketplace/marketplace_widgets.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Review Cart (Milestone 6). Purely a view over [marketplaceCartProvider]'s
/// local (shared_preferences) state — no server call happens here. Prices
/// shown are the DISPLAY-ONLY cached values from when each item was added;
/// clearly labeled as an estimate, since the real total is only known once
/// Odoo revalidates live at checkout (never trusted from this screen).
class MarketplaceCartPage extends ConsumerWidget {
  const MarketplaceCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(marketplaceCartProvider);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_cart_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = cart.isEmpty
              ? _EmptyCart(lang: lang)
              : _CartBody(cart: cart, lang: lang);
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              'marketplace_cart_empty'.tr(),
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart, required this.lang});

  final Cart cart;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(marketplaceCartProvider.notifier);
    final storeName = cart.localizedStoreName(lang) ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (storeName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 18, color: PatientAppColors.brandTeal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ...cart.items.map((item) => _CartItemTile(
                    item: item,
                    lang: lang,
                    onQuantityChanged: (q) => notifier.updateQuantity(
                        item.productEngineId, item.variantEngineId, q),
                    onRemove: () => notifier.removeItem(
                        item.productEngineId, item.variantEngineId),
                  )),
            ],
          ),
        ),
        _CartSummaryBar(cart: cart),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.lang,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final String lang;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name =
        lang == 'ar' && item.nameAr.isNotEmpty ? item.nameAr : item.nameEn;
    final price = item.displayPrice.toStringAsFixed(
      item.displayPrice.truncateToDouble() == item.displayPrice ? 0 : 2,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: (item.imageUrl ?? '').startsWith('http')
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const MarketplaceLogoFallback(),
                  )
                : const MarketplaceLogoFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                // Milestone 5 (Patient Product Experience) — the exact
                // variant this line represents (e.g. "Size: Medium, Color:
                // Black"), display-only, never used for identity.
                if ((item.variantLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.variantLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
                const SizedBox(height: 4),
                Text('$price ${item.currencyName ?? ''}'.trim(),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PatientAppColors.brandTeal)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.black38),
                onPressed: onRemove,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => onQuantityChanged(item.quantity - 1),
                  ),
                  Text('${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.estimatedSubtotal.toStringAsFixed(
      cart.estimatedSubtotal.truncateToDouble() == cart.estimatedSubtotal
          ? 0
          : 2,
    );
    final currency =
        cart.items.isNotEmpty ? (cart.items.first.currencyName ?? '') : '';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('marketplace_cart_estimated_subtotal'.tr(),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                Text('$subtotal $currency'.trim(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
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
                onPressed: () async {
                  if (!await ensureMarketplaceLogin(context)) return;
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const MarketplaceCheckoutPage(),
                    ),
                  );
                },
                child: Text('marketplace_proceed_to_checkout'.tr(),
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
