

import 'dart:js_interop';



import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IosAddToHomeTip extends StatefulWidget {
  const IosAddToHomeTip({super.key});

  @override
  State<IosAddToHomeTip> createState() => _IosAddToHomeTipState();
}

class _IosAddToHomeTipState extends State<IosAddToHomeTip> {
  bool _hidden = false;

  bool get _isWeb => kIsWeb;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;


@JS('trustyDrCanInstall')
external bool _trustyDrCanInstall();

@JS('trustyDrPromptInstall')
external JSPromise _trustyDrPromptInstall();


bool _isAndroidWeb() {
  return kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

bool _canInstallAndroid() {
  return _trustyDrCanInstall();
}



  @override
  void initState() {
    super.initState();
    _loadHidden();
  }

  Future<void> _loadHidden() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hidden = prefs.getBool('pwa_install_hidden') ?? false;
    });
  }

Future<void> _installAndroid() async {
  await _trustyDrPromptInstall().toDart;
}


  Future<void> _hideForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pwa_install_hidden', true);
    setState(() => _hidden = true);
  }

  void _showHowToInstall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Install TrustyDr',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              if (_isIOS) ...[
                _stepRow('1', 'Tap the Share button'),
                const SizedBox(height: 10),
                const Icon(Icons.ios_share, size: 36),
                const SizedBox(height: 20),
                _stepRow('2', 'Select "Add to Home Screen"'),
                const SizedBox(height: 10),
                const Icon(Icons.add_box_outlined, size: 36),
              ] else if (_isAndroid) ...[
                _stepRow('1', 'Tap the menu (⋮) in your browser'),
                const SizedBox(height: 10),
                const Icon(Icons.more_vert, size: 36),
                const SizedBox(height: 20),
                _stepRow('2', 'Tap "Install app"'),
                const SizedBox(height: 10),
                const Icon(Icons.add_to_home_screen, size: 36),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  _hideForever();
                  Navigator.pop(context);
                },
                child: const Text('Got it'),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Widget _stepRow(String number, String text) {
    return Row(
      children: [
        CircleAvatar(radius: 12, child: Text(number)),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWeb) return const SizedBox.shrink();
    if (!_isIOS && !_isAndroid) return const SizedBox.shrink();
    if (_hidden) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Text('📲', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Install TrustyDr',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(
                  'Add this app to your home screen for faster access',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

        TextButton(
  onPressed: () async {
    if (_isAndroidWeb()) {
      if (_canInstallAndroid()) {
        await _installAndroid();   // ← this uses the function
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Install not available yet')),
        );
      }
    } else {
      _showHowToInstall(context); // iOS instructions
    }
  },
  child: Text(_isAndroidWeb() ? 'Install' : 'How to install'),
),

        
        ],
      ),
    );
  }
}


