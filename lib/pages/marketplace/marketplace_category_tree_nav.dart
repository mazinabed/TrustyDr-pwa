import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';

/// Shared hierarchical category navigation — real `parentCategoryKey` tree
/// (Shared Marketplace Category Engine, 2026-07-14), "All Products" at the
/// top, expandable top-level categories with their subcategories,
/// selected-item highlight, optional per-category product counts (computed
/// once by the caller from already-fetched data, never a per-category
/// backend call). Used both as the mobile bottom-sheet/drawer content and as
/// the desktop persistent sidebar's content — same widget, different
/// container. Scrolls internally, so it scales to dozens of
/// categories/subcategories without needing a redesign.
class MarketplaceCategoryTreeNav extends StatefulWidget {
  const MarketplaceCategoryTreeNav({
    super.key,
    required this.categories,
    required this.selectedCategoryKey,
    required this.onSelect,
    this.productCountByCategoryKey,
  });

  final List<MarketplaceCategory> categories;
  final String? selectedCategoryKey;
  final ValueChanged<String?> onSelect;
  final Map<String, int>? productCountByCategoryKey;

  @override
  State<MarketplaceCategoryTreeNav> createState() =>
      _MarketplaceCategoryTreeNavState();
}

class _MarketplaceCategoryTreeNavState
    extends State<MarketplaceCategoryTreeNav> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand the branch containing the currently-selected category so
    // it's visible on open, not hidden behind a collapsed parent.
    if (widget.selectedCategoryKey != null) {
      final selected = widget.categories
          .where((c) => c.categoryKey == widget.selectedCategoryKey)
          .toList();
      if (selected.isNotEmpty && selected.first.parentCategoryKey != null) {
        _expanded.add(selected.first.parentCategoryKey!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final topLevel = widget.categories
        .where((c) => c.parentCategoryKey == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _NavTile(
          label: 'marketplace_all_products'.tr(),
          selected: widget.selectedCategoryKey == null,
          onTap: () => widget.onSelect(null),
        ),
        const Divider(height: 1),
        ...topLevel.map((top) {
          final children = widget.categories
              .where((c) => c.parentCategoryKey == top.categoryKey)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final isExpanded = _expanded.contains(top.categoryKey);
          final count = widget.productCountByCategoryKey?[top.categoryKey];

          if (children.isEmpty) {
            return _NavTile(
              label: top.localizedName(lang),
              selected: widget.selectedCategoryKey == top.categoryKey,
              trailingCount: count,
              onTap: () => widget.onSelect(top.categoryKey),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavTile(
                label: top.localizedName(lang),
                selected: widget.selectedCategoryKey == top.categoryKey,
                trailingCount: count,
                expandable: true,
                expanded: isExpanded,
                onTap: () => widget.onSelect(top.categoryKey),
                onExpandTap: () => setState(() {
                  if (isExpanded) {
                    _expanded.remove(top.categoryKey);
                  } else {
                    _expanded.add(top.categoryKey);
                  }
                }),
              ),
              if (isExpanded)
                ...children.map(
                  (sub) => _NavTile(
                    label: sub.localizedName(lang),
                    selected: widget.selectedCategoryKey == sub.categoryKey,
                    trailingCount:
                        widget.productCountByCategoryKey?[sub.categoryKey],
                    indent: true,
                    onTap: () => widget.onSelect(sub.categoryKey),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingCount,
    this.indent = false,
    this.expandable = false,
    this.expanded = false,
    this.onExpandTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? trailingCount;
  final bool indent;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onExpandTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PatientAppColors.brandTeal.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: indent ? 40 : 20,
            end: 12,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: indent ? 13.5 : 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? PatientAppColors.brandTeal : Colors.black87,
                  ),
                ),
              ),
              if (trailingCount != null) ...[
                const SizedBox(width: 8),
                Text(
                  '$trailingCount',
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
              if (expandable) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onExpandTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Product counts per category (including that category's own descendants),
/// computed once from already-fetched data — never a per-category backend
/// call.
Map<String, int> computeCategoryProductCounts(
  List<MarketplaceCategory> categories,
  List<MarketplaceProduct> products,
) {
  final result = <String, int>{};
  for (final c in categories) {
    final keys = descendantCategoryKeys(categories, c.categoryKey);
    result[c.categoryKey] = products
        .where((p) => p.categoryKeys.any((k) => keys.contains(k)))
        .length;
  }
  return result;
}
