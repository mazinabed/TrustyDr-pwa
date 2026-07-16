import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_page.dart';

/// Persistent Cart entry point (Milestone 6) — the ONE shared cart icon +
/// badge every Marketplace screen reuses (Home, Store, All Products,
/// Categories, Product Details), so there is always a visible way back to
/// the Cart beyond the post-add-to-cart SnackBar shortcut (that shortcut
/// stays as a convenience, this is the primary, always-available entry
/// point). Given its own file (not marketplace_widgets.dart) specifically
/// so it can import marketplace_cart_page.dart directly without that file
/// needing to import this one back — marketplace_cart_page.dart already
/// imports marketplace_widgets.dart for ensureMarketplaceLogin, so keeping
/// this widget separate avoids a circular import between the two.
///
/// Badge shows TOTAL QUANTITY across all cart lines (not distinct product
/// count) — matches Cart.totalQuantity exactly, never recomputed here.
/// Hidden entirely when the cart is empty. Reactive via a plain
/// ref.watch(marketplaceCartProvider) — updates immediately on add/
/// remove/quantity-change/clear/guest-cart-restore-from-shared_preferences,
/// with no extra plumbing, since all of those are just state changes on
/// the same provider.
class MarketplaceCartAction extends ConsumerWidget {
  const MarketplaceCartAction({
    super.key,
    this.iconColor = Colors.white,
    this.chipBackground,
    this.compact = false,
  });

  /// Icon (and badge border) color. Defaults to white for use over the
  /// Marketplace Design System's teal/gradient headers.
  final Color iconColor;

  /// If set, renders as a circular translucent chip — matching this
  /// design system's own back-button chip style (see
  /// marketplace_widgets.dart's private `_BackButton`) — instead of a bare
  /// `IconButton`. Use this variant when the header sits directly over a
  /// photo/banner image, where a plain icon would have poor, inconsistent
  /// contrast; omit it (the default) for solid-color headers/app bars.
  final Color? chipBackground;

  /// Shrinks the tap target to a fixed 36x36 with zero padding (vs.
  /// IconButton's default ~48x48) — for tight, shared header contexts
  /// (TrustyDrCurvedHeader) that already reserve a fixed side width for
  /// the back button and must not visually crowd a centered title.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(marketplaceCartProvider).totalQuantity;
    final isChip = chipBackground != null;

    final icon = Icon(
      Icons.shopping_cart_outlined,
      color: iconColor,
      size: isChip ? 18 : (compact ? 20 : 24),
    );

    final Widget button = isChip
        ? Material(
            color: chipBackground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openCart(context),
              child: Padding(padding: const EdgeInsets.all(8), child: icon),
            ),
          )
        : compact
            ? SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: icon,
                  onPressed: () => _openCart(context),
                ),
              )
            : IconButton(icon: icon, onPressed: () => _openCart(context));

    if (count <= 0) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(
          end: isChip ? -2 : 4,
          top: isChip ? -2 : 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const MarketplaceCartPage(),
      ),
    );
  }
}
