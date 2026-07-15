import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/login_signup/login.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
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

/// Compact "Shop by Category" chip rail — a handful of category tiles (icon
/// + label) plus a trailing "All Categories" tile that opens the full
/// [MarketplaceAllCategoriesPage] browser. This is the ONE shared
/// implementation for every screen that offers a category shortcut —
/// never a per-screen icon grid reinvented from scratch. Real marketplaces
/// never expose the full taxonomy at a browse entry point (Noon/iHerb
/// audit) — callers are expected to pass an already-capped, featured-only
/// list, not the full category set.
class MarketplaceCategoryChips extends StatelessWidget {
  const MarketplaceCategoryChips({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    required this.onOpenAllCategories,
    this.showAllCategoriesTile = true,
  });

  final List<MarketplaceCategory> categories;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onOpenAllCategories;
  // False when the caller's full available set already fits entirely in
  // [categories] — showing "All Categories" would just re-open a browser
  // with nothing new in it (e.g. a small store with 3 top-level categories
  // and no subcategories at all).
  final bool showAllCategoriesTile;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 640 ? 6 : 4;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...categories.map(
                (c) => _CategoryChip(
                  icon: marketplaceCategoryIcon(c.iconKey),
                  label: c.localizedName(lang),
                  onTap: () => onCategoryTap(c.categoryKey),
                ),
              ),
              if (showAllCategoriesTile)
                _CategoryChip(
                  icon: Icons.apps_rounded,
                  label: 'marketplace_all_categories'.tr(),
                  onTap: onOpenAllCategories,
                  emphasized: true,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emphasized
                  ? PatientAppColors.brandTeal
                  : PatientAppColors.brandTeal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: emphasized ? Colors.white : PatientAppColors.brandTeal,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
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
              PositionedDirectional(
                top: 12,
                start: 12,
                child: SafeArea(
                  bottom: false,
                  child: _BackButton(),
                ),
              ),
              PositionedDirectional(
                start: 16,
                bottom: -28,
                child: Container(
                  width: 72,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'marketplace_verified_pharmacy'.tr(),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                ],
              ),
              if (city != null && city!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 13, color: Colors.black38),
                    const SizedBox(width: 3),
                    Text(
                      city!,
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black45),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                    label: 'marketplace_product_count'
                        .tr(namedArgs: {'count': productCount.toString()}),
                    emphasized: true,
                  ),
                  if (categoryCount > 0) ...[
                    const SizedBox(width: 6),
                    _StatChip(
                      label: 'marketplace_category_count'
                          .tr(namedArgs: {'count': categoryCount.toString()}),
                    ),
                  ],
                ],
              ),
            ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: emphasized
            ? PatientAppColors.brandTeal.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: emphasized ? PatientAppColors.brandTeal : Colors.black54,
        ),
      ),
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
