import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trustydr/widgets/static_info_page.dart';
import 'package:trustydr/constant/constant.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticInfoPage(
      title: tr('privacy.title'),
      children: [
        _infoCard(Icons.lock_outline, tr('privacy.p1')),
        SizedBox(height: fixPadding * 2),
        _infoCard(Icons.medical_information_outlined, tr('privacy.p2')),
        SizedBox(height: fixPadding * 2),
        _infoCard(Icons.visibility_outlined, tr('privacy.p3')),
        SizedBox(height: fixPadding * 2),
        _infoCard(Icons.security_outlined, tr('privacy.p4')),
        SizedBox(height: fixPadding * 2),
        _infoCard(Icons.email_outlined, tr('privacy.p5')),
      ],
    );
  }

  Widget _infoCard(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(fixPadding * 1.6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4B96DF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4B96DF), size: 22),
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
