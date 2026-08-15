// lib/core/providers/marketplace_cart_provider.dart
//
// Milestone 6 (Cart, Checkout, Order Creation), extended by Marketplace
// Platform Phase 3 (Multi-Seller Cart + Split Checkout, 2026-08-15) — the
// cart still lives entirely client-side (shared_preferences, already a
// dependency and the established pattern for this kind of persisted local
// state — see home.dart's saved-location persistence), guest or
// signed-in alike. It never syncs to Firestore and is never the price/stock
// authority: every field cached here (displayPrice, currencyName, nameEn/
// nameAr, imageUrl) is DISPLAY-ONLY, sourced from the same Marketplace
// projection the rest of this app already treats as non-authoritative. The
// actual order-time live revalidation happens server-side (Healthcare ->
// Commerce -> Odoo, already built) — this file adds no new trust boundary.
//
// Phase 3 — one-store-per-cart RETIRED: this was always a Phase 1 TEMPORARY
// constraint, never permanent architecture (see the Marketplace Platform
// roadmap's own "Temporary Constraints" section). The cart may now hold
// items from any number of distinct sellers (orgId) at once. Each
// [CartItem] now carries its OWN [orgId]/[storeNameEn]/[storeNameAr] —
// previously these lived once at the [Cart] level, implicitly shared by
// every item, which is exactly what made more than one seller impossible to
// represent. [CartStoreConflictException] and [CartNotifier.replaceCartWith]
// are removed entirely: adding an item from a different store than what's
// already in the cart is no longer an error, it simply adds a new seller
// group. See [Cart.sellerGroups] (the multi-seller Cart/Checkout UI's own
// source of truth for "how many sellers, which items belong to which") and
// marketplace_checkout_page.dart's own header for how checkout splits a
// multi-seller cart into one independent Odoo order PER SELLER — never one
// cross-seller order (permanent architecture law, unchanged by this phase).
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

class CartItem {
  const CartItem({
    required this.orgId,
    required this.storeNameEn,
    required this.storeNameAr,
    required this.productEngineId,
    this.variantEngineId,
    this.variantLabel,
    required this.nameEn,
    required this.nameAr,
    required this.displayPrice,
    required this.currencyName,
    required this.imageUrl,
    required this.quantity,
  });

  // Phase 3 — the seller this line belongs to. Every line in a cart used to
  // implicitly share the single Cart-level orgId; now each line carries its
  // own, which is what makes a multi-seller cart representable at all.
  final String orgId;
  final String storeNameEn;
  final String storeNameAr;

  final String productEngineId;
  // Milestone 5 (Patient Product Experience, 2026-07-19) — explicit variant
  // identity, threaded straight through to EngineCheckoutLine.variantEngineId
  // (already optional/supported server-side since Milestone 2, Variant
  // Identity — see marketplaceCheckout.ts). Null for a single-variant
  // product: the backend's own resolveVariantDecision safely auto-selects
  // the one sellable variant when no explicit id is submitted, so this is
  // never guessed client-side, only ever set when the patient actually
  // resolved one exact variant on the detail page (see
  // MarketplaceProductDetail.resolveVariant).
  final String? variantEngineId;
  // Display-only summary of the selected attribute values (e.g. "Size:
  // Medium, Color: Black") for the cart/checkout line UI — never sent to
  // the backend, never used for identity (variantEngineId is).
  final String? variantLabel;
  final String nameEn;
  final String nameAr;
  final double displayPrice;
  final String? currencyName;
  final String? imageUrl;
  final int quantity;

  /// Two cart lines are the "same line" only when the seller, product, AND
  /// selected variant all match — two different variants of the same
  /// product must coexist as separate lines (explicit QA requirement),
  /// never merge quantities into one; and (Phase 3) the SAME engineId at
  /// two different sellers must never be treated as one line either, since
  /// engineId is only unique per-seller (per-Odoo-company), not globally.
  bool sameLineAs(String otherOrgId, String otherProductEngineId,
          String? otherVariantEngineId) =>
      orgId == otherOrgId &&
      productEngineId == otherProductEngineId &&
      variantEngineId == otherVariantEngineId;

  CartItem copyWith({int? quantity}) => CartItem(
        orgId: orgId,
        storeNameEn: storeNameEn,
        storeNameAr: storeNameAr,
        productEngineId: productEngineId,
        variantEngineId: variantEngineId,
        variantLabel: variantLabel,
        nameEn: nameEn,
        nameAr: nameAr,
        displayPrice: displayPrice,
        currencyName: currencyName,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
      );

  double get estimatedLineTotal => displayPrice * quantity;

  Map<String, dynamic> toJson() => {
        'orgId': orgId,
        'storeNameEn': storeNameEn,
        'storeNameAr': storeNameAr,
        'productEngineId': productEngineId,
        'variantEngineId': variantEngineId,
        'variantLabel': variantLabel,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'displayPrice': displayPrice,
        'currencyName': currencyName,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        orgId: j['orgId']?.toString() ?? '',
        storeNameEn: j['storeNameEn']?.toString() ?? '',
        storeNameAr: j['storeNameAr']?.toString() ?? '',
        productEngineId: j['productEngineId']?.toString() ?? '',
        variantEngineId: j['variantEngineId']?.toString(),
        variantLabel: j['variantLabel']?.toString(),
        nameEn: j['nameEn']?.toString() ?? '',
        nameAr: j['nameAr']?.toString() ?? '',
        displayPrice: (j['displayPrice'] is num)
            ? (j['displayPrice'] as num).toDouble()
            : 0.0,
        currencyName: j['currencyName']?.toString(),
        imageUrl: j['imageUrl']?.toString(),
        quantity: (j['quantity'] is num) ? (j['quantity'] as num).toInt() : 1,
      );
}

/// Phase 3 — every cart line belonging to ONE seller, grouped for display
/// (Cart page) and for checkout orchestration (one independent order per
/// group — see marketplace_checkout_page.dart). Never persisted directly;
/// always derived fresh from [Cart.sellerGroups].
class CartSellerGroup {
  const CartSellerGroup({
    required this.orgId,
    required this.storeNameEn,
    required this.storeNameAr,
    required this.items,
  });

  final String orgId;
  final String storeNameEn;
  final String storeNameAr;
  final List<CartItem> items;

  double get subtotal =>
      items.fold(0.0, (sum, i) => sum + i.estimatedLineTotal);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  String? localizedStoreName(String lang) {
    if (lang == 'ar' && storeNameAr.isNotEmpty) return storeNameAr;
    return storeNameEn.isNotEmpty ? storeNameEn : storeNameAr;
  }
}

class Cart {
  const Cart({required this.items});

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  /// Display-only estimate for the Review Cart screen — never the price of
  /// record. The real total (per seller) is Odoo's own, read back at each
  /// seller's own order confirmation.
  double get estimatedSubtotal =>
      items.fold(0.0, (sum, i) => sum + i.estimatedLineTotal);

  /// One group per distinct seller, in first-added order — see
  /// [CartSellerGroup]'s own doc comment. A single-seller cart (still the
  /// common case) always yields exactly one group here.
  List<CartSellerGroup> get sellerGroups {
    final byOrg = <String, List<CartItem>>{};
    for (final item in items) {
      (byOrg[item.orgId] ??= []).add(item);
    }
    // Map (default LinkedHashMap) preserves insertion order, so this is
    // already "first-added seller first" with no extra bookkeeping.
    return byOrg.entries
        .map((e) => CartSellerGroup(
              orgId: e.key,
              storeNameEn: e.value.first.storeNameEn,
              storeNameAr: e.value.first.storeNameAr,
              items: e.value,
            ))
        .toList();
  }

  static const empty = Cart(items: []);

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Cart.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'];
    return Cart(
      items: rawItems is List
          ? rawItems
              .map(
                  (e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

class CartNotifier extends Notifier<Cart> {
  // Phase 3 schema change (Cart no longer has a single top-level orgId;
  // every CartItem now carries its own) — bumped from 'marketplace_cart_v1'
  // rather than migrated. Cart data is ephemeral, display-only, client-local
  // state; an old v1 cart is simply not read back (same "corrupted data ->
  // start fresh" resilience _load() already had, just triggered by the key
  // no longer existing rather than by a parse failure).
  static const _prefsKey = 'marketplace_cart_v2';

  @override
  Cart build() {
    // Fire-and-forget: state starts empty and is replaced once the
    // persisted cart (if any) loads — same pattern as other
    // shared_preferences-backed state in this app (no synchronous local
    // storage API exists to read before the first frame).
    _load();
    return Cart.empty;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = Cart.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupted/outdated local data must never crash the app — start
      // fresh, same as this file's persistence is best-effort throughout.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  /// Phase 3 — adding an item from a store not already in the cart no
  /// longer conflicts with anything; it simply becomes (or joins) that
  /// store's own [CartSellerGroup]. There is no store-conflict case left to
  /// guard against here.
  Future<void> addItem({
    required MarketplaceProduct product,
    required String storeNameEn,
    required String storeNameAr,
    // Milestone 5 (Patient Product Experience) — explicit variant identity
    // for a multi-variant product, resolved by the detail page BEFORE this
    // is ever called (never guessed here). Null for a single-variant
    // product — see CartItem.variantEngineId's own doc comment.
    String? variantEngineId,
    String? variantLabel,
    // The detail page's own live, resolved price/stock for the SELECTED
    // variant — falls back to the (possibly stale) browse-card price only
    // when omitted, matching the existing pre-variant behavior exactly.
    double? resolvedPrice,
    int quantity = 1,
  }) async {
    final items = [...state.items];
    final existingIndex = items.indexWhere(
        (i) => i.sameLineAs(product.orgId, product.engineId, variantEngineId));
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex]
          .copyWith(quantity: items[existingIndex].quantity + quantity);
    } else {
      items.add(CartItem(
        orgId: product.orgId,
        storeNameEn: storeNameEn,
        storeNameAr: storeNameAr,
        productEngineId: product.engineId,
        variantEngineId: variantEngineId,
        variantLabel: variantLabel,
        nameEn: product.nameEn,
        nameAr: product.nameAr,
        displayPrice: resolvedPrice ?? product.displayPrice,
        currencyName: product.currencyName,
        imageUrl: product.imageUrl,
        quantity: quantity,
      ));
    }

    state = Cart(items: items);
    await _persist();
  }

  Future<void> updateQuantity(String orgId, String productEngineId,
      String? variantEngineId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(orgId, productEngineId, variantEngineId);
      return;
    }
    final items = state.items
        .map((i) => i.sameLineAs(orgId, productEngineId, variantEngineId)
            ? i.copyWith(quantity: quantity)
            : i)
        .toList();
    state = Cart(items: items);
    await _persist();
  }

  Future<void> removeItem(
      String orgId, String productEngineId, String? variantEngineId) async {
    final items = state.items
        .where((i) => !i.sameLineAs(orgId, productEngineId, variantEngineId))
        .toList();
    state = Cart(items: items);
    await _persist();
  }

  /// Phase 3 — removes every item belonging to ONE seller, leaving any
  /// OTHER sellers' items untouched. Called after that seller's order is
  /// successfully placed during a (possibly multi-seller) split checkout —
  /// see marketplace_checkout_page.dart's own header. This is deliberately
  /// NOT [clear]: a partially-completed multi-seller checkout must never
  /// lose the still-unplaced sellers' items just because one seller's order
  /// succeeded.
  Future<void> removeSeller(String orgId) async {
    final items = state.items.where((i) => i.orgId != orgId).toList();
    state = Cart(items: items);
    await _persist();
  }

  Future<void> clear() async {
    state = Cart.empty;
    await _persist();
  }
}

final marketplaceCartProvider =
    NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
