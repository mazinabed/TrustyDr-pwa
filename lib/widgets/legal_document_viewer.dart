import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Legal Consent Modernization (Patient app, v2) — multilingual document
/// viewer (English | العربية | کوردی), ported from TrustyDr Commerce's own
/// widget (app/lib/widgets/legal_document_viewer.dart) to reuse the exact
/// same pattern: a three-tab reader backed by dedicated plain-text assets
/// under `assets/legal/v2/<lang>/<documentKey>.txt`. Switching tabs changes
/// only which translation of the SAME document/version is shown — it never
/// touches `context.locale` (the app's own UI language), and there is
/// exactly one acceptance record per document/version regardless of which
/// tab was read.
///
/// Each tab's content gets its own [Directionality] (LTR for English, RTL
/// for Arabic/Kurdish) independent of the app's ambient locale direction.
enum _LegalLanguage {
  en('en', 'English', ui.TextDirection.ltr),
  ar('ar', 'العربية', ui.TextDirection.rtl),
  ku('ku', 'کوردی', ui.TextDirection.rtl);

  const _LegalLanguage(this.code, this.label, this.direction);

  final String code;
  final String label;
  final ui.TextDirection direction;
}

/// [documentKey] selects the asset file (`patient_terms` or `privacy`) —
/// matching `assets/legal/v2/<lang>/<documentKey>.txt` for all three
/// languages. [version] is shown next to the title when provided (e.g.
/// "v2") — sourced by the caller from the same server-authoritative
/// version the accept callable itself resolves, never invented
/// client-side.
Future<void> showLegalDocument(
  BuildContext context, {
  required String title,
  required String documentKey,
  String? version,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LegalDocumentSheet(
      title: title,
      documentKey: documentKey,
      version: version,
    ),
  );
}

class _LegalDocumentSheet extends StatefulWidget {
  const _LegalDocumentSheet({
    required this.title,
    required this.documentKey,
    this.version,
  });

  final String title;
  final String documentKey;
  final String? version;

  @override
  State<_LegalDocumentSheet> createState() => _LegalDocumentSheetState();
}

class _LegalDocumentSheetState extends State<_LegalDocumentSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<Map<String, String>> _bodiesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _LegalLanguage.values.length,
      vsync: this,
    );
    _bodiesFuture = _loadAllBodies();
  }

  Future<Map<String, String>> _loadAllBodies() async {
    final entries = await Future.wait(
      _LegalLanguage.values.map((lang) async {
        final text = await rootBundle.loadString(
          'assets/legal/v2/${lang.code}/${widget.documentKey}.txt',
        );
        return MapEntry(lang.code, text);
      }),
    );
    return Map.fromEntries(entries);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaHeight * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (widget.version != null && widget.version!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Chip(label: Text(widget.version!)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                tabs: _LegalLanguage.values
                    .map((lang) => Tab(text: lang.label))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<Map<String, String>>(
                  future: _bodiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text('legal_v2_error_loading_document'.tr()),
                      );
                    }
                    final bodies = snapshot.data!;
                    return TabBarView(
                      controller: _tabController,
                      children: _LegalLanguage.values.map((lang) {
                        return Directionality(
                          textDirection: lang.direction,
                          child: SingleChildScrollView(
                            child: Text(
                              bodies[lang.code] ?? '',
                              textAlign: lang.direction == ui.TextDirection.rtl
                                  ? TextAlign.right
                                  : TextAlign.left,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
