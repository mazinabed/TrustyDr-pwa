// import 'dart:html' as html;      // ✅ browser APIs
// import 'dart:js' as js;          // ✅ JS bridge

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

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
//     if (!kIsWeb) return;

//     _refresh();

//     // listen for custom JS event
//     js.context.callMethod('addEventListener', [
//       'pwa-install-available',
//       (_) => _refresh(),
//     ]);
//   }

//   void _refresh() {
//     if (!kIsWeb) return;

//     final can = js.context.callMethod('trustyDrCanInstall') as bool? ?? false;
//     if (mounted) setState(() => _canInstall = can);
//   }

//   Future<void> _install() async {
//     final accepted =
//         js.context.callMethod('trustyDrPromptInstall') as bool? ?? false;

//     if (accepted && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Installed!')),
//       );
//       setState(() => _canInstall = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!kIsWeb || !_canInstall) return const SizedBox.shrink();

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.download_rounded),
//           const SizedBox(width: 10),
//           const Expanded(
//             child: Text(
//               'Install TrustyDr for faster access.',
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           TextButton(
//             onPressed: _install,
//             child: const Text('Install'),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
//     if (!_isIos() || _isStandalone()) return const SizedBox.shrink();

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
//               'To install: tap Share ⬆️ then "Add to Home Screen This is a TEST"',
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Single Point of Truth for JS ---
@JS('trustyDrCanInstall')
external bool _canInstallJS();

@JS('trustyDrPromptInstall')
external JSPromise _promptInstallJS();

class TrustyInstallBanner extends StatefulWidget {
  const TrustyInstallBanner({super.key});

  @override
  State<TrustyInstallBanner> createState() => _TrustyInstallBannerState();
}

class _TrustyInstallBannerState extends State<TrustyInstallBanner> {
  bool _isDismissed = false;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroidWeb =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isStandalone =>
      html.window.matchMedia('(display-mode: standalone)').matches;

  @override
  void initState() {
    super.initState();
    _checkStatus();

    // Listen for the 'available' event from your pwa.js
    html.window.addEventListener('pwa-install-available', (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDismissed = prefs.getBool('pwa_hidden') ?? false);
  }

  Future<void> _handleAction() async {
    if (_isAndroidWeb) {
      if (_canInstallJS()) {
        await _promptInstallJS().toDart;
        _dismissForever();
      } else {
        _showToast("Installation is coming soon!");
      }
    } else if (_isIOS) {
      _showIosInstructions();
    }
  }

  void _dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pwa_hidden', true);
    setState(() => _isDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if: Not web, already installed, or user dismissed it.
    if (!kIsWeb || _isStandalone || _isDismissed)
      return const SizedBox.shrink();
    // Only show on Mobile (Big companies rarely show banners on Desktop)
    if (!_isIOS && !_isAndroidWeb) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isIOS
            ? const Color(0xFFFFF9E6)
            : Colors.white, // iOS gets a subtle hint color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(_isIOS ? Icons.apple : Icons.install_mobile,
              color: const Color(0xFF4B96DF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Install TrustyDr',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _isIOS
                      ? 'Tap Share then "Add to Home Screen"'
                      : 'Get the app for a faster experience.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleAction,
            child: Text(_isAndroidWeb ? 'INSTALL' : 'HOW-TO'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: _dismissForever,
          ),
        ],
      ),
    );
  }

  void _showIosInstructions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add to Home Screen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _step(
                1, 'Tap the Share icon in the browser tools', Icons.ios_share),
            const SizedBox(height: 15),
            _step(2, 'Scroll down and tap "Add to Home Screen"',
                Icons.add_box_outlined),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it')),
          ],
        ),
      ),
    );
  }

  Widget _step(int n, String text, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
            radius: 12,
            child: Text('$n', style: const TextStyle(fontSize: 12))),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
        Icon(icon, color: Colors.blue),
      ],
    );
  }

  void _showToast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
