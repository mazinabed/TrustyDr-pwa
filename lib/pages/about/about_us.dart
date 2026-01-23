// import 'package:trustydr/constant/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';

// class AboutUs extends StatelessWidget {
//   const AboutUs({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: whiteColor,
//       body: Column(
//         children: [
//           // 🔵 Gradient Header (unchanged)
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).padding.top + fixPadding * 2,
//               bottom: fixPadding * 3,
//             ),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF4DB6AC),
//                   Color(0xFF4B96DF),
//                 ],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(28),
//               ),
//             ),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'about.title'.tr(),
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 48), // balance back button
//               ],
//             ),
//           ),

//           // ⚪ Content with cards
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(fixPadding * 2),
//               children: [
//                 _aboutCard(context, 'about.p1'.tr()),
//                 SizedBox(height: fixPadding * 1.5),
//                 _aboutCard(context, 'about.p2'.tr()),
//                 SizedBox(height: fixPadding * 1.5),
//                 _aboutCard(context, 'about.p3'.tr()),
//                 SizedBox(height: fixPadding * 3),
//                 Center(
//                   child: Column(
//                     children: [
//                       Text(
//                         'footer.rights'.tr(),
//                         style: blackSmallTextStyle.copyWith(
//                           color: Colors.grey,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'footer.website'.tr(),
//                         style: blackSmallTextStyle.copyWith(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _aboutCard(BuildContext context, String text) {
//     return Container(
//       padding: EdgeInsets.all(fixPadding * 1.5),
//       decoration: BoxDecoration(
//         color: whiteColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Text(
//         text,
//         style: blackNormalTextStyle.copyWith(height: 1.6),
//         textAlign: TextAlign.justify,
//       ),
//     );
//   }
// }

import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/widgets/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // 🔵 Gradient Header (consistent with app)
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
                    'about.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance arrow
              ],
            ),
          ),

          // ⚪ Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(fixPadding * 2),
              children: [
                _aboutCard(
                  icon: Icons.verified_user_outlined,
                  text: 'about.p1'.tr(),
                ),
                SizedBox(height: fixPadding * 2),
                _aboutCard(
                  icon: Icons.phone_disabled_outlined,
                  text: 'about.p2'.tr(),
                ),
                SizedBox(height: fixPadding * 2),
                _aboutCard(
                  icon: Icons.schedule_outlined,
                  text: 'about.p3'.tr(),
                ),
                _aboutCard(
                  icon: Icons.medical_information_outlined,
                  text: 'about.p4'.tr(),
                ),

                //Footer
                const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.all(fixPadding * 1.6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF), // very subtle tint
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
          // 🔵 Icon badge
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
              style: blackNormalTextStyle.copyWith(height: 1.75),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
