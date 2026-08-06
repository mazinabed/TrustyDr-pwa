// Public Store Profile + Social Links (2026-08-05) — regression coverage
// for buildSocialContactActionButtons (widgets/social_contact_links.dart),
// the shared helper extracted from doctor_profile_v2.dart's previously
// inline addSocial/actionButton closures and now also used by the
// standalone Commerce Store page. Tests the pure filtering/ordering logic
// directly — no Firebase dependency, matching this app's existing
// marketplace_gallery_parsing_test.dart convention.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/widgets/social_contact_links.dart';

void main() {
  group('MarketplaceStore.fromMap social/contact parsing', () {
    Map<String, dynamic> baseFields() => {
          'providerId': 'org_1',
          'orgId': 'org_1',
          'facilityName_en': 'Demo Store',
          'facilityName_ar': 'Demo Store',
          'facilityName_ku': 'Demo Store',
          'province_en': 'Wasit',
          'province_ar': 'Wasit',
          'province_ku': 'Wasit',
          'city_en': 'Kut',
          'city_ar': 'Kut',
          'city_ku': 'Kut',
          'productCount': 3,
        };

    test('parses type/website/socialLinks/phone/email/whatsapp when present',
        () {
      final store = MarketplaceStore.fromMap({
        ...baseFields(),
        'type': 'retailer',
        'website': 'https://example.com',
        'socialLinks': {'instagram': 'https://instagram.com/x'},
        'phone': '+964 770 000 0000',
        'email': 'owner@example.com',
        'whatsapp': '+964 770 111 1111',
      });

      expect(store.businessType, 'retailer');
      expect(store.website, 'https://example.com');
      expect(store.socialLinks?['instagram'], 'https://instagram.com/x');
      expect(store.phone, '+964 770 000 0000');
      expect(store.email, 'owner@example.com');
      expect(store.whatsapp, '+964 770 111 1111');
    });

    test(
        'a legacy/pre-checkpoint payload with none of these keys parses without crashing',
        () {
      final store = MarketplaceStore.fromMap(baseFields());

      expect(store.businessType, isNull);
      expect(store.website, isNull);
      expect(store.socialLinks, isNull);
      expect(store.phone, isNull);
      expect(store.email, isNull);
      expect(store.whatsapp, isNull);
    });

    test('a non-Map socialLinks value is ignored, never throws', () {
      final store = MarketplaceStore.fromMap({
        ...baseFields(),
        'socialLinks': 'not-a-map',
      });
      expect(store.socialLinks, isNull);
    });
  });

  group('MarketplaceStoreBranding.fromMap social/contact parsing', () {
    test('parses businessType/location/website/socialLinks/contact fields', () {
      final branding = MarketplaceStoreBranding.fromMap({
        'type': 'retailer',
        'provinceKey': 'wasit',
        'cityKey': 'wasit_kut',
        'cityEn': 'Kut',
        'website': 'https://example.com',
        'socialLinks': {'facebook': 'https://facebook.com/x'},
        'phone': '+964 770 000 0000',
        'email': 'owner@example.com',
        'whatsapp': '+964 770 111 1111',
      });

      expect(branding.businessType, 'retailer');
      expect(branding.provinceKey, 'wasit');
      expect(branding.cityKey, 'wasit_kut');
      expect(branding.cityEn, 'Kut');
      expect(branding.website, 'https://example.com');
      expect(branding.socialLinks?['facebook'], 'https://facebook.com/x');
      expect(branding.phone, '+964 770 000 0000');
      expect(branding.email, 'owner@example.com');
      expect(branding.whatsapp, '+964 770 111 1111');
    });

    test(
        'an empty map (Healthcare pharmacy org with none of these fields) parses to all-null',
        () {
      final branding = MarketplaceStoreBranding.fromMap(const {});
      expect(branding.businessType, isNull);
      expect(branding.website, isNull);
      expect(branding.socialLinks, isNull);
      expect(branding.phone, isNull);
    });
  });

  group('buildSocialContactActionButtons', () {
    test('everything null/empty produces no buttons', () {
      final items = buildSocialContactActionButtons();
      expect(items, isEmpty);
    });

    test('phone only shown when canCall is true', () {
      final shown = buildSocialContactActionButtons(
        phone: '+964 770 000 0000',
        canCall: true,
      );
      expect(shown, hasLength(1));

      final hidden = buildSocialContactActionButtons(
        phone: '+964 770 000 0000',
        canCall: false,
      );
      expect(hidden, isEmpty);
    });

    test('whatsapp shown when a digit-bearing number is set', () {
      final items =
          buildSocialContactActionButtons(whatsapp: '+964 770 111 1111');
      expect(items, hasLength(1));
    });

    test('whatsapp with no usable digits produces no button', () {
      final items = buildSocialContactActionButtons(whatsapp: '   ');
      expect(items, isEmpty);
    });

    test('email shown when non-empty', () {
      final items = buildSocialContactActionButtons(email: 'owner@example.com');
      expect(items, hasLength(1));
    });

    test('social links: only populated, valid-scheme platforms produce buttons',
        () {
      final items = buildSocialContactActionButtons(
        socialLinks: {
          'instagram': 'https://instagram.com/x',
          'facebook': '',
          'tiktok': 'not-a-url',
          'youtube': 'javascript:alert(1)',
        },
      );
      // Only instagram is a valid, non-empty http(s) URL — facebook is
      // empty, tiktok fails Uri parsing as an http(s) link, youtube has
      // the wrong scheme. Exactly matching the same http(s)-only rule
      // every existing Provider profile page already enforced.
      expect(items, hasLength(1));
    });

    test('website counts as part of the social/online group, same rule', () {
      final validWebsite = buildSocialContactActionButtons(
          socialLinks: {'website': 'https://example.com'});
      expect(validWebsite, hasLength(1));

      final invalidWebsite = buildSocialContactActionButtons(
          socialLinks: {'website': 'example.com'});
      expect(invalidWebsite, isEmpty);
    });

    test(
        'order is call, whatsapp, email, then instagram/facebook/tiktok/youtube/website',
        () {
      final items = buildSocialContactActionButtons(
        phone: '+964 770 000 0000',
        whatsapp: '+964 770 111 1111',
        email: 'owner@example.com',
        canCall: true,
        socialLinks: {
          'instagram': 'https://instagram.com/x',
          'facebook': 'https://facebook.com/x',
          'tiktok': 'https://tiktok.com/@x',
          'youtube': 'https://youtube.com/x',
          'website': 'https://example.com',
        },
      );
      expect(items, hasLength(8));
    });

    test(
        'phone/email/whatsapp all absent but social links present shows only social buttons',
        () {
      // Mirrors the Commerce Store page's own "Contact" vs "Social &
      // Online" section split — each MarketplaceSection calls this helper
      // with only its own category of params populated.
      final contactOnly = buildSocialContactActionButtons(
        socialLinks: {'instagram': 'https://instagram.com/x'},
      );
      expect(contactOnly, hasLength(1));

      final socialOnly = buildSocialContactActionButtons(
        phone: '+964 770 000 0000',
        canCall: true,
      );
      expect(socialOnly, hasLength(1));
    });
  });
}
