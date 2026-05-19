import 'package:trustydr/widgets/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // 🔵 Gradient Header (same as About)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + fixPadding * 2,
              bottom: fixPadding * 3,
            ),
            decoration: const BoxDecoration(
              gradient: PatientAppColors.infoGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'help.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ⚪ Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(fixPadding * 2),
              children: [
                _supportCard(
                  icon: Icons.support_agent_outlined,
                  text: 'help.p1'.tr(),
                ),
                SizedBox(height: fixPadding * 2),

                _supportCard(
                  icon: Icons.email_outlined,
                  text: 'help.p2'.tr(),
                ),
                SizedBox(height: fixPadding * 2),

                _supportCard(
                  icon: Icons.feedback_outlined,
                  text: 'help.p3'.tr(),
                ),

                // Footer spacing
                const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportCard({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.all(fixPadding * 1.6),
      decoration: BoxDecoration(
        color: PatientAppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: PatientAppColors.shadowCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PatientAppColors.brandBlueAlt.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: PatientAppColors.brandBlueAlt,
              size: 22,
            ),
          ),
          SizedBox(width: fixPadding),
          Expanded(
            child: Text(
              text,
              style: blackNormalTextStyle.copyWith(height: 1.7),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
