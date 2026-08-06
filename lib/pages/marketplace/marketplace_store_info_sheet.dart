import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/widgets/social_contact_links.dart';

/// Store Info detail sheet (2026-08-07 Store header compaction) — the
/// single "See Store Info" destination for everything that used to sit
/// inline above Search (full description, address, contact, social) before
/// this checkpoint. Keeps the Store page itself compact: nothing here is
/// ever in the main widget tree until a patient explicitly asks for it, so
/// it can never push Search/Categories/Products down, and never reserves
/// space for a section that has no data — each of the four sub-sections
/// (About/Location/Contact/Online) is independently omitted when empty,
/// same "no empty state" rule as every other Store-page section.
///
/// [description] is passed in already-resolved by the caller (rather than
/// derived here from [store]) so the Store page's own existing
/// catalog.store-then-nav-param fallback (see _StoreBody's
/// `effectiveDescription`) stays the single source of truth for which
/// description wins — this sheet never re-implements that fallback.
///
/// A modal bottom sheet on every form factor — content is width-capped
/// (see [_maxSheetWidth]) so it stays a reasonable reading width on tablet/
/// desktop rather than stretching edge-to-edge; a mobile-width sheet is
/// already the correct pattern there, so no separate desktop layout was
/// needed.
const double _maxSheetWidth = 480;

/// Merges [store]'s top-level `website` into its `socialLinks` map so
/// [buildSocialContactActionButtons]' existing URL-validation/ordering
/// logic can be reused for the Online sub-section — `website` is never
/// actually nested in socialLinks on the model itself (see
/// MarketplaceStoreBranding's own doc comment), this is purely a local
/// adapter for this one call site.
Map<String, dynamic> _onlineLinksFor(MarketplaceStoreBranding? store) => {
      ...?store?.socialLinks,
      if ((store?.website ?? '').trim().isNotEmpty) 'website': store!.website,
    };

Future<void> showStoreInfoSheet({
  required BuildContext context,
  required MarketplaceStoreBranding? store,
  required String? resolvedLocation,
  required String? description,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _StoreInfoSheetContent(
      store: store,
      resolvedLocation: resolvedLocation,
      description: description,
    ),
  );
}

class _StoreInfoSheetContent extends StatelessWidget {
  const _StoreInfoSheetContent({
    required this.store,
    required this.resolvedLocation,
    required this.description,
  });

  final MarketplaceStoreBranding? store;
  final String? resolvedLocation;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description?.trim();
    final hasDescription = (trimmedDescription ?? '').isNotEmpty;

    final streetAddress = store?.streetAddress?.trim();
    final locationNotes = store?.locationNotes?.trim();
    final hasLocation = (streetAddress?.isNotEmpty ?? false) ||
        (resolvedLocation?.trim().isNotEmpty ?? false) ||
        (locationNotes?.isNotEmpty ?? false);

    final contactActions = buildSocialContactActionButtons(
      phone: store?.phone,
      email: store?.email,
      whatsapp: store?.whatsapp,
    );
    final onlineActions =
        buildSocialContactActionButtons(socialLinks: _onlineLinksFor(store));

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxSheetWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'marketplace_store_info_title'.tr(),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDescription)
                          _InfoSubSection(
                            title: 'marketplace_store_info_about'.tr(),
                            child: Text(
                              trimmedDescription!,
                              style: const TextStyle(
                                  fontSize: 13.5, color: Colors.black87),
                            ),
                          ),
                        if (hasLocation)
                          _InfoSubSection(
                            title: 'marketplace_store_info_location'.tr(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((streetAddress ?? '').isNotEmpty)
                                  Text(streetAddress!,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.black87)),
                                if ((resolvedLocation ?? '').trim().isNotEmpty)
                                  Text(resolvedLocation!.trim(),
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.black87)),
                                if ((locationNotes ?? '').isNotEmpty)
                                  Text(locationNotes!,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                          ),
                        if (contactActions.isNotEmpty)
                          _InfoSubSection(
                            title: 'marketplace_store_contact_section'.tr(),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: contactActions,
                            ),
                          ),
                        if (onlineActions.isNotEmpty)
                          _InfoSubSection(
                            title: 'marketplace_store_social_section'.tr(),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: onlineActions,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSubSection extends StatelessWidget {
  const _InfoSubSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Whether there's anything at all for [showStoreInfoSheet] to show — the
/// Store page uses this to decide whether "See Store Info" renders as a
/// trigger in the first place (never a dead-end button with nothing behind
/// it). [description] is the caller's already-resolved value, same
/// contract as [showStoreInfoSheet]'s own parameter.
bool storeHasDetailedInfo({
  required MarketplaceStoreBranding? store,
  required String? resolvedLocation,
  required String? description,
}) {
  final hasDescription = (description?.trim() ?? '').isNotEmpty;
  final hasLocation = (store?.streetAddress?.trim().isNotEmpty ?? false) ||
      (resolvedLocation?.trim().isNotEmpty ?? false) ||
      (store?.locationNotes?.trim().isNotEmpty ?? false);
  final hasContact = buildSocialContactActionButtons(
    phone: store?.phone,
    email: store?.email,
    whatsapp: store?.whatsapp,
  ).isNotEmpty;
  final hasOnline =
      buildSocialContactActionButtons(socialLinks: _onlineLinksFor(store))
          .isNotEmpty;
  return hasDescription || hasLocation || hasContact || hasOnline;
}
