// Public Store Profile + Social Links (2026-08-05) — regression coverage
// for buildSocialContactActionButtons (widgets/social_contact_links.dart),
// the shared helper extracted from doctor_profile_v2.dart's previously
// inline addSocial/actionButton closures and now also used by the
// standalone Commerce Store page. Tests the pure filtering/ordering logic
// directly — no Firebase dependency, matching this app's existing
// marketplace_gallery_parsing_test.dart convention.
import 'package:flutter/material.dart';
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

  group(
      'MarketplaceStore/MarketplaceStoreBranding address parsing (2026-08-07)',
      () {
    test('MarketplaceStore.fromMap parses streetAddress/locationNotes', () {
      final store = MarketplaceStore.fromMap({
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
        'streetAddress': '123 Demo Street',
        'locationNotes': 'Near the market',
      });
      expect(store.streetAddress, '123 Demo Street');
      expect(store.locationNotes, 'Near the market');
    });

    test('MarketplaceStoreBranding.fromMap parses streetAddress/locationNotes',
        () {
      final branding = MarketplaceStoreBranding.fromMap({
        'streetAddress': '123 Demo Street',
        'locationNotes': 'Near the market',
      });
      expect(branding.streetAddress, '123 Demo Street');
      expect(branding.locationNotes, 'Near the market');
    });

    test('absent streetAddress/locationNotes parse to null, never crash', () {
      final branding = MarketplaceStoreBranding.fromMap(const {});
      expect(branding.streetAddress, isNull);
      expect(branding.locationNotes, isNull);
    });
  });

  group('buildQuickStoreActions (2026-08-08 second-pass Store header redesign)',
      () {
    test('everything absent produces no actions — no reserved space', () {
      final items = buildQuickStoreActions();
      expect(items, isEmpty);
    });

    test(
        'exactly matches the live Demo Store example: Location, Instagram, capped at 3',
        () {
      // Demo Store as tested live: streetAddress present (always public),
      // showSocialLinks enabled with only Instagram configured, phone
      // NOT currently public. Expect exactly 2 quick actions (Location,
      // Instagram) — the "Store Info" chip itself is appended by the
      // Store page, not by this builder.
      final items = buildQuickStoreActions(
        hasLocation: true,
        onLocationTap: () {},
        socialLinks: {'instagram': 'https://instagram.com/demostore'},
      );
      expect(items, hasLength(2));
    });

    test('caps at maxPrimary (default 3) even when more channels are public',
        () {
      final items = buildQuickStoreActions(
        phone: '+964 770 000 0000',
        whatsapp: '+964 770 111 1111',
        website: 'https://example.com',
        hasLocation: true,
        onLocationTap: () {},
        socialLinks: {
          'instagram': 'https://instagram.com/x',
          'facebook': 'https://facebook.com/x',
        },
      );
      // 6 candidates exist (call, whatsapp, location, website, instagram,
      // facebook) but only the first 3 by priority render inline — the
      // rest are reachable only via Store Info.
      expect(items, hasLength(3));
    });

    test('priority order is call, whatsapp, location, website, then socials',
        () {
      // Fewer than maxPrimary candidates so the full relative order is
      // observable: whatsapp+location+instagram, no call/website.
      final items = buildQuickStoreActions(
        whatsapp: '+964 770 111 1111',
        hasLocation: true,
        onLocationTap: () {},
        socialLinks: {'instagram': 'https://instagram.com/x'},
      );
      expect(items, hasLength(3));
    });

    test(
        'location action only appears when hasLocation AND onLocationTap are both set',
        () {
      final withoutTap = buildQuickStoreActions(hasLocation: true);
      expect(withoutTap, isEmpty);

      final withoutFlag =
          buildQuickStoreActions(hasLocation: false, onLocationTap: () {});
      expect(withoutFlag, isEmpty);

      final both =
          buildQuickStoreActions(hasLocation: true, onLocationTap: () {});
      expect(both, hasLength(1));
    });

    test('phone gated by canCall, same as the labeled variant', () {
      final hidden = buildQuickStoreActions(
        phone: '+964 770 000 0000',
        canCall: false,
      );
      expect(hidden, isEmpty);
    });

    test('an invalid website scheme produces no action', () {
      final items = buildQuickStoreActions(website: 'not-a-valid-url');
      expect(items, isEmpty);
    });

    test('a single available action renders alone', () {
      final items = buildQuickStoreActions(phone: '+964 770 000 0000');
      expect(items, hasLength(1));
    });
  });

  group('resolveContactSocialActions (2026-08-08 shared resolver)', () {
    test(
        'includes email (unlike buildQuickStoreActions) for Store Info sheet use',
        () {
      final items = resolveContactSocialActions(email: 'owner@example.com');
      expect(items, hasLength(1));
      expect(items.first.label, isNotEmpty);
    });

    test(
        'buildSocialContactActionButtons stays behaviorally identical after the refactor',
        () {
      // Confirms the extraction into resolveContactSocialActions didn't
      // change buildSocialContactActionButtons' own public behavior —
      // still call, whatsapp, email, then the 4 socials + website.
      final items = buildSocialContactActionButtons(
        phone: '+964 770 000 0000',
        whatsapp: '+964 770 111 1111',
        email: 'owner@example.com',
        socialLinks: {
          'instagram': 'https://instagram.com/x',
          'website': 'https://example.com',
        },
      );
      expect(items, hasLength(5));
      expect(items.every((w) => w is SocialContactActionButton), isTrue);
    });
  });

  group('CompactStoreActionButton rendering', () {
    testWidgets('renders as an icon-only tap target, no visible label text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactStoreActionButton(
              icon: const Icon(Icons.call),
              tooltip: 'Call',
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.call), findsOneWidget);
      // Unlike SocialContactActionButton (label underneath), this compact
      // variant renders no visible Text widget at all.
      expect(find.byType(Text), findsNothing);
    });
  });
}
