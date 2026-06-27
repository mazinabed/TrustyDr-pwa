import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_referral_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_referral_request.dart';

class ReferralDetailPage extends ConsumerWidget {
  final String referralId;
  const ReferralDetailPage({super.key, required this.referralId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final async = ref.watch(patientReferralProvider(referralId));

    return Scaffold(
      backgroundColor: PatientAppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
        title: Text(
          'referral.page_title'.tr(),
          style: appBarTitleTextStyle.copyWith(
            color: PatientAppColors.brandIndigo,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (referral) {
          if (referral == null) return const SizedBox.shrink();
          return _ReferralBody(referral: referral, lang: lang);
        },
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  final PatientReferralRequest referral;
  final String lang;
  const _ReferralBody({required this.referral, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        fixPadding * 1.6,
        fixPadding,
        fixPadding * 1.6,
        120,
      ),
      children: [
        // ── Partner header card ───────────────────────────────────────────────
        _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderAvatar(imageUrl: referral.partnerImage),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.partnerName(lang),
                      style: blackHeadingTextStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    if (referral.serviceName(lang).isNotEmpty)
                      Text(
                        referral.serviceName(lang),
                        style: TextStyle(
                          color: PatientAppColors.brandIndigo,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    if (referral.partnerCity.isNotEmpty ||
                        referral.partnerProvince.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [referral.partnerCity, referral.partnerProvince]
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: greySmallTextStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Sender card (doctor + center) ─────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.person_outline,
                label: 'referral.from_doctor'.tr(),
              ),
              const SizedBox(height: 10),
              _row('doctor_prefix_name'.tr(args: [referral.doctorName(lang)])),
              if (referral.doctorSpecialty(lang).isNotEmpty)
                _subRow(referral.doctorSpecialty(lang)),
              if (referral.centerName(lang).isNotEmpty) ...[
                const SizedBox(height: 6),
                _row(referral.centerName(lang),
                    label: 'referral.center_label'.tr()),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Address card ──────────────────────────────────────────────────────
        if (referral.partnerAddress.isNotEmpty) ...[
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    color: PatientAppColors.brandIndigo, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('referral.address'.tr(),
                          style: greySmallBoldTextStyle),
                      const SizedBox(height: 4),
                      Text(referral.partnerAddress,
                          style: blackNormalTextStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Phone card ────────────────────────────────────────────────────────
        if (referral.partnerPhone.isNotEmpty) ...[
          _card(
            child: Row(
              children: [
                Icon(Icons.phone_outlined,
                    color: PatientAppColors.brandIndigo, size: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('referral.phone'.tr(), style: greySmallBoldTextStyle),
                    const SizedBox(height: 4),
                    Text(referral.partnerPhone, style: blackHeadingTextStyle),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Instructions card ─────────────────────────────────────────────────
        if (referral.instructions.isNotEmpty) ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.assignment_outlined,
                  label: 'referral.instructions'.tr(),
                ),
                const SizedBox(height: 10),
                Text(referral.instructions, style: blackNormalTextStyle),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Status timeline ───────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.timeline_outlined,
                label: 'referral.status_title'.tr(),
              ),
              const SizedBox(height: 16),
              _StatusTimeline(referral: referral),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Results notice ────────────────────────────────────────────────────
        if (!referral.isReleased)
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline,
                    color: Colors.orange.shade600, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'referral.results_pending'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'referral.results_pending_body'.tr(),
                        style: greySmallTextStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
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

  Widget _row(String value, {String? label}) {
    if (label != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: greySmallBoldTextStyle),
            ),
            Expanded(
              child: Text(value,
                  style: blackNormalTextStyle, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }
    return Text(value, style: blackNormalTextStyle);
  }

  Widget _subRow(String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(value, style: greySmallTextStyle),
    );
  }
}

// ── Status timeline widget ────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final PatientReferralRequest referral;
  const _StatusTimeline({required this.referral});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(referral);
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _TimelineRow(
          label: step.label,
          done: step.done,
          active: step.active,
          isLast: isLast,
        );
      }),
    );
  }

  static List<_Step> _buildSteps(PatientReferralRequest r) {
    final ps = r.partnerStatus;
    final st = r.status;

    final sentDone = true;
    final receivedDone =
        ps == 'received' || ps == 'checkedIn' || ps == 'completed';
    final checkedInDone = ps == 'checkedIn' || ps == 'completed';
    final inProgressDone = st == 'in_progress' || st == 'completed';
    final completedDone = st == 'completed';

    return [
      _Step(
        label: 'referral.status_sent'.tr(),
        done: sentDone,
        active: ps == 'sent' && st == 'pending',
      ),
      _Step(
        label: 'referral.status_received'.tr(),
        done: receivedDone,
        active: ps == 'received',
      ),
      _Step(
        label: 'referral.status_checked_in'.tr(),
        done: checkedInDone,
        active: ps == 'checkedIn' && st != 'in_progress' && st != 'completed',
      ),
      _Step(
        label: 'referral.status_in_progress'.tr(),
        done: inProgressDone,
        active: st == 'in_progress',
      ),
      _Step(
        label: 'referral.status_completed'.tr(),
        done: completedDone,
        active: completedDone,
      ),
    ];
  }
}

class _Step {
  final String label;
  final bool done;
  final bool active;
  const _Step({required this.label, required this.done, required this.active});
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final bool isLast;
  const _TimelineRow({
    required this.label,
    required this.done,
    required this.active,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? PatientAppColors.brandTeal
        : active
            ? PatientAppColors.brandIndigo
            : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done || active ? color : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color:
                      done ? PatientAppColors.brandTeal : Colors.grey.shade200,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
              color: done || active ? Colors.black87 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section header widget ─────────────────────────────────────────────────────

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

// ── Provider avatar widget ────────────────────────────────────────────────────

class _ProviderAvatar extends StatelessWidget {
  final String imageUrl;
  const _ProviderAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _LabIcon(),
              ),
            )
          : const _LabIcon(),
    );
  }
}

class _LabIcon extends StatelessWidget {
  const _LabIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.biotech, size: 32, color: Colors.grey);
  }
}
