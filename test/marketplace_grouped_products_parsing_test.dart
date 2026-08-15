// Marketplace Platform, Phase 2 — Multi-Seller Aggregated Discovery.
// Pure .fromMap parsing tests, no Firebase/network dependency — matches
// this app's existing marketplace_gallery_parsing_test.dart convention.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

void main() {
  group('MarketplaceProductOffer.fromMap', () {
    test('parses a full offer', () {
      final offer = MarketplaceProductOffer.fromMap({
        'orgId': 'org_b',
        'engineId': 'engine_b1',
        'storeName_en': 'Baghdad Central Pharmacy',
        'storeName_ar': null,
        'storeName_ku': null,
        'displayPrice': 4750,
        'currencyName': 'IQD',
        'availabilityBadge': 'in_stock',
        'imageUrl': 'https://example.com/panadol.jpg',
      });

      expect(offer.orgId, 'org_b');
      expect(offer.engineId, 'engine_b1');
      expect(offer.storeNameEn, 'Baghdad Central Pharmacy');
      expect(offer.displayPrice, 4750);
      expect(offer.currencyName, 'IQD');
    });

    test('missing fields degrade safely, never throw', () {
      final offer = MarketplaceProductOffer.fromMap(const {});
      expect(offer.orgId, '');
      expect(offer.engineId, '');
      expect(offer.displayPrice, 0);
      expect(offer.storeNameEn, isNull);
    });
  });

  group('GroupedMarketplaceProduct.fromMap', () {
    test('parses a group with 3 offers, preserving the backend-provided order',
        () {
      final group = GroupedMarketplaceProduct.fromMap({
        'canonicalId': 'canonical_panadol',
        'name_en': 'Panadol Extra 24 Tablets',
        'name_ar': 'بانادول اكسترا',
        'brandName': 'GSK',
        'categoryKey': 'medicines_analgesics',
        'representativeImageUrl': null,
        'lowestPrice': 4750,
        'currencyName': 'IQD',
        'sellerCount': 3,
        'offers': [
          {
            'orgId': 'org_b',
            'engineId': 'engine_b1',
            'storeName_en': 'Baghdad Central Pharmacy',
            'displayPrice': 4750,
            'currencyName': 'IQD',
          },
          {
            'orgId': 'org_a',
            'engineId': 'engine_a1',
            'storeName_en': 'Al Noor Pharmacy',
            'displayPrice': 5000,
            'currencyName': 'IQD',
          },
          {
            'orgId': 'org_c',
            'engineId': 'engine_c1',
            'storeName_en': 'Kut Pharmacy',
            'displayPrice': 5250,
            'currencyName': 'IQD',
          },
        ],
      });

      expect(group.canonicalId, 'canonical_panadol');
      expect(group.sellerCount, 3);
      expect(group.lowestPrice, 4750);
      expect(group.offers, hasLength(3));
      // Client trusts the backend's own cheapest-first order — never
      // re-sorts (see MarketplaceSellerOffersPage's own doc comment).
      expect(group.offers.map((o) => o.orgId).toList(),
          ['org_b', 'org_a', 'org_c']);
    });

    test('missing offers list degrades to an empty list, never throws', () {
      final group = GroupedMarketplaceProduct.fromMap({
        'canonicalId': 'canonical_x',
        'name_en': 'X',
        'name_ar': 'X',
      });
      expect(group.offers, isEmpty);
      expect(group.sellerCount, 0);
    });
  });

  group('MarketplaceBrowseData.groupedProducts', () {
    test('defaults to an empty list when not supplied (backward compatible)',
        () {
      const data = MarketplaceBrowseData(
        stores: [],
        products: [],
        categories: [],
        hasMoreProducts: false,
      );
      expect(data.groupedProducts, isEmpty);
    });

    test('MarketplaceBrowseData.empty has an empty groupedProducts list', () {
      expect(MarketplaceBrowseData.empty.groupedProducts, isEmpty);
    });
  });
}
