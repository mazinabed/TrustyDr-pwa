// import 'package:flutter/material.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:easy_localization/easy_localization.dart';

// class RecommendationsPage extends StatelessWidget {
//   const RecommendationsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: whiteColor,
//       appBar: AppBar(
//         backgroundColor: whiteColor,
//         elevation: 1,
//         title: Text(
//           tr('recommendations.title'),
//           style: appBarTitleTextStyle,
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.lightbulb_outline,
//                 size: 56,
//                 color: Colors.grey.shade400,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 tr('recommendations.placeholder'),
//                 textAlign: TextAlign.center,
//                 style: blackNormalTextStyle,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:easy_localization/easy_localization.dart';

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // 🔵 Gradient Header (same system as About)
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
                    tr('recommendations.title'),
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
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(fixPadding * 2),
                child: _emptyStateCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fixPadding * 2),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔵 Icon badge (medical style)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4B96DF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 36,
              color: const Color(0xFF4B96DF),
            ),
          ),

          SizedBox(height: fixPadding * 1.5),

          Text(
            tr('recommendations.placeholder'),
            textAlign: TextAlign.center,
            style: blackNormalTextStyle.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
