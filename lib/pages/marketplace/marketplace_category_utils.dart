import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

/// Maps a Category Engine `iconKey` (see
/// trustydr-commerce/scripts/taxonomy/starter-taxonomy.mjs for the full,
/// authored set) to a real Flutter icon — proven marketplaces (Noon, iHerb)
/// give each shopping category a distinct, recognizable icon rather than one
/// generic icon repeated everywhere. Falls back to a neutral category icon
/// for any key not yet mapped, so a future taxonomy addition never breaks.
IconData marketplaceCategoryIcon(String? iconKey) {
  switch (iconKey) {
    case 'medication':
      return Icons.medication_outlined;
    case 'vitamins':
      return Icons.spa_outlined;
    case 'first_aid':
      return Icons.health_and_safety_outlined;
    case 'devices':
      return Icons.monitor_heart_outlined;
    case 'diabetes':
      return Icons.bloodtype_outlined;
    case 'mobility':
      return Icons.accessible_outlined;
    case 'respiratory':
      return Icons.air_outlined;
    case 'baby':
      return Icons.child_care_outlined;
    case 'personal_care':
      return Icons.clean_hands_outlined;
    case 'beauty':
      return Icons.face_retouching_natural_outlined;
    case 'dermatology':
      return Icons.face_outlined;
    case 'hair':
      return Icons.content_cut_outlined;
    case 'eye':
      return Icons.visibility_outlined;
    case 'ent':
      return Icons.hearing_outlined;
    case 'dental':
      return Icons.sentiment_satisfied_outlined;
    case 'womens_health':
      return Icons.female_outlined;
    case 'mens_health':
      return Icons.male_outlined;
    case 'wellness':
      return Icons.favorite_outline;
    case 'nutrition':
      return Icons.restaurant_outlined;
    case 'fitness':
      return Icons.fitness_center_outlined;
    case 'elderly':
      return Icons.elderly_outlined;
    case 'lab':
      return Icons.science_outlined;
    case 'professional':
      return Icons.medical_services_outlined;
    case 'household':
      return Icons.home_outlined;
    case 'travel':
      return Icons.flight_takeoff_outlined;
    default:
      return Icons.category_outlined;
  }
}

/// A category plus every descendant subcategory's categoryKey — the current
/// taxonomy is 2 levels deep, but this walks the full parentCategoryKey
/// chain so it stays correct if deeper nesting is added later. Shared by the
/// Marketplace landing page's Categories tab and a single Store page's
/// category navigation. Shared Marketplace Category Engine (2026-07-14) —
/// keyed on the stable categoryKey, never the raw Odoo engineId.
Set<String> descendantCategoryKeys(
  List<MarketplaceCategory> categories,
  String rootCategoryKey,
) {
  final result = <String>{rootCategoryKey};
  var frontier = <String>{rootCategoryKey};
  while (frontier.isNotEmpty) {
    final next = categories
        .where((c) =>
            c.parentCategoryKey != null &&
            frontier.contains(c.parentCategoryKey))
        .map((c) => c.categoryKey)
        .toSet();
    next.removeWhere(result.contains);
    result.addAll(next);
    frontier = next;
  }
  return result;
}

/// Count of distinct categories a set of products (typically one store's
/// catalog) is assigned to — the single shared implementation for the
/// "N categories" stat shown on store cards, the store header, and
/// anywhere else that needs it, rather than a bespoke count computed
/// independently per call site (Marketplace Design System, 2026-07-15).
int distinctCategoryCount(List<MarketplaceProduct> products) {
  final keys = <String>{};
  for (final p in products) {
    keys.addAll(p.categoryKeys);
  }
  return keys.length;
}

/// The subset of shared category definitions actually represented by a
/// specific store's published products — NEVER the global featured set.
/// A category is included if at least one of [products] carries it in
/// [MarketplaceProduct.categoryKeys], OR if it's an ancestor of a category
/// that does (so a parent always shows whenever any descendant has a
/// product) — the exact mirror-image walk of [descendantCategoryKeys].
/// Backend already filters [allCategories] to isActive-only
/// (getMarketplaceCatalogForHealthcare/getActiveMarketplaceStoresForHealthcare
/// both query `.where("isActive", "==", true)`), so no client-side active
/// check is needed here. Never returns a duplicate (Set-backed) and never
/// returns a category with zero products anywhere in its own subtree.
///
/// Marketplace Home uses the global `featured` flag instead — this is
/// deliberately a SEPARATE, store-scoped concept, both reading from the
/// same shared Category Engine definitions and localized names (Shared
/// Marketplace Category Engine, 2026-07-15) — not a second category system.
List<MarketplaceCategory> storeAvailableCategories(
  List<MarketplaceProduct> products,
  List<MarketplaceCategory> allCategories,
) {
  final byKey = {for (final c in allCategories) c.categoryKey: c};
  final directKeys = <String>{};
  for (final p in products) {
    directKeys.addAll(p.categoryKeys);
  }

  final available = <String>{};
  for (final key in directKeys) {
    var cursor = key;
    while (available.add(cursor)) {
      final parent = byKey[cursor]?.parentCategoryKey;
      if (parent == null) break;
      cursor = parent;
    }
  }

  return allCategories.where((c) => available.contains(c.categoryKey)).toList();
}
