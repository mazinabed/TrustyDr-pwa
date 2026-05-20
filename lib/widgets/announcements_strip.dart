import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/providers/announcements_provider.dart';
import 'announcement_card.dart';

/// Renders 0–2 stacked announcement cards from the session-cached provider.
///
/// Renders SizedBox.shrink() when:
///   - loading (no layout jump on first render)
///   - error (announcements are non-critical; fail silently)
///   - no active/undismissed announcements
///
/// When non-empty adds 16px bottom padding so the next dashboard section
/// has consistent spacing without a permanent SizedBox in home.dart.
class AnnouncementsStrip extends ConsumerWidget {
  const AnnouncementsStrip({super.key});

  Future<void> _dismiss(WidgetRef ref, String dismissKey) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('dismissedAnnouncements') ?? [];
    if (!list.contains(dismissKey)) {
      list.add(dismissKey);
      await prefs.setStringList('dismissedAnnouncements', list);
    }
    // Re-fetch: removes the dismissed announcement from the rendered list.
    ref.invalidate(announcementsProvider);
  }

  Future<void> _launchCta(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (announcements) {
        if (announcements.isEmpty) return const SizedBox.shrink();

        return Padding(
          // Bottom padding fills the gap to the next dashboard card.
          // Only present when there is actual content.
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < announcements.length; i++) ...[
                AnnouncementCard(
                  announcement: announcements[i],
                  lang: lang,
                  onDismiss: announcements[i].dismissible
                      ? () => _dismiss(ref, announcements[i].dismissKey)
                      : null,
                  onCtaTap: announcements[i].ctaLink != null
                      ? () => _launchCta(announcements[i].ctaLink!)
                      : null,
                ),
                if (i < announcements.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}
