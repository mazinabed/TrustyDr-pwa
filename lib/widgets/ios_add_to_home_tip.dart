import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class IosAddToHomeTip extends StatelessWidget {
  const IosAddToHomeTip({super.key});

  bool _isIosSafari() {
    if (!kIsWeb) return false;
    final ua = (defaultTargetPlatform == TargetPlatform.iOS);
    // On Flutter web, defaultTargetPlatform can still help, but not perfect.
    // Good enough as a first pass; we can upgrade later.
    return ua;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIosSafari()) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'On iPhone: tap Share → “Add to Home Screen” to install TrustyDr.',
      ),
    );
  }
}
