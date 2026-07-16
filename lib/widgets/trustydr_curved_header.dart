// import 'package:flutter/material.dart';

// class TrustyDrCurvedHeader extends StatelessWidget {
//   final String title;
//   final bool showBack;

//   const TrustyDrCurvedHeader({
//     super.key,
//     required this.title,
//     this.showBack = true,
//     required int height, // kept as requested
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isRtl = Directionality.of(context) == TextDirection.rtl;

//     const double sideWidth = 48; // same space for logo & back button

//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
//       child: Container(
//         height: 72,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           bottom: false,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // ───────── Left: Logo ─────────
//               Positioned(
//                 left: isRtl ? null : 12,
//                 right: isRtl ? 12 : null,
//                 child: Image.asset(
//                   'assets/icons/white-logo.png',
//                   height: 70,
//                 ),
//               ),

//               // ───────── Center: Title ─────────
//               Center(
//                 child: Text(
//                   'TrustyDr',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.4,
//                   ),
//                 ),
//               ),

//               // ───────── Right: Back button or placeholder ─────────
//         // ───────── Back button (Standard placement) ─────────
// Positioned(
//   // In EN: left is 0. In AR: right is 0.
//   left: isRtl ? null : 0,
//   right: isRtl ? 0 : null,
//   child: SizedBox(
//     width: sideWidth,
//     child: showBack
//         ? IconButton(
//             // Icons.adaptive automatically flips based on locale
//             icon: const Icon(
//               Icons.arrow_back_ios_new,
//               color: Colors.white,
//               size: 20,
//             ),
//             onPressed: () => Navigator.pop(context),
//           )
//         : const SizedBox.shrink(),
//   ),
// ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class TrustyDrCurvedHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  // Optional, purely presentational — defaults to null so every existing
  // caller across the app is completely unaffected. Rendered next to the
  // back button (never touching the opposite/logo edge), so adding it
  // never displaces this widget's own branding placement. Milestone 6
  // (Marketplace persistent Cart action) is this parameter's only caller
  // today; kept generic (not Marketplace-specific) since this file is
  // shared infrastructure used by many non-Marketplace screens.
  final Widget? trailing;

  const TrustyDrCurvedHeader({
    super.key,
    required this.title,
    this.showBack = true,
    required int height, // kept as requested
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    const double sideWidth = 48; // same space for logo & back button

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          gradient: PatientAppColors.brandGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ───────── Logo (Moved to the opposite side of Arrow) ─────────
              Positioned(
                // Swapped logic: In EN (isRtl=false) it goes to the RIGHT.
                // In AR (isRtl=true) it goes to the LEFT.
                left: isRtl ? 12 : null,
                right: isRtl ? null : 12,
                child: Image.asset(
                  'assets/icons/white-logo.png',
                  height: 50, // Adjusted height to look cleaner in the bar
                ),
              ),

              // ───────── Center: Title ─────────
              // Horizontal padding + ellipsis added alongside Milestone 6's
              // optional `trailing` slot: a longer title (e.g. a category
              // name on the Marketplace Products page) must never overlap
              // the back button/trailing icons on a narrow screen — safe
              // and inert for every existing short-title caller too.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sideWidth + (trailing != null ? 40 : 0),
                ),
                child: Center(
                  child: Text(
                    title, // Used the variable title
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // ───────── Back Button (Kept your logic) + optional trailing ─────────
              Positioned(
                // In EN: left is 0. In AR: right is 0.
                left: isRtl ? null : 0,
                right: isRtl ? 0 : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: sideWidth,
                      child: showBack
                          ? IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
