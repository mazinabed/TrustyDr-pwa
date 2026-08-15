// Marketplace Platform, Phase 3 — Multi-Seller Cart + Split Checkout.
//
// Real widget-driven provider tests (ProviderScope + shared_preferences
// mock, matching this app's established convention) exercising the ACTUAL
// CartNotifier — never a hand-rolled fake — for the exact behavior this
// phase changed: a cart may now hold items from more than one seller
// without throwing, sameLineAs disambiguates by seller (not just
// product+variant), and removing one seller's items never touches another
// seller's. A single-seller cart's own behavior (still the common case) is
// verified to be unchanged.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

MarketplaceProduct _product({
  required String orgId,
  required String engineId,
  double price = 5000,
}) {
  return MarketplaceProduct(
    orgId: orgId,
    engineId: engineId,
    sku: 'SKU-$orgId-$engineId',
    nameEn: 'Panadol Extra 24 Tablets',
    nameAr: 'بانادول اكسترا',
    descriptionEn: null,
    descriptionAr: null,
    brandName: 'GSK',
    categoryEngineIds: const [],
    categoryKeys: const [],
    categories: const [],
    categoryEngineId: null,
    categoryNameEn: null,
    categoryNameAr: null,
    displayPrice: price,
    currencyName: 'IQD',
    isFeatured: false,
    availabilityBadge: 'in_stock',
    imageUrl: null,
    galleryImageUrls: const [],
    storeNameEn: orgId,
    storeNameAr: null,
    storeNameKu: null,
    ratingAverage: 0,
    ratingCount: 0,
  );
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    // Force the auto-load from (empty) shared_preferences to settle before
    // each test mutates state, matching how the real app's first frame
    // behaves.
    container.read(marketplaceCartProvider);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => container.dispose());

  test(
      'adding items from two different sellers does not throw and both survive as separate groups',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1', price: 5000),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: 'صيدلية النور',
    );
    // The old CartStoreConflictException would have been thrown right
    // here, before Phase 3 — this call must now simply succeed.
    await notifier.addItem(
      product: _product(orgId: 'org_b', engineId: 'e2', price: 4750),
      storeNameEn: 'Baghdad Central Pharmacy',
      storeNameAr: 'صيدلية بغداد المركزية',
    );

    final cart = container.read(marketplaceCartProvider);
    expect(cart.items, hasLength(2));
    final groups = cart.sellerGroups;
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.orgId), containsAll(['org_a', 'org_b']));
    expect(groups.firstWhere((g) => g.orgId == 'org_a').subtotal, 5000);
    expect(groups.firstWhere((g) => g.orgId == 'org_b').subtotal, 4750);
    expect(cart.estimatedSubtotal, 9750);
  });

  test(
      'the SAME engineId at two different sellers is two distinct lines, never merged',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: '31'),
      storeNameEn: 'Demp Pharmacy',
      storeNameAr: '',
    );
    await notifier.addItem(
      product: _product(orgId: 'org_b', engineId: '31'),
      storeNameEn: 'My Pharmacy',
      storeNameAr: '',
    );

    final cart = container.read(marketplaceCartProvider);
    // Both lines share engineId "31" but belong to different Odoo
    // companies — engineId alone is never a valid global identity.
    expect(cart.items, hasLength(2));
    expect(cart.sellerGroups, hasLength(2));
  });

  test(
      'adding the same product from the same seller twice merges quantity into one line',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1'),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: '',
    );
    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1'),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: '',
      quantity: 2,
    );

    final cart = container.read(marketplaceCartProvider);
    expect(cart.items, hasLength(1));
    expect(cart.items.single.quantity, 3);
  });

  test(
      'removeSeller removes only that seller\'s items, leaving another seller untouched',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1', price: 5000),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: '',
    );
    await notifier.addItem(
      product: _product(orgId: 'org_b', engineId: 'e2', price: 4750),
      storeNameEn: 'Baghdad Central Pharmacy',
      storeNameAr: '',
    );

    // Mirrors marketplace_checkout_page.dart's own post-order cleanup: only
    // the just-placed seller's items are removed, never the whole cart —
    // this is exactly what lets a partially-completed multi-seller
    // checkout keep the still-unplaced seller's items intact.
    await notifier.removeSeller('org_a');

    final cart = container.read(marketplaceCartProvider);
    expect(cart.items, hasLength(1));
    expect(cart.items.single.orgId, 'org_b');
    expect(cart.sellerGroups, hasLength(1));
  });

  test(
      'a single-seller cart still behaves exactly as before this phase: one group, one subtotal',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1', price: 5000),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: 'صيدلية النور',
      quantity: 2,
    );

    final cart = container.read(marketplaceCartProvider);
    expect(cart.sellerGroups, hasLength(1));
    final group = cart.sellerGroups.single;
    expect(group.orgId, 'org_a');
    expect(group.itemCount, 2);
    expect(group.subtotal, 10000);
    expect(cart.estimatedSubtotal, 10000);
    expect(cart.totalQuantity, 2);
  });

  test(
      'updateQuantity and removeItem are scoped by seller too (orgId + product + variant)',
      () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e1'),
      storeNameEn: 'Al Noor Pharmacy',
      storeNameAr: '',
    );
    await notifier.addItem(
      product: _product(orgId: 'org_b', engineId: 'e1'),
      storeNameEn: 'My Pharmacy',
      storeNameAr: '',
    );

    await notifier.updateQuantity('org_a', 'e1', null, 5);
    var cart = container.read(marketplaceCartProvider);
    expect(cart.items.firstWhere((i) => i.orgId == 'org_a').quantity, 5);
    expect(cart.items.firstWhere((i) => i.orgId == 'org_b').quantity, 1);

    await notifier.removeItem('org_b', 'e1', null);
    cart = container.read(marketplaceCartProvider);
    expect(cart.items, hasLength(1));
    expect(cart.items.single.orgId, 'org_a');
  });

  test('CartSellerGroup preserves first-added seller order', () async {
    final notifier = container.read(marketplaceCartProvider.notifier);

    await notifier.addItem(
      product: _product(orgId: 'org_z', engineId: 'e1'),
      storeNameEn: 'Z Store',
      storeNameAr: '',
    );
    await notifier.addItem(
      product: _product(orgId: 'org_a', engineId: 'e2'),
      storeNameEn: 'A Store',
      storeNameAr: '',
    );

    final groups = container.read(marketplaceCartProvider).sellerGroups;
    expect(groups.map((g) => g.orgId).toList(), ['org_z', 'org_a']);
  });
}
