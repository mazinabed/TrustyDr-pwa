import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/login_signup/login.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_action.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart'
    show MarketplaceBannerGradient, MarketplaceLogoFallback;

/// Marketplace Design System (established 2026-07-15): shared building
/// blocks every commerce screen (Marketplace Home, Pharmacy Store, and
/// future Category/Search/Product-Detail/Cart/Checkout/Orders screens)
/// reuses, instead of each screen growing its own near-duplicate widget.
/// Before this file, [MarketplaceSection] and the category-tile grid each
/// had two independent, drifting copies (one on the landing page, one on
/// the Store page) — exactly the "second UI system" problem this file
/// exists to prevent.

/// A titled content section with a "View All" affordance — every
/// horizontal-rail/grid section on Home and the Store page (Popular
/// Products, Featured Stores, Shop by Category, All Products) is one of
/// these, so the header typography/spacing/View-All treatment can never
/// drift between screens.
class MarketplaceSection extends StatelessWidget {
  const MarketplaceSection({
    super.key,
    required this.title,
    required this.child,
    this.onViewAll,
    this.viewAllLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;

  @override
  Widget build(BuildContext context) {
    // Consistent 20px inter-section rhythm across every commerce screen —
    // spacing reads as one deliberate system, not accumulated one-off gaps.
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      viewAllLabel ?? 'marketplace_view_all'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PatientAppColors.brandTeal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Storefront-identity page header — the Pharmacy Store page's equivalent
/// of [MarketplaceStoreCard]'s banner+logo anatomy, scaled up to a full
/// header. Deliberately NOT [TrustyDrCurvedHeader] (this app's generic
/// curved header, used across doctor/patient/appointment screens) — reusing
/// it here is exactly what made the Store page feel like a healthcare
/// provider profile instead of a shop. [bannerUrl]/[logoUrl]/[city] are
/// optional because not every call site has them today (the pharmacy
/// provider profile's "Visit Store" button only has providerId/orgId/name,
/// no Commerce-side store metadata) — falls back to the same gradient/icon
/// treatment [MarketplaceStoreCard] uses when missing, never a blank or
/// clinical-looking header.
class MarketplaceStoreHeader extends StatelessWidget {
  const MarketplaceStoreHeader({
    super.key,
    required this.storeName,
    this.bannerUrl,
    this.logoUrl,
    this.city,
    required this.productCount,
    required this.categoryCount,
  });

  final String storeName;
  final String? bannerUrl;
  final String? logoUrl;
  final String? city;
  final int productCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final banner = (bannerUrl ?? '').trim();
    final logo = (logoUrl ?? bannerUrl ?? '').trim();

    // 2026-07-19 header restructure (Issue 1) — the pharmacy name, logo,
    // and verification badge now live INSIDE the gradient/banner area
    // itself, alongside the existing back/cart actions, instead of a
    // separate large white identity block below. The gradient's height is
    // organic (sized to its own back/cart row + logo/name row content, via
    // Stack's "non-positioned child sizes the Stack" rule) rather than a
    // fixed 96px — it grows just enough to hold what's actually in it.
    // Below the gradient, only a single compact metadata line remains
    // (see _StoreMetaLine) — city/product-count/category-count merged into
    // one line with separators rather than three stacked pills/rows, so
    // the first product collection sits noticeably higher on the page.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: banner.startsWith('http')
                  ? Image.network(
                      banner,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const MarketplaceBannerGradient(),
                    )
                  : const MarketplaceBannerGradient(),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BackButton(),
                        const Spacer(),
                        MarketplaceCartAction(
                          chipBackground: Colors.black.withValues(alpha: 0.28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: logo.startsWith('http')
                              ? Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const MarketplaceLogoFallback(),
                                )
                              : const MarketplaceLogoFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'marketplace_verified_pharmacy'.tr(),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: _StoreMetaLine(
            city: city,
            productCount: productCount,
            categoryCount: categoryCount,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Compact single-line store metadata (2026-07-19 Issue 1) — replaces the
/// old two-`_StatChip`-pill row plus a separate city row with ONE line of
/// subtle text joined by " · " separators (city · N products · N
/// categories, whichever are present). Wraps to a second line gracefully on
/// narrow widths rather than truncating — deliberately not three stacked
/// pills/chips per the explicit "prefer subtle text with separators"
/// direction. Counts use accent (brand teal) weight so they read as the
/// notable part of the line without becoming large chips of their own.
class _StoreMetaLine extends StatelessWidget {
  const _StoreMetaLine({
    required this.city,
    required this.productCount,
    required this.categoryCount,
  });

  final String? city;
  final int productCount;
  final int categoryCount;

  static const _labelStyle = TextStyle(fontSize: 12.5, color: Colors.black54);
  static const _accentStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: PatientAppColors.brandTeal,
  );
  static const _dotStyle = TextStyle(fontSize: 12.5, color: Colors.black26);

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[];
    void addSegment(String text, TextStyle style) {
      if (segments.isNotEmpty) {
        segments.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: _dotStyle),
        ));
      }
      segments.add(Text(text, style: style));
    }

    if (city != null && city!.isNotEmpty) {
      addSegment(city!, _labelStyle);
    }
    addSegment(
      'marketplace_product_count'
          .tr(namedArgs: {'count': productCount.toString()}),
      _accentStyle,
    );
    if (categoryCount > 0) {
      addSegment(
        'marketplace_category_count'
            .tr(namedArgs: {'count': categoryCount.toString()}),
        _accentStyle,
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments,
    );
  }
}

/// Marketplace login gate — for PROTECTED actions only (Cart, Checkout,
/// Orders, prescriptions, saved addresses, order history/tracking,
/// payments). NEVER call this to gate browsing: Marketplace Home, stores,
/// categories, products, and search must all work for guests (2026-07-15
/// public-browse milestone — see marketplace_providers.dart's header,
/// where the old page-load auth gate that threw
/// MarketplaceAuthRequiredException was removed entirely).
///
/// Reuses this app's EXISTING tap-time login-gate mechanism rather than
/// inventing a Marketplace-specific one — same `login_required_title` /
/// `login_required_body` / `go_to_login` keys and the same
/// bottom-sheet-then-push-LoginScreen() shape as profile.dart's
/// `_showLoginSheet()` (the closest thing this codebase has to a shared
/// pattern, though it was private to that screen) — restyled with
/// Marketplace's own teal branding rather than copying profile.dart's
/// indigo verbatim, matching every other Marketplace Design System
/// component's identity.
///
/// KNOWN LIMITATION, inherited from the existing pattern, not introduced
/// here: LoginScreen's own post-login navigation
/// (`Navigator.pushAndRemoveUntil(..., BottomBar(), (_) => false)`) clears
/// the entire nav stack and lands the user on the app's generic Home shell
/// — it does not resume the original action (e.g. re-add the item that was
/// in the cart). Fixing that is a LoginScreen-wide change affecting every
/// caller of this pattern, not a Marketplace-only concern, and is out of
/// scope for establishing the access boundary itself.
///
/// Returns true if already logged in (caller proceeds immediately). Returns
/// false after showing the prompt (caller must NOT proceed — the guest is
/// being sent to sign in, not completing the action right now).
Future<bool> ensureMarketplaceLogin(BuildContext context) async {
  if (FirebaseAuth.instance.currentUser != null) return true;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _MarketplaceLoginRequiredSheet(),
  );
  return false;
}

class _MarketplaceLoginRequiredSheet extends StatelessWidget {
  const _MarketplaceLoginRequiredSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: PatientAppColors.brandTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 26, color: PatientAppColors.brandTeal),
          ),
          const SizedBox(height: 14),
          Text(
            'login_required_title'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'login_required_body'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientAppColors.brandTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const LoginScreen(),
                  ),
                );
              },
              child: Text(
                'go_to_login'.tr(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
