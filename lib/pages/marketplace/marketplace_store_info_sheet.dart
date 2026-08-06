import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/social_contact_links.dart';

/// Store Info detail sheet (2026-08-07, redesigned 2026-08-08) — the
/// single "See Store Info" destination for everything that doesn't fit
/// the Store header's own compact quick-actions row (full description,
/// address, remaining contact/social channels). Keeps the Store page
/// itself compact: nothing here is ever in the main widget tree until a
/// patient explicitly asks for it.
///
/// Second-pass redesign (2026-08-08) fixes two problems found in live
/// testing:
/// 1. The sheet used to render `Center(child: ConstrainedBox(maxWidth))`
///    with no `heightFactor`. `Center`/`Align`, when given bounded (not
///    infinite) constraints — which `showModalBottomSheet(isScrollControlled:
///    true)` provides, since it only removes the ~9/16 height CAP, not the
///    bound itself — size THEMSELVES to fill all available space in any
///    axis without an explicit factor, then merely align the (much
///    shorter) child inside that box. That's what produced the "opens
///    almost full-screen with a huge empty white area" bug: the sheet's
///    real content might be 3 lines tall, but Center claimed the entire
///    viewport height regardless. Fixed by `heightFactor: 1` (shrink-wrap
///    vertically to content; still fills width so the maxWidth cap stays
///    centered on desktop) plus an explicit `maxHeight` so only content
///    that's genuinely too long to fit scrolls internally, rather than the
///    sheet silently claiming a fixed tall size regardless of content.
/// 2. Content was grouped into always-titled "About/Location/Contact/
///    Online" cards even for a single line of data — replaced with plain
///    icon-prefixed rows and no section headings at all; sparse data (one
///    address, one social link) now renders as just those 1-2 rows, not a
///    full templated page.
///
/// [description] is passed in already-resolved by the caller (rather than
/// derived here from [store]) so the Store page's own existing
/// catalog.store-then-nav-param fallback stays the single source of truth
/// for which description wins.
const double _maxSheetWidth = 480;

/// Merges [store]'s top-level `website` into its `socialLinks` map so
/// [resolveContactSocialActions]' existing URL-validation/ordering logic
/// can be reused for the Online rows — `website` is never actually nested
/// in socialLinks on the model itself (see MarketplaceStoreBranding's own
/// doc comment), this is purely a local adapter for this one call site.
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

    final contactActions = resolveContactSocialActions(
      phone: store?.phone,
      email: store?.email,
      whatsapp: store?.whatsapp,
    );
    final onlineActions =
        resolveContactSocialActions(socialLinks: _onlineLinksFor(store));

    final viewportHeight = MediaQuery.sizeOf(context).height;

    // heightFactor: 1 is the actual fix for the oversized-sheet bug (see
    // this file's own header comment) — without it, Center fills the full
    // bounded height the modal route offers and just centers the short
    // content inside that empty box.
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _maxSheetWidth,
          maxHeight: viewportHeight * 0.85,
        ),
        child: SafeArea(
          top: false,
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
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'marketplace_store_info_title'.tr(),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    // Visible close action (2026-08-08) — swipe-down and
                    // tap-outside still dismiss this sheet too (Flutter's
                    // showModalBottomSheet defaults, unchanged), but a
                    // mobile web patient without those affordances needs an
                    // explicit, obvious close target.
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'close'.tr(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDescription)
                          _InfoRow(
                            icon: Icons.storefront_outlined,
                            child: Text(
                              trimmedDescription!,
                              style: const TextStyle(
                                  fontSize: 13.5, color: Colors.black87),
                            ),
                          ),
                        if (hasLocation)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
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
                        for (final action in contactActions)
                          _ActionInfoRow(action: action),
                        for (final action in onlineActions)
                          _ActionInfoRow(action: action),
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

/// A single icon-prefixed content row — no section heading, adapts to
/// whatever data density the merchant actually has (2026-08-08). The icon
/// itself is the label (a pin for location, the store's own icon for the
/// description) rather than a generic English heading like "Location".
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: PatientAppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A single tappable contact/social row (2026-08-08) — the sheet's own
/// compact, icon+label-inline presentation of a [ContactSocialAction],
/// distinct from [SocialContactActionButton]'s circle-with-label-below
/// grid style (right for a dedicated action row, too tall for a detail
/// list here).
class _ActionInfoRow extends StatelessWidget {
  const _ActionInfoRow({required this.action});

  final ContactSocialAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: action.onTap,
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: Center(child: action.icon)),
            const SizedBox(width: 10),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether there's anything at all for [showStoreInfoSheet] to show — the
/// Store page uses this to decide whether "Store Info" renders as a
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
  final hasContact = resolveContactSocialActions(
    phone: store?.phone,
    email: store?.email,
    whatsapp: store?.whatsapp,
  ).isNotEmpty;
  final hasOnline =
      resolveContactSocialActions(socialLinks: _onlineLinksFor(store))
          .isNotEmpty;
  return hasDescription || hasLocation || hasContact || hasOnline;
}
