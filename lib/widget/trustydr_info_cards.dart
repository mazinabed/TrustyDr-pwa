// import 'package:trustydr/constant/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:url_launcher/url_launcher.dart';

// class TrustyDrInfoCards extends StatelessWidget {
//   const TrustyDrInfoCards({super.key});

//   Future<void> _openDoctorPortal() async {
//     final uri = Uri.parse('https://doctor.trustydr.com/');

//     try {
//       await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );
//     } catch (e) {
//       debugPrint('Failed to open Doctor Portal: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 170,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: [
//           _infoCard(
//             context,
//             icon: Icons.schedule,
//             title: tr('card_waiting_title'),
//             subtitle: tr('card_waiting_subtitle'),
//           ),
//           const SizedBox(width: 14),
//           _infoCard(
//             context,
//             icon: Icons.event_available,
//             title: tr('card_schedule_title'),
//             subtitle: tr('card_schedule_subtitle'),
//           ),
//           const SizedBox(width: 14),
//           Semantics(
//             label: 'DoctorPortalCTA',
//             button: true,
//             child: _infoCard(
//               context,
//               icon: Icons.medical_services,
//               title: tr('card_doctor_title'),
//               subtitle: tr('card_doctor_subtitle'),
//               onTap: _openDoctorPortal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _infoCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     VoidCallback? onTap,
//   }) {
//     const trustydrBlue = Color(0xFF4B96DF);

//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedScale(
//         duration: const Duration(milliseconds: 120),
//         scale: 1.0,
//         child: SizedBox(
//           width: 280,
//           height: 150,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(22),
//               color: trustydrBlue,
//               boxShadow: [
//                 // Ambient shadow (soft, wide)
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.10),
//                   blurRadius: 24,
//                   offset: const Offset(0, 12),
//                 ),

//                 // Directional shadow (lift)
//                 BoxShadow(
//                   color: trustydrBlue.withOpacity(0.35),
//                   blurRadius: 12,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // 🌊 Soft abstract light shape
//                 Positioned(
//                   top: -40,
//                   right: -40,
//                   child: Container(
//                     width: 140,
//                     height: 140,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white.withOpacity(0.12),
//                     ),
//                   ),
//                 ),

//                 // 🌊 Secondary soft shape
//                 Positioned(
//                   bottom: -30,
//                   left: -30,
//                   child: Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white.withOpacity(0.08),
//                     ),
//                   ),
//                 ),

//                 // 🧱 Content
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Floating icon badge
//                       Container(
//                         width: 38,
//                         height: 38,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.22),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           icon,
//                           size: 18,
//                           color: Colors.white,
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       // Title
//                       Text(
//                         title,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                       ),

//                       const SizedBox(height: 6),

//                       // Subtitle
//                       Expanded(
//                         child: Text(
//                           subtitle,
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                           style:
//                               Theme.of(context).textTheme.bodySmall?.copyWith(
//                                     height: 1.45,
//                                     color: Colors.white.withOpacity(0.85),
//                                   ),
//                         ),
//                       ),

//                       if (onTap != null)
//                         Text(
//                           tr('learn_more'),
//                           style:
//                               Theme.of(context).textTheme.labelMedium?.copyWith(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                         ),
//                     ],
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

import 'package:trustydr/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustyDrInfoCards extends StatefulWidget {
  const TrustyDrInfoCards({super.key});

  @override
  State<TrustyDrInfoCards> createState() => _TrustyDrInfoCardsState();
}

class _TrustyDrInfoCardsState extends State<TrustyDrInfoCards> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  Future<void> _openDoctorPortal() async {
    final uri = Uri.parse('https://doctor.trustydr.com/');

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: [
              _infoCard(
                context,
                icon: Icons.schedule,
                title: tr('card_waiting_title'),
                subtitle: tr('card_waiting_subtitle'),
              ),
              _infoCard(
                context,
                icon: Icons.event_available,
                title: tr('card_schedule_title'),
                subtitle: tr('card_schedule_subtitle'),
              ),
              Semantics(
                label: 'DoctorPortalCTA',
                button: true,
                child: _infoCard(
                  context,
                  icon: Icons.medical_services,
                  title: tr('card_doctor_title'),
                  subtitle: tr('card_doctor_subtitle'),
                  onTap: _openDoctorPortal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? PatientAppColors.brandBlueAlt
                : Colors.grey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    const trustydrBlue = PatientAppColors.brandBlueAlt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: 1.0,
          child: SizedBox(
            width: 280,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: trustydrBlue,
                boxShadow: [
                  // Ambient shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),

                  // Directional shadow
                  BoxShadow(
                    color: trustydrBlue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 🌊 Soft abstract shape
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),

                  // 🌊 Secondary shape
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),

                  // 🧱 Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      height: 1.45,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                          ),
                        ),

                        if (onTap != null)
                          Text(
                            tr('learn_more'),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
