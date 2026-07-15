import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Full Stores browse (Patient Marketplace, Phase 1C, browse-only). Reached
/// via "View All" on the landing page's "Stores Near You" section. Takes
/// already-fetched data — never a new network call.
class MarketplaceStoresPage extends StatefulWidget {
  const MarketplaceStoresPage({super.key, required this.data});

  final MarketplaceBrowseData data;

  @override
  State<MarketplaceStoresPage> createState() => _MarketplaceStoresPageState();
}

class _MarketplaceStoresPageState extends State<MarketplaceStoresPage> {
  String _searchQuery = '';

  String? _categorySummaryFor(String orgId, String lang) {
    final names = <String>{};
    for (final p in widget.data.products) {
      if (p.orgId != orgId) continue;
      final name = p.localizedCategoryName(lang);
      if (name != null && name.isNotEmpty) names.add(name);
      if (names.length >= 2) break;
    }
    return names.isEmpty ? null : names.join(' · ');
  }

  int _categoryCountFor(String orgId) {
    return distinctCategoryCount(
      widget.data.products.where((p) => p.orgId == orgId).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    var stores = widget.data.stores;
    if (_searchQuery.trim().length >= 2) {
      final q = _searchQuery.trim().toLowerCase();
      stores = stores
          .where((s) => s.localizedName(lang).toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'marketplace_tab_stores'.tr(),
                showBack: true,
                height: 120,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MarketplaceSearchBar(
                  hintText: 'marketplace_search_stores'.tr(),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: stores.isEmpty
                    ? Center(
                        child: Text(
                          'marketplace_no_stores_found'.tr(),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final crossAxisCount =
                              gridConstraints.maxWidth >= 1000
                                  ? 3
                                  : gridConstraints.maxWidth >= 640
                                      ? 2
                                      : 1;
                          if (crossAxisCount == 1) {
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: stores.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: MarketplaceStoreCard(
                                  store: stores[i],
                                  categorySummary: _categorySummaryFor(
                                      stores[i].orgId, lang),
                                  categoryCount:
                                      _categoryCountFor(stores[i].orgId),
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 238,
                            ),
                            itemCount: stores.length,
                            itemBuilder: (context, i) => MarketplaceStoreCard(
                              store: stores[i],
                              categorySummary:
                                  _categorySummaryFor(stores[i].orgId, lang),
                              categoryCount: _categoryCountFor(stores[i].orgId),
                            ),
                          );
                        },
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
