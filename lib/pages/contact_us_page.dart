import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/static_info_page.dart';
import 'package:trustydr/constant/constant.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticInfoPage(
      title: tr('contact.title'),
      children: [
        _infoCard(
          Icons.email_outlined,
          tr('contact.p1'),
        ),
        SizedBox(height: fixPadding * 2),
        _infoCard(
          Icons.support_agent_outlined,
          tr('contact.p2'),
        ),
        SizedBox(height: fixPadding * 2),
        _infoCard(
          Icons.feedback_outlined,
          tr('contact.p3'),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String text) {
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
