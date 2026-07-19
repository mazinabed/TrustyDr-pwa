import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Milestone 5 (Marketplace Home / Pharmacy Store Home category-nav
/// refinement, 2026-07-19) — the ONE reusable compact category navigation
/// bar both pages use, replacing the large circular-icon "Shop by Category"
/// chip grid ([MarketplaceCategoryChips]) with a single-row, text-only
/// strip: a fixed "All Categories" entry point that never scrolls, plus
/// the rest of the categories in a horizontally-scrolling row beside it.
///
/// Deliberately presentation-only — it takes an already-resolved list of
/// [CommerceCategoryNavItem] (categoryKey + localized display name, both
/// resolved by the CALLER from whichever category source is correct for
/// that page: Marketplace Home's own featured/top-level set, or Pharmacy
/// Store Home's [storeAvailableCategories]-derived set) and two callbacks.
/// It fetches nothing, sorts nothing, and filters nothing — every "which
/// categories, in what order, scoped to what" decision stays entirely with
/// the caller, exactly like [CommerceCollectionSection] before it.
class CommerceCategoryNavItem {
  const CommerceCategoryNavItem({
    required this.categoryKey,
    required this.label,
  });

  final String categoryKey;
  final String label;
}

class CommerceCategoryNavBar extends StatelessWidget {
  const CommerceCategoryNavBar({
    super.key,
    required this.categories,
    required this.selectedCategoryKey,
    required this.onCategoryTap,
    required this.onAllCategoriesTap,
  });

  final List<CommerceCategoryNavItem> categories;
  // null means "All Categories" is the active/neutral entry (nothing
  // filtered yet) — the same convention both pages' own
  // selectedCategoryKey state already uses.
  final String? selectedCategoryKey;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onAllCategoriesTap;

  static const double _height = 46.0;

  // 2026-07-19 theme refinement (Issue 2) — the near-black navy surface
  // read as off-brand and disconnected from the rest of the patient app's
  // teal-blue identity. Replaced with a soft brand-tinted light surface
  // (Option B) rather than a second teal->blue gradient, since the
  // Pharmacy Store Home header immediately above this bar is ITSELF being
  // restructured into a gradient in this same pass — stacking two
  // gradients back to back would compete rather than integrate. A subtle
  // tint reads as "part of the same page" on both Marketplace Home (plain
  // white background) and Pharmacy Store Home (white body below the
  // header gradient).
  static const Color _surfaceColor = Color(0xFFEAF5F3);
  static const Color _dividerColor = Color(0xFFCFE6E2);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Fixed entry point — never inside the scrolling ListView, so it
          // can never move with the rest of the strip. Sits at the
          // logical BEGINNING of the bar in both directions: Row already
          // reverses child order under RTL Directionality automatically,
          // so this stays first (visually rightmost in RTL, leftmost in
          // LTR) with no special-casing here.
          _NavItem(
            label: 'marketplace_all_categories'.tr(),
            selected: selectedCategoryKey == null,
            onTap: onAllCategoriesTap,
            emphasized: true,
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsetsDirectional.only(end: 2),
            color: _dividerColor,
          ),
          Expanded(
            child: categories.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final item = categories[i];
                      return _NavItem(
                        label: item.label,
                        selected: selectedCategoryKey == item.categoryKey,
                        onTap: () => onCategoryTap(item.categoryKey),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One text-only nav entry — no icon, single line, ellipsis rather than
/// wrapping (a category strip must never grow to a second row). Active
/// state is a teal underline + teal text, deliberately NOT a filled pill
/// (a pill would grow the bar's height for no real gain — the explicit
/// "do not use a large pill that increases bar height" requirement).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  // "All Categories" stays at full dark-text emphasis even when not the
  // active filter (it's always a valid, permanent entry point) — every
  // other category dims slightly when not selected, matching a real
  // nav-bar hierarchy rather than every label competing at equal weight.
  final bool emphasized;

  // 2026-07-19 theme refinement — dark text on the new light tinted
  // surface (was white-on-navy). Deliberately not pure black: a softened
  // near-navy keeps the same brand character the rest of the app uses for
  // body text on light backgrounds.
  static const Color _inactiveEmphasized = Color(0xFF1F2A44);
  static const Color _inactiveMuted = Color(0xFF5B6B74);

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? PatientAppColors.brandTeal
        : (emphasized ? _inactiveEmphasized : _inactiveMuted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    selected ? PatientAppColors.brandTeal : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected || emphasized ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
