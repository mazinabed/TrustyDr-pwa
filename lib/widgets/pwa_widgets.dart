// import 'dart:html' as html;
// import 'dart:js' as js;
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';

// /// -------------------------------
// /// PWA Install Banner (Chrome/Edge)
// /// -------------------------------
// class PwaInstallBanner extends StatefulWidget {
//   const PwaInstallBanner({super.key});

//   @override
//   State<PwaInstallBanner> createState() => _PwaInstallBannerState();
// }

// class _PwaInstallBannerState extends State<PwaInstallBanner> {
//   bool _canInstall = false;

//   @override
//   void initState() {
//     super.initState();

//     html.window.addEventListener('pwa-install-available', (_) {
//       if (mounted) setState(() => _canInstall = true);
//     });

//     try {
//       final initial =
//           js.context.callMethod('trustyDrCanInstall') as bool? ?? false;
//       _canInstall = initial;
//     } catch (_) {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!kIsWeb || !_canInstall) return const SizedBox.shrink();

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE8F1FF),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFB6D0FF)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.download, color: Color(0xFF4A90E2)),
//           const SizedBox(width: 8),
//           const Expanded(
//             child: Text(
//               'Install TrustyDr for faster access',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               js.context.callMethod('trustyDrPromptInstall');
//             },
//             child: const Text('Install'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// -------------------------------
// /// iOS Add to Home Screen hint
// /// -------------------------------
// class IosInstallHint extends StatelessWidget {
//   const IosInstallHint({super.key});

//   bool _isIos() {
//     final ua = html.window.navigator.userAgent.toLowerCase();
//     return ua.contains('iphone') || ua.contains('ipad');
//   }

//   bool _isStandalone() {
//     return html.window.matchMedia('(display-mode: standalone)').matches;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!kIsWeb || !_isIos() || _isStandalone()) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF6D6),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.info_outline),
//           SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'To install: tap Share ⬆️ then "Add to Home Screen"',
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// -------------------------------
// /// Offline banner (optional)
// /// -------------------------------
// class OfflineBanner extends StatelessWidget {
//   const OfflineBanner({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.red.shade600,
//       padding: const EdgeInsets.all(8),
//       child: const Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.wifi_off, color: Colors.white, size: 16),
//           SizedBox(width: 6),
//           Text(
//             'You are offline',
//             style: TextStyle(color: Colors.white),
//           ),
//         ],
//       ),
//     );
//   }
// }
