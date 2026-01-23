import 'dart:html' as html;      // ✅ browser APIs
import 'dart:js' as js;          // ✅ JS bridge

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _canInstall = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    _refresh();

    // listen for custom JS event
    js.context.callMethod('addEventListener', [
      'pwa-install-available',
      (_) => _refresh(),
    ]);
  }

  void _refresh() {
    if (!kIsWeb) return;

    final can = js.context.callMethod('trustyDrCanInstall') as bool? ?? false;
    if (mounted) setState(() => _canInstall = can);
  }

  Future<void> _install() async {
    final accepted =
        js.context.callMethod('trustyDrPromptInstall') as bool? ?? false;

    if (accepted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installed!')),
      );
      setState(() => _canInstall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_canInstall) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.download_rounded),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Install TrustyDr for faster access.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _install,
            child: const Text('Install'),
          ),
        ],
      ),
    );
  }
}

class IosInstallHint extends StatelessWidget {
  const IosInstallHint({super.key});

  bool _isIos() {
    final ua = html.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad');
  }

  bool _isStandalone() {
    return html.window.matchMedia('(display-mode: standalone)').matches;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIos() || _isStandalone()) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'To install: tap Share ⬆️ then "Add to Home Screen"',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
