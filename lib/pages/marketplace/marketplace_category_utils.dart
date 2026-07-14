import 'package:trustydr/core/providers/marketplace_providers.dart';

/// A category plus every descendant subcategory's engineId — one level of
/// nesting today (Odoo's public_categ_ids tree in this dataset is shallow),
/// but walks the full parentEngineId chain so it stays correct if deeper
/// nesting is added later. Shared by the Marketplace landing page's
/// Categories tab and a single Store page's category navigation.
Set<String> descendantCategoryIds(
  List<MarketplaceCategory> categories,
  String rootEngineId,
) {
  final result = <String>{rootEngineId};
  var frontier = <String>{rootEngineId};
  while (frontier.isNotEmpty) {
    final next = categories
        .where((c) =>
            c.parentEngineId != null && frontier.contains(c.parentEngineId))
        .map((c) => c.engineId)
        .toSet();
    next.removeWhere(result.contains);
    result.addAll(next);
    frontier = next;
  }
  return result;
}
