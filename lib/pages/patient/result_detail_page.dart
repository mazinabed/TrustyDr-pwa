import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_results_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_result.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultDetailPage extends ConsumerWidget {
  final PatientResult result;

  const ResultDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final attachmentsAsync =
        ref.watch(patientResultAttachmentsProvider(result.id));

    return Scaffold(
      backgroundColor: PatientAppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
        title: Text(
          'my_results'.tr(),
          style: appBarTitleTextStyle.copyWith(
              color: PatientAppColors.brandIndigo),
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
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: PatientAppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.science_outlined,
                          size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.serviceCategory.isNotEmpty)
                            Text(result.serviceCategory,
                                style: blackHeadingTextStyle),
                          if (result.subTypeItems.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              result.subTypeItems
                                  .map((e) => e.displayName(lang))
                                  .where((s) => s.isNotEmpty)
                                  .join(' • '),
                              style: greySmallTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (result.doctorName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${'doctor_prefix'.tr()} ${result.doctorName}',
                              style: const TextStyle(
                                color: PatientAppColors.brandIndigo,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (result.dateKey.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(result.dateKey, style: greySmallTextStyle),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (result.resultItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('notes'.tr(), style: blackHeadingTextStyle),
                  const SizedBox(height: 8),
                  ...result.resultItems.map(
                    (item) => _resultRow(
                      item.displayName(lang),
                      item.valueDisplay,
                      item.unit,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (result.doctorNote != null && result.doctorNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_outlined,
                          color: PatientAppColors.brandIndigo, size: 20),
                      const SizedBox(width: 6),
                      Text('result_doctor_note'.tr(),
                          style: blackHeadingTextStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(result.doctorNote!, style: blackNormalTextStyle),
                ],
              ),
            ),
          ],
          if (result.releaseResultNote &&
              result.resultNote != null &&
              result.resultNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes_outlined,
                          color: PatientAppColors.brandIndigo, size: 20),
                      const SizedBox(width: 6),
                      Text('notes'.tr(), style: blackHeadingTextStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(result.resultNote!, style: blackNormalTextStyle),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        color: PatientAppColors.brandIndigo, size: 20),
                    const SizedBox(width: 6),
                    Text('result_attachments'.tr(),
                        style: blackHeadingTextStyle),
                  ],
                ),
                const SizedBox(height: 8),
                attachmentsAsync.when(
                  loading: () => const CircularProgressIndicator(
                    color: PatientAppColors.brandIndigo,
                    strokeWidth: 2,
                  ),
                  error: (_, __) =>
                      Text('error_generic'.tr(), style: greySmallTextStyle),
                  data: (attachments) {
                    if (attachments.isEmpty) {
                      return Text('no_results'.tr(), style: greySmallTextStyle);
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _resultRow(String name, String value, String? unit) {
    final displayValue =
        unit != null && unit.isNotEmpty ? '$value $unit' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name, style: greySmallBoldTextStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: blackNormalTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final isImage = widget.attachment.mimeType.startsWith('image/');
    final icon = isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: PatientAppColors.brandIndigo),
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
          : const Icon(Icons.open_in_new,
              size: 18, color: PatientAppColors.brandIndigo),
      onTap: _open,
    );
  }
}
