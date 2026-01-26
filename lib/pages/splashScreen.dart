// import 'dart:async';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/main_layout.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:flutter/material.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   bool _navigated = false;

//   @override
//   void initState() {
//     super.initState();
//     _start();
//   }

//   Future<void> _start() async {
//     try {
//       await DatabaseService.instance.initialize();
//       await Future.delayed(const Duration(milliseconds: 800));
//       if (!mounted) return;
//       _routeByAuth();
//     } catch (_) {
//       if (!mounted) return;
//       _showRetryDialog();
//     }
//   }

//   void _routeByAuth() {
//     if (_navigated || !mounted) return;
//     _navigated = true;

//     Navigator.pushReplacement(
//       context,
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 300),
//         pageBuilder: (_, __, ___) => const MainLayout(),
//         transitionsBuilder: (_, anim, __, child) =>
//             FadeTransition(opacity: anim, child: child),
//       ),
//     );
//   }

//   void _showRetryDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: const Text('Connection issue'),
//         content: const Text(
//           'We couldn’t connect to the server. Please check your internet connection.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               Navigator.of(context).pop();
//               try {
//                 await DatabaseService.instance.initialize();
//                 if (!mounted) return;
//                 _routeByAuth();
//               } catch (_) {
//                 if (!mounted) return;
//                 _routeByAuth();
//               }
//             },
//             child: const Text('Retry'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _routeByAuth();
//             },
//             child: const Text('Continue as guest'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isSmall = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
//       backgroundColor: const Color(0xFF4B96DF), // ✅ BRAND BLUE
//       body: SizedBox.expand(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // WHITE LOGO (CENTERED)
//             Image.asset(
//               'assets/icons/logo.png', // ✅ white logo
//               width: isSmall ? 160 : 200,
//               fit: BoxFit.contain,
//             ),

//             const SizedBox(height: 36),

//             // WHITE SPINNER
//             SizedBox(
//               width: 44,
//               height: 44,
//               child: CircularProgressIndicator(
//                 strokeWidth: 3.5,
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//this the oreginal one

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:trustydr/pages/bottom_bar.dart';
// import 'package:trustydr/services/database_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _tCtrl;
//   late AnimationController _dCtrl;
//   late AnimationController _rCtrl;
//   late AnimationController _dotCtrl;

//   bool _navigated = false;

//   @override
//   void initState() {
//     super.initState();

//     _tCtrl = _ctrl();
//     _dCtrl = _ctrl();
//     _rCtrl = _ctrl();
//     _dotCtrl = _ctrl();

//     // chained animation
//     _tCtrl.forward();
//     _tCtrl.addStatusListener((s) {
//       if (s == AnimationStatus.completed) _dCtrl.forward();
//     });
//     _dCtrl.addStatusListener((s) {
//       if (s == AnimationStatus.completed) _rCtrl.forward();
//     });
//     _rCtrl.addStatusListener((s) {
//       if (s == AnimationStatus.completed) _dotCtrl.forward();
//     });

//     _start();
//   }

//   AnimationController _ctrl() {
//     return AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 350),
//     );
//   }

//   Future<void> _start() async {
//     // 🔥 DO NOT AWAIT DATABASE / FIRESTORE
//     DatabaseService.instance.initialize().catchError((e) {
//       debugPrint('[DatabaseService] init failed: $e');
//     });

//     // let animation finish
//     await Future.delayed(const Duration(milliseconds: 1200));

//     if (!mounted) return;
//     _route();
//   }

//   void _route() {
//     if (_navigated) return;
//     _navigated = true;

//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (_, __, ___) => const BottomBar(),
//         transitionsBuilder: (_, a, __, c) =>
//             FadeTransition(opacity: a, child: c),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _tCtrl.dispose();
//     _dCtrl.dispose();
//     _rCtrl.dispose();
//     _dotCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       extendBodyBehindAppBar: true,
//       backgroundColor: const Color(0xFF4B96DF),
//       body: SizedBox.expand(
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _letter('T', 68, _tCtrl),
//               _letter('D', 48, _dCtrl),
//               _letter('r', 44, _rCtrl),
//               _letter('.', 56, _dotCtrl),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _letter(String text, double size, AnimationController ctrl) {
//     final slide = Tween<Offset>(
//       begin: const Offset(0, 0.6),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

//     final fade = Tween<double>(begin: 0, end: 1).animate(ctrl);

//     final scale = Tween<double>(begin: 0.8, end: 1).animate(
//       CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack),
//     );

//     return SlideTransition(
//       position: slide,
//       child: FadeTransition(
//         opacity: fade,
//         child: ScaleTransition(
//           scale: scale,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 2),
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white,
//                 height: 1,
//               ).copyWith(fontSize: size),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:trustydr/pages/bottom_bar.dart';
// import 'package:trustydr/services/database_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   bool _navigated = false;

//   @override
//   void initState() {
//     super.initState();

//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     )..forward();

//     DatabaseService.instance.initialize().catchError((e) {
//       debugPrint('[DatabaseService] init failed: $e');
//     });

//     Future.delayed(const Duration(milliseconds: 900), _route);
//   }

//   void _route() {
//     if (!mounted || _navigated) return;
//     _navigated = true;

//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (_, __, ___) => const BottomBar(),
//         transitionsBuilder: (_, a, __, c) =>
//             FadeTransition(opacity: a, child: c),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF4B96DF),
//       body: Center(
//         child: FadeTransition(
//           opacity: _ctrl,
//           child: ScaleTransition(
//             scale: Tween(begin: 0.95, end: 1.0).animate(_ctrl),
//             child: Image.asset(
//               'assets/images/logo.png',
//               width: 140,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:html' as html; // 👈 Add this for PWA refresh
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trustydr/firebase_options.dart';
import 'package:trustydr/pages/bottom_bar.dart';
import 'package:trustydr/services/database_service.dart';
// Ensure your DatabaseService and BottomBar imports are here

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _navigated = false;
  bool _isUpdateAvailable = false; // 👈 Track if update found

  @override
  void initState() {
    super.initState();
    
    // Your original Animation Controller - DO NOT REMOVE
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // 👈 Listen for the PWA update event from index.html
    html.window.addEventListener('pwa_update_available', (event) {
      if (mounted) {
        setState(() {
          _isUpdateAvailable = true;
        });
      }
    });

    _start();
  }

  Future<void> _start() async {
    try {
      // 1️⃣ Firebase init (required)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));

      debugPrint('[Startup] Firebase initialized');

      // 2️⃣ DatabaseService init (required for auth + consent + profile)
      await DatabaseService.instance
          .initialize()
          .timeout(const Duration(seconds: 5));

      debugPrint('[Startup] DatabaseService initialized');
    } catch (e, st) {
      debugPrint('[Startup] Initialization failed: $e');
      debugPrintStack(stackTrace: st);
    }

    // Keep your splash animation timing
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    
    // 👈 Only route to app if no update is waiting
    if (!_isUpdateAvailable) {
      _route();
    }
  }

  void _route() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const BottomBar(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // 🔒 FORCE LTR FOR SPLASH
      child: Scaffold(
        backgroundColor: const Color(0xFF4B96DF),
        body: Stack( // 👈 Added Stack to show the update button on top
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _letter('T', 68, 0.0, 0.25),
                  _letter('D', 48, 0.25, 0.5),
                  _letter('r', 44, 0.5, 0.75),
                  _letter('.', 56, 0.75, 1.0),
                ],
              ),
            ),
            
            // 👈 The Update UI Overlay
            if (_isUpdateAvailable)
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.white,
                  elevation: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Update Available",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text("A new version of the app is ready."),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => html.window.location.reload(),
                          child: const Text("REFRESH NOW"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _letter(
    String text,
    double size,
    double start,
    double end,
  ) {
    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.8),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(curved),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}