// lib/core/providers/marketplace_cart_provider.dart
//
// Milestone 6 (Cart, Checkout, Order Creation) — the cart itself lives
// entirely client-side (shared_preferences, already a dependency and the
// established pattern for this kind of persisted local state — see
// home.dart's saved-location persistence), guest or signed-in alike. It
// never syncs to Firestore and is never the price/stock authority: every
// field cached here (displayPrice, currencyName, nameEn/nameAr, imageUrl)
// is DISPLAY-ONLY, sourced from the same Marketplace projection the rest
// of this app already treats as non-authoritative. The actual order-time
// live revalidation happens server-side (Healthcare -> Commerce -> Odoo,
// already built) — this file adds no new trust boundary.
//
// One-store-per-cart (Phase 1 rule): [MarketplaceProduct.orgId] is the key.
// addItem() throws [CartStoreConflictException] rather than silently
// mixing stores when the cart already holds a different orgId's items —
// the caller (UI) must confirm with the patient, then call
// [CartNotifier.replaceCartWith].
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

class CartItem {
  const CartItem({
    required this.productEngineId,
    required this.nameEn,
    required this.nameAr,
    required this.displayPrice,
    required this.currencyName,
    required this.imageUrl,
    required this.quantity,
  });

  final String productEngineId;
  final String nameEn;
  final String nameAr;
  final double displayPrice;
  final String? currencyName;
  final String? imageUrl;
  final int quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productEngineId: productEngineId,
        nameEn: nameEn,
        nameAr: nameAr,
        displayPrice: displayPrice,
        currencyName: currencyName,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
      );

  double get estimatedLineTotal => displayPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productEngineId': productEngineId,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'displayPrice': displayPrice,
        'currencyName': currencyName,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productEngineId: j['productEngineId']?.toString() ?? '',
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

class Cart {
  const Cart({
    required this.orgId,
    required this.storeNameEn,
    required this.storeNameAr,
    required this.items,
  });

  final String? orgId;
  final String? storeNameEn;
  final String? storeNameAr;
  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  /// Display-only estimate for the Review Cart screen — never the price of
  /// record. The real total is Odoo's own, read back at order confirmation.
  double get estimatedSubtotal =>
      items.fold(0.0, (sum, i) => sum + i.estimatedLineTotal);

  String? localizedStoreName(String lang) {
    if (lang == 'ar' && (storeNameAr ?? '').isNotEmpty) return storeNameAr;
    return (storeNameEn ?? '').isNotEmpty ? storeNameEn : storeNameAr;
  }

  static const empty =
      Cart(orgId: null, storeNameEn: null, storeNameAr: null, items: []);

  Map<String, dynamic> toJson() => {
        'orgId': orgId,
        'storeNameEn': storeNameEn,
        'storeNameAr': storeNameAr,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Cart.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'];
    return Cart(
      orgId: j['orgId']?.toString(),
      storeNameEn: j['storeNameEn']?.toString(),
      storeNameAr: j['storeNameAr']?.toString(),
      items: rawItems is List
          ? rawItems
              .map(
                  (e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

/// Thrown by [CartNotifier.addItem] when the cart already holds a different
/// store's items — the UI must show a confirmation (per the approved
/// one-store-per-cart Phase 1 rule) before calling [CartNotifier.replaceCartWith].
class CartStoreConflictException implements Exception {
  CartStoreConflictException({
    required this.currentStoreNameEn,
    required this.currentStoreNameAr,
  });

  final String currentStoreNameEn;
  final String currentStoreNameAr;
}

class CartNotifier extends Notifier<Cart> {
  static const _prefsKey = 'marketplace_cart_v1';

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

  Future<void> addItem({
    required MarketplaceProduct product,
    required String storeNameEn,
    required String storeNameAr,
    int quantity = 1,
  }) async {
    if (state.isNotEmpty && state.orgId != product.orgId) {
      throw CartStoreConflictException(
        currentStoreNameEn: state.storeNameEn ?? '',
        currentStoreNameAr: state.storeNameAr ?? '',
      );
    }

    final items = [...state.items];
    final existingIndex =
        items.indexWhere((i) => i.productEngineId == product.engineId);
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex]
          .copyWith(quantity: items[existingIndex].quantity + quantity);
    } else {
      items.add(CartItem(
        productEngineId: product.engineId,
        nameEn: product.nameEn,
        nameAr: product.nameAr,
        displayPrice: product.displayPrice,
        currencyName: product.currencyName,
        imageUrl: product.imageUrl,
        quantity: quantity,
      ));
    }

    state = Cart(
      orgId: product.orgId,
      storeNameEn: storeNameEn,
      storeNameAr: storeNameAr,
      items: items,
    );
    await _persist();
  }

  /// Replaces the entire cart with a single new item from a different
  /// store — called only after the UI has confirmed the
  /// [CartStoreConflictException] prompt with the patient.
  Future<void> replaceCartWith({
    required MarketplaceProduct product,
    required String storeNameEn,
    required String storeNameAr,
    int quantity = 1,
  }) async {
    state = Cart(
      orgId: product.orgId,
      storeNameEn: storeNameEn,
      storeNameAr: storeNameAr,
      items: [
        CartItem(
          productEngineId: product.engineId,
          nameEn: product.nameEn,
          nameAr: product.nameAr,
          displayPrice: product.displayPrice,
          currencyName: product.currencyName,
          imageUrl: product.imageUrl,
          quantity: quantity,
        ),
      ],
    );
    await _persist();
  }

  Future<void> updateQuantity(String productEngineId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productEngineId);
      return;
    }
    final items = state.items
        .map((i) => i.productEngineId == productEngineId
            ? i.copyWith(quantity: quantity)
            : i)
        .toList();
    state = Cart(
      orgId: state.orgId,
      storeNameEn: state.storeNameEn,
      storeNameAr: state.storeNameAr,
      items: items,
    );
    await _persist();
  }

  Future<void> removeItem(String productEngineId) async {
    final items =
        state.items.where((i) => i.productEngineId != productEngineId).toList();
    state = items.isEmpty
        ? Cart.empty
        : Cart(
            orgId: state.orgId,
            storeNameEn: state.storeNameEn,
            storeNameAr: state.storeNameAr,
            items: items,
          );
    await _persist();
  }

  Future<void> clear() async {
    state = Cart.empty;
    await _persist();
  }
}

final marketplaceCartProvider =
    NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
