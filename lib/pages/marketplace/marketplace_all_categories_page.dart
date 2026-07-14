import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Full-screen hierarchical category browser for a single store: top-level
/// category -> subcategories -> (tap) filters the Store page's product
/// grid and pops back. Used when a store has too many categories/
/// subcategories to fit the compact "Shop by Category" grid on the Store
/// page header. RTL-correct via the ambient Directionality (no hardcoded
/// TextDirection anywhere here).
class MarketplaceAllCategoriesPage extends StatelessWidget {
  const MarketplaceAllCategoriesPage({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  final List<MarketplaceCategory> categories;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final topLevel = categories.where((c) => c.parentEngineId == null).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'marketplace_all_categories'.tr(),
                showBack: true,
                height: 110,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.apps_rounded,
                        color: PatientAppColors.brandTeal,
                      ),
                      title: Text(
                        'marketplace_all_categories'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        onCategorySelected(null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ...topLevel.map(
                      (top) => _CategoryExpansionTile(
                        category: top,
                        allCategories: categories,
                        lang: lang,
                        onCategorySelected: (id) {
                          onCategorySelected(id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

class _CategoryExpansionTile extends StatelessWidget {
  const _CategoryExpansionTile({
    required this.category,
    required this.allCategories,
    required this.lang,
    required this.onCategorySelected,
  });

  final MarketplaceCategory category;
  final List<MarketplaceCategory> allCategories;
  final String lang;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final children = allCategories
        .where((c) => c.parentEngineId == category.engineId)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    if (children.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.category_outlined, color: Colors.black45),
        title: Text(category.localizedName(lang)),
        onTap: () => onCategorySelected(category.engineId),
      );
    }

    return ExpansionTile(
      leading: const Icon(Icons.category_outlined, color: Colors.black45),
      title: Text(
        category.localizedName(lang),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        ListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 32, end: 16),
          title: Text(
            'marketplace_all_categories'.tr(),
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          onTap: () => onCategorySelected(category.engineId),
        ),
        ...children.map(
          (sub) => ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 32, end: 16),
            title: Text(sub.localizedName(lang)),
            onTap: () => onCategorySelected(sub.engineId),
          ),
        ),
      ],
    );
  }
}
