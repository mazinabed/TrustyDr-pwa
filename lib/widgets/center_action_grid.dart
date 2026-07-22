// import 'package:flutter/material.dart';

// class ActionItem {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   ActionItem({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });
// }

// class CenterActionGrid extends StatelessWidget {
//   final List<ActionItem> items;

//   const CenterActionGrid({super.key, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(builder: (context, c) {
//       int count = 3;

//       return GridView.count(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisCount: count,
//         crossAxisSpacing: 24,
//         mainAxisSpacing: 24,
//         childAspectRatio: 1.1,
//         children: items.map(_buildTile).toList(),
//       );
//     });
//   }

// Widget _buildTile(ActionItem item) {
//   return InkWell(
//     onTap: item.onTap,
//     borderRadius: BorderRadius.circular(14),
//     child: Container(
//       height: 96, // 👈 control height
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         gradient: const LinearGradient(
//           colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.10),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           )
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(item.icon, size: 26, color: Colors.white),
//           const SizedBox(height: 6),
//          Text(
//   item.label,
//   textAlign: TextAlign.center,
//   maxLines: 2,
//   overflow: TextOverflow.ellipsis,
//   style: const TextStyle(
//     color: Colors.white,
//     fontSize: 12, // 👈 slightly smaller
//     fontWeight: FontWeight.w600,
//     height: 1.15, // 👈 tighter line spacing
//   ),
// ),

//         ],
//       ),
//     ),
//   );
// }

// }

import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// class CenterActionGrid extends StatelessWidget {
//   final List<ActionItem> items;

//   const CenterActionGrid({super.key, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // We use a small horizontal padding here to let the boxes breathe
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         children: [
//           _buildExpandedTile(items[0]),
//           const SizedBox(width: 10), // Gap between boxes
//           _buildExpandedTile(items[1]),
//           const SizedBox(width: 10),
//           _buildExpandedTile(items[2]),
//         ],
//       ),
//     );
//   }

//   Widget _buildExpandedTile(ActionItem item) {
//     return Expanded(
//       child: AspectRatio(
//         // 0.75 or 0.8 makes them tall rectangles.
//         // 1.0 would make them perfect squares.
//         aspectRatio: 0.9,
//         child: InkWell(
//           onTap: item.onTap,
//           borderRadius: BorderRadius.circular(20),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.12),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 )
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(item.icon, size: 36, color: Colors.white),
//                 const SizedBox(height: 12),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 4),
//                   child: Text(
//                     item.label,
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       height: 1.1,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class CenterActionGrid extends StatelessWidget {
  final List<ActionItem> items;

  // isCollapsed: future scroll-collapse wire. Pass true to hide the grid.
  // Currently always false — wire to a scroll listener when ready.
  final bool isCollapsed;

  const CenterActionGrid({
    super.key,
    required this.items,
    this.isCollapsed = false,
  });

  // Marketplace Home UI Polish (2026-07-22) -- tile content (38px icon +
  // 7px gap + up to 2 lines of 11px label text + 10px vertical padding on
  // each side) is a fixed height, but childAspectRatio sizes each cell
  // relative to its WIDTH. At real phone widths that produced cells ~10px
  // taller than the content needs; Column(mainAxisAlignment: center) split
  // that dead space evenly top/bottom of every tile, so the last row left
  // extra invisible padding directly above whatever followed the grid (the
  // Marketplace card), on top of the explicit SizedBox gap already there.
  // A fixed mainAxisExtent instead sizes every cell to the content itself,
  // independent of column width, removing that hidden slack.
  static const double _tileHeight = 92;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 4 columns when there is enough room; 3 on very narrow devices.
          final use4 = constraints.maxWidth >= 300;
          return GridView.builder(
            // Marketplace Home UI Polish (2026-07-22) -- BoxScrollView
            // (GridView/ListView's base class) auto-absorbs
            // MediaQuery.of(context).padding into a SliverPadding whenever
            // `padding` is left null, regardless of shrinkWrap/physics. The
            // outer page ListView already opts out via its own explicit
            // `padding: EdgeInsets.zero`, but this nested, non-scrolling
            // GridView never did, so on a device that reports non-zero
            // top/bottom safe-area padding (e.g. a phone with a status bar
            // and gesture-nav inset), it silently re-added that padding a
            // second time as extra height -- absent on desktop web, where
            // MediaQuery.padding is 0. An explicit zero opts this GridView
            // out of that auto-padding entirely.
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: use4 ? 4 : 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 8,
              mainAxisExtent: _tileHeight,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildTile(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildTile(ActionItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: PatientAppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 18, color: Colors.white),
                ),
                const SizedBox(height: 7),
                // Marketplace Home UI Polish (2026-07-22) -- reserves the
                // same 2-line label height (11px font * 1.2 line height * 2)
                // for every tile regardless of whether its own label
                // actually wraps. Without this, a short 1-line label (e.g.
                // "Labs") sized itself shorter than a 2-line neighbor in the
                // same row, leaving that tile's own centered content with
                // extra slack below it -- most visible on narrower phone
                // widths, where some labels wrap and others don't, and most
                // noticeable in the last row, directly above the
                // Marketplace card. Reserving a fixed label height makes
                // every tile the same height everywhere, independent of
                // which labels happen to wrap at the current screen width.
                SizedBox(
                  height: 26.5,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PatientAppColors.darkNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
