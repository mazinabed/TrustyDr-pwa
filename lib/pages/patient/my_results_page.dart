import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_results_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_result.dart';
import 'package:trustydr/pages/patient/result_detail_page.dart';
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/pages/patient/result_widgets.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class MyResultsPage extends ConsumerWidget {
  final bool showBack;

  const MyResultsPage({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: PatientAppColors.pageBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            Widget content = Column(
              children: [
                TrustyDrCurvedHeader(
                  title: 'my_results'.tr(),
                  showBack: showBack,
                  height: 100,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('login_required'.tr(),
                              style: blackHeadingTextStyle),
                          const SizedBox(height: 10),
                          Text(
                            'please_login'.tr(),
                            textAlign: TextAlign.center,
                            style: greySmallTextStyle,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const LoginScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PatientAppColors.brandIndigo,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'login_button'.tr(),
                              style: whiteColorButtonTextStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
            if (constraints.maxWidth >= 768) {
              content = WebScaffoldContainer(child: content);
            }
            return content;
          },
        ),
      );
    }

    final resultsAsync = ref.watch(patientResultsProvider);

    return Scaffold(
      backgroundColor: PatientAppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'my_results'.tr(),
                showBack: showBack,
                height: 100,
              ),
              Container(
                height: 16,
                decoration: const BoxDecoration(
                  color: PatientAppColors.pageBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: resultsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: PatientAppColors.brandIndigo,
                    ),
                  ),
                  error: (_, __) => Center(
                    child:
                        Text('error_generic'.tr(), style: greyNormalTextStyle),
                  ),
                  data: (results) {
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('no_results'.tr(), style: greyNormalTextStyle),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: results.length,
                      itemBuilder: (_, i) => _ResultCard(result: results[i]),
                    );
                  },
                ),
              ),
            ],
          );
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final PatientResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    final providerDisplay = result.providerName(lang).isNotEmpty
        ? result.providerName(lang)
        : result.serviceCategory;

    final tests = result.subTypeItems
        .map((e) => e.displayName(lang))
        .where((s) => s.isNotEmpty)
        .toList();

    final dateDisplay = formatResultDate(result, lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: ResultDetailPage(result: result),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon + provider name + category chip + attachment badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResultCategoryIcon(serviceCategory: result.serviceCategory),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerDisplay,
                            style: blackNormalBoldTextStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ResultCategoryChip(
                              serviceCategory: result.serviceCategory),
                        ],
                      ),
                    ),
                    if (result.attachmentCount > 0) ...[
                      const SizedBox(width: 8),
                      _AttachmentBadge(count: result.attachmentCount),
                    ],
                  ],
                ),

                // Test chips (max 2 visible + overflow count)
                if (tests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _TestChipsRow(tests: tests, maxVisible: 2),
                ],

                // Doctor + date footer
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (result.doctorName.isNotEmpty) ...[
                      Icon(Icons.person_outline,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'doctor_prefix_name'.tr(args: [result.doctorName]),
                          style: greySmallTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (dateDisplay.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        dateDisplay,
                        style: greySmallTextStyle.copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── List-only widgets ─────────────────────────────────────────────────────────

class _TestChipsRow extends StatelessWidget {
  final List<String> tests;
  final int maxVisible;
  const _TestChipsRow({required this.tests, required this.maxVisible});

  @override
  Widget build(BuildContext context) {
    final visible = tests.take(maxVisible).toList();
    final overflow = tests.length - maxVisible;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...visible.map((t) => ResultTestChip(label: t)),
        if (overflow > 0) ResultTestChip(label: '+$overflow', isOverflow: true),
      ],
    );
  }
}

class _AttachmentBadge extends StatelessWidget {
  final int count;
  const _AttachmentBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PatientAppColors.brandIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file,
              size: 14, color: PatientAppColors.brandIndigo),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              color: PatientAppColors.brandIndigo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
