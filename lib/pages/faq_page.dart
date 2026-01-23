import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trustydr/widgets/static_info_page.dart';
import 'package:trustydr/constant/constant.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticInfoPage(
      title: tr('faq.title'),
      children: [
        _faqCard(Icons.search_outlined, tr('faq.q1'), tr('faq.a1')),
        SizedBox(height: fixPadding * 2),
        _faqCard(Icons.verified_user_outlined, tr('faq.q2'), tr('faq.a2')),
        SizedBox(height: fixPadding * 2),
        _faqCard(Icons.schedule_outlined, tr('faq.q3'), tr('faq.a3')),
        SizedBox(height: fixPadding * 2),
        _faqCard(Icons.payments_outlined, tr('faq.q4'), tr('faq.a4')),
        SizedBox(height: fixPadding * 2),
        _faqCard(Icons.lock_outline, tr('faq.q5'), tr('faq.a5')),
      ],
    );
  }

  Widget _faqCard(IconData icon, String question, String answer) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: blackNormalTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: fixPadding * 0.5),
                Text(
                  answer,
                  style: blackNormalTextStyle.copyWith(height: 1.6),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
