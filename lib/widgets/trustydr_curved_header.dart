


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

class TrustyDrCurvedHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const TrustyDrCurvedHeader({
    super.key,
    required this.title,
    this.showBack = true,
    required int height, // kept as requested
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
          gradient: LinearGradient(
            colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  height:50, // Adjusted height to look cleaner in the bar
                ),
              ),

              // ───────── Center: Title ─────────
              Center(
                child: Text(
                  title, // Used the variable title
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // ───────── Back Button (Kept your logic) ─────────
              Positioned(
                // In EN: left is 0. In AR: right is 0.
                left: isRtl ? null : 0,
                right: isRtl ? 0 : null,
                child: SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}