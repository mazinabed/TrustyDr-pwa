import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_prescriptions_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_referral_request.dart';
import 'package:trustydr/pages/patient/referral_detail_page.dart';
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class MyPrescriptionsPage extends ConsumerWidget {
  final bool showBack;

  const MyPrescriptionsPage({super.key, this.showBack = true});

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
                  title: 'my_prescriptions'.tr(),
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
                              backgroundColor: PatientAppColors.brandTeal,
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
            return Scaffold(
              backgroundColor: PatientAppColors.pageBackground,
              body: content,
            );
          },
        ),
      );
    }

    final rxAsync = ref.watch(patientPrescriptionsProvider);

    return Scaffold(
      backgroundColor: PatientAppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'my_prescriptions'.tr(),
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
                child: rxAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                  error: (_, __) => Center(
                    child:
                        Text('error_generic'.tr(), style: greyNormalTextStyle),
                  ),
                  data: (prescriptions) {
                    if (prescriptions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medication_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('no_prescriptions'.tr(),
                                style: greyNormalTextStyle),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: prescriptions.length,
                      itemBuilder: (_, i) =>
                          _PrescriptionCard(rx: prescriptions[i]),
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

// ── Prescription card ──────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  final PatientReferralRequest rx;
  const _PrescriptionCard({required this.rx});

  static const _statusOrder = [
    'sent',
    'received',
    'preparing',
    'ready',
    'dispensed',
  ];

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'referral.status_sent'.tr();
      case 'received':
        return 'referral.status_received'.tr();
      case 'preparing':
        return 'referral.status_preparing'.tr();
      case 'ready':
        return 'referral.status_ready_for_pickup'.tr();
      case 'dispensed':
        return 'referral.status_dispensed'.tr();
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.blue;
      case 'received':
        return Colors.orange;
      case 'preparing':
        return Colors.amber.shade700;
      case 'ready':
        return PatientAppColors.statusConfirmed;
      case 'dispensed':
        return PatientAppColors.brandTeal;
      default:
        return Colors.grey;
    }
  }

  bool get _isComplete => rx.partnerStatus == 'dispensed';

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final doctorDisplay = rx.doctorName(lang);
    final pharmacyDisplay = rx.partnerName(lang);
    final status = rx.partnerStatus;
    final statusIdx = _statusOrder.indexOf(status);
    final progressFraction =
        statusIdx < 0 ? 0.0 : (statusIdx + 1) / _statusOrder.length;

    String dateDisplay = '';
    if (rx.createdAt != null) {
      dateDisplay = DateFormat('d MMM yyyy').format(rx.createdAt!);
    }

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
              child: ReferralDetailPage(referralId: rx.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ───────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            PatientAppColors.brandTeal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: PatientAppColors.brandTeal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (doctorDisplay.isNotEmpty)
                            Text(
                              doctorDisplay,
                              style: blackNormalBoldTextStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (pharmacyDisplay.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.local_pharmacy_outlined,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    pharmacyDisplay,
                                    style: greySmallTextStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Progress bar ────────────────────────────────────────
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 3,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isComplete
                          ? PatientAppColors.brandTeal
                          : PatientAppColors.brandTeal.withValues(alpha: 0.55),
                    ),
                  ),
                ),

                // ── Date footer ─────────────────────────────────────────
                if (dateDisplay.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        dateDisplay,
                        style: greySmallTextStyle.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
