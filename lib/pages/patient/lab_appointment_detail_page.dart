import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_appointment_item.dart';
import 'package:trustydr/pages/lab/lab_time_slot_page.dart';

class LabAppointmentDetailPage extends StatefulWidget {
  final PatientAppointmentItem item;
  const LabAppointmentDetailPage({super.key, required this.item});

  @override
  State<LabAppointmentDetailPage> createState() =>
      _LabAppointmentDetailPageState();
}

class _LabAppointmentDetailPageState extends State<LabAppointmentDetailPage> {
  final _fs = FirebaseFirestore.instance;

  static String _resolveStreamName(Map<String, dynamic> data, String lang) {
    if (lang == 'ar') {
      final s = (data['providerName_ar'] ?? '').toString();
      if (s.isNotEmpty) return s;
    }
    if (lang == 'ku') {
      final s = (data['providerName_ku'] ?? '').toString();
      if (s.isNotEmpty) return s;
    }
    final en = (data['providerName_en'] ?? '').toString();
    if (en.isNotEmpty) return en;
    return (data['providerName'] ?? '').toString();
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final item = widget.item;
    final isImaging = item.type == PatientAppointmentType.imaging;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          _fs.collection('clinical_requests').doc(item.sourceId).snapshots(),
      builder: (context, snap) {
        final data = (snap.hasData && snap.data!.exists)
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final patientName = (data['patientName'] ?? '').toString();
        final instructions = (data['instructions'] ?? '').toString();
        final providerPhone = (data['providerPhone'] ?? '').toString();
        final collectPayment = (data['collectPayment'] ?? false) == true;
        final paymentStatus = (data['paymentStatus'] ?? '').toString();
        final amountPaid = (data['amountPaid'] as num?)?.toInt() ?? 0;
        final paymentMethod = (data['paymentMethod'] ?? '').toString();

        // Provider display — prefer item snapshot (new records), fallback to
        // Firestore stream fields (old records that predate snapshot fields).
        final displayName = item.providerName(lang).isNotEmpty
            ? item.providerName(lang)
            : _resolveStreamName(data, lang);
        final displayImage = (item.providerImage ?? '').isNotEmpty
            ? item.providerImage!
            : (data['providerImage'] ?? '').toString();
        final displayAddress = (item.locationLabel(lang) ?? '').isNotEmpty
            ? item.locationLabel(lang)!
            : (data['providerAddress'] ?? '').toString();

        final dateStr = _fmtDate(item.appointmentDateTime);
        final timeStr = _fmtTime(item.appointmentDateTime);
        final statusKey = item.statusKey();
        final statusColor = item.statusColor();

        return Scaffold(
          backgroundColor: PatientAppColors.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
            title: Text(
              'DetailTitle'.tr(),
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
              120,
            ),
            children: [
              // ── Provider header card ────────────────────────────────────────
              _card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade200,
                      ),
                      child: displayImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                displayImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _iconPlaceholder(isImaging),
                              ),
                            )
                          : _iconPlaceholder(isImaging),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: blackHeadingTextStyle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          _TypeLabel(isImaging: isImaging),
                          const SizedBox(height: 4),
                          Text(
                            item.serviceLabel(lang),
                            style: TextStyle(
                              color: PatientAppColors.brandIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'status.$statusKey'.tr(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Date / time card ────────────────────────────────────────────
              _card(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: PatientAppColors.brandIndigo, size: 26),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('appointment_time'.tr(),
                            style: greySmallBoldTextStyle),
                        const SizedBox(height: 4),
                        Text('$dateStr • $timeStr',
                            style: blackHeadingTextStyle),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Location card ───────────────────────────────────────────────
              if (displayAddress.isNotEmpty) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: PatientAppColors.brandIndigo),
                          const SizedBox(width: 6),
                          Text('address'.tr(), style: blackHeadingTextStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(displayAddress, style: greyNormalTextStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Phone card ──────────────────────────────────────────────────
              if (providerPhone.isNotEmpty) ...[
                _card(
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          color: PatientAppColors.brandIndigo, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('phone'.tr(), style: greySmallBoldTextStyle),
                          const SizedBox(height: 4),
                          Text(providerPhone, style: blackHeadingTextStyle),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Patient card ────────────────────────────────────────────────
              if (patientName.isNotEmpty ||
                  collectPayment ||
                  paymentStatus.isNotEmpty) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('patient'.tr(), style: blackHeadingTextStyle),
                      const SizedBox(height: 8),
                      if (patientName.isNotEmpty)
                        _row('name'.tr(), patientName),
                      if (paymentStatus.isNotEmpty)
                        _row(
                          'payment'.tr(),
                          amountPaid > 0 && paymentMethod.isNotEmpty
                              ? '$paymentStatus — $amountPaid ($paymentMethod)'
                              : amountPaid > 0
                                  ? '$paymentStatus — $amountPaid'
                                  : paymentStatus,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Instructions card ───────────────────────────────────────────
              if (instructions.isNotEmpty) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('notes'.tr(), style: blackHeadingTextStyle),
                      const SizedBox(height: 8),
                      Text(instructions, style: blackNormalTextStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Actions ─────────────────────────────────────────────────────
              if (item.isUpcoming) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openReschedule(context),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: Text('reschedule'.tr()),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _confirmCancel(item.sourceId, slotId: item.slotId),
                      icon:
                          const Icon(Icons.cancel, color: Colors.red, size: 18),
                      label: Text(
                        'cancel'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openReschedule(BuildContext context) {
    final item = widget.item;
    final labId = item.labId;
    final centerId = item.centerId;
    final specialtyId = item.specialtyId;
    if (labId == null || centerId == null || specialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr())),
      );
      return;
    }
    final lang = context.locale.languageCode;
    final serviceGroup =
        item.type == PatientAppointmentType.imaging ? 'imaging' : 'laboratory';
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: LabTimeSlotPage(
          labId: labId,
          centerId: centerId,
          facilityName: item.providerName(lang),
          imageUrl: item.providerImage ?? '',
          serviceGroup: serviceGroup,
          specialtyId: specialtyId,
          serviceNameEn: item.serviceLabelEn,
          serviceNameAr: item.serviceLabelAr,
          serviceNameKu: item.serviceLabelKu,
          providerNameEn: item.providerNameEn,
          providerNameAr: item.providerNameAr,
          providerNameKu: item.providerNameKu,
          providerAddress: item.locationLabel('en') ?? '',
          providerImage: item.providerImage ?? '',
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    String requestId, {
    String? slotId,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('cancel_appointment'.tr()),
        content: Text('cancel_appointment_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      final batch = _fs.batch();
      batch.update(
        _fs.collection('clinical_requests').doc(requestId),
        {
          'partnerStatus': 'cancelled',
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (slotId != null) {
        batch.delete(_fs.collection('slot_locks').doc(slotId));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('appointment_canceled'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_generic'.tr())),
        );
      }
    }
  }

  // ── Helpers identical to AppointmentDetailPage ───────────────────────────

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

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: greySmallBoldTextStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: blackNormalTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconPlaceholder(bool isImaging) {
    return Icon(
      isImaging ? Icons.image_search : Icons.science,
      size: 32,
      color: Colors.grey,
    );
  }
}

// ── Type label widget ────────────────────────────────────────────────────────

class _TypeLabel extends StatelessWidget {
  final bool isImaging;
  const _TypeLabel({required this.isImaging});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF5CC6BA).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isImaging ? 'imaging'.tr() : 'lab'.tr(),
        style: const TextStyle(
          color: Color(0xFF5CC6BA),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
