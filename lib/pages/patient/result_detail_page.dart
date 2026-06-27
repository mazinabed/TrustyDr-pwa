import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_results_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_result.dart';
import 'package:trustydr/pages/patient/result_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultDetailPage extends ConsumerWidget {
  final PatientResult result;

  const ResultDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final attachmentsAsync =
        ref.watch(patientResultAttachmentsProvider(result.id));

    final providerDisplay = result.providerName(lang).isNotEmpty
        ? result.providerName(lang)
        : result.serviceCategory;
    final dateDisplay = formatResultDate(result, lang);

    return Scaffold(
      backgroundColor: PatientAppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
        title: Text(
          'my_results'.tr(),
          style: appBarTitleTextStyle.copyWith(
            color: PatientAppColors.brandIndigo,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          fixPadding * 1.6,
          fixPadding,
          fixPadding * 1.6,
          100,
        ),
        children: [
          // ── Provider header card ────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            style: blackHeadingTextStyle.copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 5),
                          ResultCategoryChip(
                              serviceCategory: result.serviceCategory),
                        ],
                      ),
                    ),
                  ],
                ),
                if (result.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'result_ordered_by'.tr(),
                    value: 'doctor_prefix_name'.tr(args: [result.doctorName]),
                  ),
                ],
                if (dateDisplay.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'result_released'.tr(),
                    value: dateDisplay,
                  ),
                ],
              ],
            ),
          ),

          // ── Tests card ──────────────────────────────────────────────────────
          if (result.subTypeItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: isImagingCategory(result.serviceCategory)
                        ? Icons.image_search_outlined
                        : Icons.checklist_outlined,
                    label: 'result_tests'.tr(),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: result.subTypeItems
                        .map((e) => e.displayName(lang))
                        .where((s) => s.isNotEmpty)
                        .map((s) => ResultTestChip(label: s))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // ── Test results table ──────────────────────────────────────────────
          if (result.resultItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'result_test_results'.tr(),
                  ),
                  const Divider(height: 20, color: Color(0xFFEEEEEE)),
                  ...List.generate(result.resultItems.length, (i) {
                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        _ResultItemRow(item: result.resultItems[i], lang: lang),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Doctor note card ────────────────────────────────────────────────
          if (result.doctorNote != null && result.doctorNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.medical_information_outlined,
                    label: 'result_doctor_note'.tr(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          PatientAppColors.brandIndigo.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Text(result.doctorNote!, style: blackNormalTextStyle),
                  ),
                ],
              ),
            ),
          ],

          // ── Lab note card ───────────────────────────────────────────────────
          if (result.releaseResultNote &&
              result.resultNote != null &&
              result.resultNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.notes_outlined,
                    label: 'result_lab_note'.tr(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PatientAppColors.pageBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Text(result.resultNote!, style: blackNormalTextStyle),
                  ),
                ],
              ),
            ),
          ],

          // ── Attachments card ────────────────────────────────────────────────
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.attach_file_outlined,
                  label: 'result_attachments'.tr(),
                ),
                const SizedBox(height: 10),
                attachmentsAsync.when(
                  loading: () => const SizedBox(
                    height: 32,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: PatientAppColors.brandIndigo,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, __) =>
                      Text('error_generic'.tr(), style: greySmallTextStyle),
                  data: (attachments) {
                    if (attachments.isEmpty) {
                      return Text('result_no_attachments'.tr(),
                          style: greySmallTextStyle);
                    }
                    return Column(
                      children: attachments
                          .map((a) => _AttachmentTile(attachment: a))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card helper ───────────────────────────────────────────────────────────────

Widget _card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: whiteColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 12,
        ),
      ],
    ),
    child: child,
  );
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PatientAppColors.brandIndigo, size: 20),
        const SizedBox(width: 8),
        Text(label, style: blackHeadingTextStyle),
      ],
    );
  }
}

// ── Info row (label + value with leading icon) ────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        SizedBox(
          width: 96,
          child: Text(label, style: greySmallBoldTextStyle),
        ),
        Expanded(
          child: Text(
            value,
            style: blackNormalTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Result item row (test name + value + optional per-item note) ──────────────

class _ResultItemRow extends StatelessWidget {
  final PatientResultItem item;
  final String lang;
  const _ResultItemRow({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final name = item.displayName(lang);
    final displayValue =
        (item.unit?.isNotEmpty ?? false) && item.valueDisplay.isNotEmpty
            ? '${item.valueDisplay} ${item.unit}'
            : item.valueDisplay;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(name, style: greySmallBoldTextStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  displayValue,
                  style: blackNormalTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (item.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 3),
            Text(item.note!, style: greySmallTextStyle),
          ],
        ],
      ),
    );
  }
}

// ── Attachment tile ───────────────────────────────────────────────────────────

class _AttachmentTile extends StatefulWidget {
  final PatientAttachment attachment;
  const _AttachmentTile({required this.attachment});

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final url = await FirebaseStorage.instance
          .ref(widget.attachment.storagePath)
          .getDownloadURL();
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_generic'.tr())),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_generic'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.attachment.mimeType.contains('pdf');
    final isImage = widget.attachment.mimeType.startsWith('image/');
    final iconData =
        isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined;
    final iconColor = isPdf
        ? const Color(0xFFE53935)
        : isImage
            ? PatientAppColors.brandTeal
            : PatientAppColors.brandIndigo;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: PatientAppColors.pageBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          widget.attachment.fileName,
          style: blackNormalTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PatientAppColors.brandIndigo,
                ),
              )
            : Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade500),
        onTap: _open,
      ),
    );
  }
}
