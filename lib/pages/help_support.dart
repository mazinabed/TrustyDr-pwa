import 'package:trustydr/widgets/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
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
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4DB6AC),
                  Color(0xFF4B96DF),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
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
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4B96DF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4B96DF),
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
