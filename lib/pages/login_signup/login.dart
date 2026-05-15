// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/screens.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:intl_phone_number_input/intl_phone_number_input.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:easy_localization/easy_localization.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   DateTime? currentBackPressTime;

//   String phoneNumber = '';
//   final TextEditingController phoneController = TextEditingController();
//   PhoneNumber number = PhoneNumber(isoCode: 'IQ', dialCode: '+964');

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;

//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//             image: AssetImage('assets/doctor_bg.jpg'), fit: BoxFit.cover),
//       ),
//       child: Stack(
//         children: <Widget>[
//           Positioned(
//             top: 0.0,
//             left: 0.0,
//             child: Container(
//               width: width,
//               height: height,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
//                   colors: [
//                     Colors.black.withValues(alpha: 0.4),
//                     Colors.black.withValues(alpha: 0.55),
//                     Colors.black.withValues(alpha: 0.7),
//                     Colors.black.withValues(alpha: 0.8),
//                     Colors.black.withValues(alpha: 1.0),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             child: Scaffold(
//               backgroundColor: Colors.transparent,
//               body: ListView(
//                 physics: const BouncingScrollPhysics(),
//                 children: <Widget>[
//                   const SizedBox(height: 30.0),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 20.0, left: 20.0),
//                     child: Text('login_title'.tr(), style: loginBigTextStyle),
//                   ),
//                   const SizedBox(height: 10.0),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 20.0),
//                     child: Text('login_subtitle'.tr(),
//                         style: whiteSmallLoginTextStyle),
//                   ),
//                   const SizedBox(height: 30.0),
//                   Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Container(
//                       padding: const EdgeInsets.only(left: 10.0),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[200]!.withValues(alpha: 0.3),
//                         borderRadius: const BorderRadius.all(
//                           Radius.circular(20.0),
//                         ),
//                       ),
//                       child: InternationalPhoneNumberInput(
//                         textStyle: inputLoginTextStyle,
//                         autoValidateMode: AutovalidateMode.disabled,
//                         selectorTextStyle: const TextStyle(
//                             color: Colors.white, fontSize: 16.0),
//                         initialValue: number,
//                         textFieldController: phoneController,
//                         inputBorder: InputBorder.none,
//                         inputDecoration: InputDecoration(
//                           contentPadding:
//                               const EdgeInsets.only(left: 0.0, bottom: 15.0),
//                           hintText: 'phone'.tr(),
//                           hintStyle: inputLoginTextStyle,
//                           border: InputBorder.none,
//                         ),
//                         selectorConfig: const SelectorConfig(
//                             selectorType: PhoneInputSelectorType.DIALOG),
//                         onInputChanged: (PhoneNumber num) {
//                           phoneNumber = num.phoneNumber ?? '';
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(30.0),
//                       onTap: () {
//                         if (phoneNumber.isEmpty) {
//                           Fluttertoast.showToast(
//                               msg: 'please_login'.tr(),
//                               backgroundColor: Colors.black,
//                               textColor: whiteColor);
//                           return;
//                         }
//                         Navigator.push(
//                           context,
//                           PageTransition(
//                             duration: const Duration(milliseconds: 600),
//                             type: PageTransitionType.fade,
//                             child: OTPScreen(phoneNumber: phoneNumber),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         height: 50.0,
//                         width: double.infinity,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(30.0),
//                           gradient: LinearGradient(
//                             begin: Alignment.centerLeft,
//                             end: Alignment.bottomRight,
//                             stops: const [0.1, 0.5, 0.9],
//                             colors: [
//                               Colors.blue[300]!.withValues(alpha: 0.8),
//                               Colors.blue[500]!.withValues(alpha: 0.8),
//                               Colors.blue[800]!.withValues(alpha: 0.8),
//                             ],
//                           ),
//                         ),
//                         child:
//                             Text('continue'.tr(), style: inputLoginTextStyle),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'otp_info'.tr(),
//                     textAlign: TextAlign.center,
//                     style: whiteSmallLoginTextStyle,
//                   ),
//                   const SizedBox(height: 30),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                     child: Column(
//                       children: [
//                         InkWell(
//                           onTap: _loginWithGoogle,
//                           child: Container(
//                             height: 50,
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(30),
//                               color: Colors.red[700],
//                             ),
//                             child: Text('login_continue_google'.tr(),
//                                 style: inputLoginTextStyle),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Future<void> _loginWithFacebook() async {
//   //   setState(() => _isLoading = true);
//   //   try {
//   //     final LoginResult result = await FacebookAuth.instance.login();
//   //     if (result.status == LoginStatus.success) {
//   //       final OAuthCredential credential =
//   //           FacebookAuthProvider.credential(result.accessToken!.token);
//   //       UserCredential userCredential =
//   //           await _auth.signInWithCredential(credential);
//   //       await _checkAndCreateUser(userCredential.user);
//   //     } else {
//   //       Fluttertoast.showToast(
//   //           msg: 'error_generic'.tr(), backgroundColor: Colors.black);
//   //     }
//   //   } catch (e) {
//   //     Fluttertoast.showToast(
//   //         msg: 'error_generic'.tr(), backgroundColor: Colors.black);
//   //   } finally {
//   //     setState(() => _isLoading = false);
//   //   }
//   // }

//   Future<void> _loginWithGoogle() async {
//     setState(() => _isLoading = true);
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) {
//         setState(() => _isLoading = false);
//         return;
//       }
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       await _checkAndCreateUser(userCredential.user);
//     } catch (e) {
//       Fluttertoast.showToast(
//           msg: 'error_generic'.tr(), backgroundColor: Colors.black);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _checkAndCreateUser(User? user) async {
//     if (user == null) return;
//     await DatabaseService.instance.createUserDocument(user);

//     Navigator.pushAndRemoveUntil(
//       context,
//       PageTransition(
//         duration: const Duration(milliseconds: 600),
//         type: PageTransitionType.fade,
//         child: const BottomBar(),
//       ),
//       (route) => false,
//     );
//   }

//   bool onWillPop() {
//     DateTime now = DateTime.now();
//     if (currentBackPressTime == null ||
//         now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
//       currentBackPressTime = now;
//       Fluttertoast.showToast(
//         msg: 'cancel'.tr(),
//         backgroundColor: Colors.black,
//         textColor: whiteColor,
//       );
//       return false;
//     } else {
//       return true;
//     }
//   }
// }

//This secyion is working, but we are adding term and condtions and improve Optemazation too.

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController phoneController = TextEditingController();

//   PhoneNumber number = PhoneNumber(isoCode: 'IQ', dialCode: '+964');
//   String phoneNumber = '';

//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         centerTitle: true,
//         title: Text('login_title'.tr()),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           const SizedBox(height: 20),

//           Text(
//             'login_subtitle'.tr(),
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),

//           const SizedBox(height: 30),

//           /// 📱 Phone input
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 6,
//                 ),
//               ],
//             ),
//             child: InternationalPhoneNumberInput(
//               initialValue: number,
//               textFieldController: phoneController,
//               selectorConfig: const SelectorConfig(
//                 selectorType: PhoneInputSelectorType.DIALOG,
//               ),
//               inputBorder: InputBorder.none,
//               autoValidateMode: AutovalidateMode.disabled,
//               textStyle: const TextStyle(fontSize: 16),
//               selectorTextStyle: const TextStyle(fontSize: 16),
//               inputDecoration: InputDecoration(
//                 hintText: 'phone'.tr(),
//                 border: InputBorder.none,
//               ),
//               onInputChanged: (PhoneNumber num) {
//                 phoneNumber = num.phoneNumber ?? '';
//               },
//             ),
//           ),

//           const SizedBox(height: 30),

//           /// ▶️ Continue button
//           ElevatedButton(
//             onPressed: _isLoading ? null : _continue,
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size.fromHeight(50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             child: _isLoading
//                 ? const SizedBox(
//                     width: 22,
//                     height: 22,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : Text('continue'.tr()),
//           ),

//           const SizedBox(height: 12),

//           Text(
//             'otp_info'.tr(),
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodySmall,
//           ),

//           const SizedBox(height: 30),

//           /// 🔵 Google login (MATCH APP COLOR)
//           ElevatedButton(
//             onPressed: _loginWithGoogle,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF2563EB),
//               minimumSize: const Size.fromHeight(50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             child: Text('login_continue_google'.tr()),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ➡️ Phone → OTP
//   void _continue() {
//     if (phoneNumber.isEmpty || phoneNumber.length < 8) {
//       Fluttertoast.showToast(msg: 'please_login'.tr());
//       return;
//     }

//     // 🔥 IMPORTANT: stop spinner before navigation
//     setState(() => _isLoading = false);

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => OTPScreen(phoneNumber: phoneNumber),
//       ),
//     );
//   }

//   /// 🔐 Google login
//   Future<void> _loginWithGoogle() async {
//     setState(() => _isLoading = true);

//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final userCredential =
//           await FirebaseAuth.instance.signInWithCredential(credential);

//       final user = userCredential.user;
//       if (user == null) return;

//       await DatabaseService.instance.createUserDocument(user);

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const BottomBar()),
//         (_) => false,
//       );
//     } catch (_) {
//       Fluttertoast.showToast(msg: 'error_generic'.tr());
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
// }

// Improved Login Screen with Terms and Conditions
//This is good but I am adding apple login

// import 'dart:ui' as ui;

// import 'package:trustydr/pages/legal_disclaimer_page.dart';
// import 'package:trustydr/pages/login_signup/consent_screen.dart';
// import 'package:trustydr/pages/login_signup/otp.dart';
// import 'package:trustydr/pages/privacy_policy_page.dart';
// import 'package:trustydr/pages/terms_conditions_page.dart';
// import 'package:trustydr/widgets/StaticInfoHeader.dart';
// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:intl_phone_number_input/intl_phone_number_input.dart';

// import 'package:trustydr/pages/bottom_bar.dart';
// import 'package:trustydr/services/database_service.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController phoneController = TextEditingController();

//   PhoneNumber number = PhoneNumber(isoCode: 'IQ', dialCode: '+964');
//   String phoneNumber = '';

//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: ui.TextDirection.ltr, // 🔒 lock layout like ZainCash
//       child: Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         body: ListView(
//           padding: const EdgeInsets.all(20),
//           children: [
//             /// 🔷 Header
//             StaticInfoHeader(
//               title: 'login_title'.tr(),
//               showBack: false,
//             ),

//             const SizedBox(height: 20),

//             Text(
//               'login_title'.tr(),
//               textAlign: TextAlign.center,
//               textDirection:
//                   ui.TextDirection.rtl, // ✅ Arabic/Kurdish reads correctly
//               style: Theme.of(context).textTheme.titleLarge,
//             ),

//             const SizedBox(height: 8),

//             Text(
//               'login_subtitle'.tr(),
//               textAlign: TextAlign.center,
//               textDirection: ui.TextDirection.rtl,
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),

//             const SizedBox(height: 30),

//             /// 📱 Phone input
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 6,
//                   ),
//                 ],
//               ),
//               child: Directionality(
//                 textDirection: ui.TextDirection.ltr,
//                 child: InternationalPhoneNumberInput(
//                   initialValue: number,
//                   textFieldController: phoneController,
//                   selectorConfig: const SelectorConfig(
//                     selectorType: PhoneInputSelectorType.DIALOG,
//                   ),
//                   inputBorder: InputBorder.none,
//                   autoValidateMode: AutovalidateMode.disabled,
//                   textStyle: const TextStyle(fontSize: 16),
//                   selectorTextStyle: const TextStyle(fontSize: 16),
//                   inputDecoration: InputDecoration(
//                     hintText: 'phone'.tr(),
//                     border: InputBorder.none,
//                   ),
//                   onInputChanged: (PhoneNumber num) {
//                     phoneNumber = num.phoneNumber ?? '';
//                   },
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             /// ▶️ Continue button (Phone)
//             ElevatedButton(
//               onPressed: _isLoading ? null : _continue,
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size.fromHeight(50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 22,
//                       height: 22,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : Text('continue'.tr()),
//             ),

//             const SizedBox(height: 12),

//             Text(
//               'otp_info'.tr(),
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodySmall,
//             ),

//             const SizedBox(height: 30),

//             /// 🔵 Google login
//             ElevatedButton(
//               onPressed: _isLoading ? null : _loginWithGoogle,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2563EB),
//                 foregroundColor: Colors.white, // ✅ text + icon color
//                 minimumSize: const Size.fromHeight(50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: Text('login_continue_google'.tr()),
//             ),

//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   /// ➡️ Phone → OTP
//   void _continue() {
//     if (phoneNumber.isEmpty || phoneController.text.trim().length < 7) {
//       Fluttertoast.showToast(msg: 'please_login'.tr());
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => OTPScreen(phoneNumber: phoneNumber),
//       ),
//     );
//   }

//   /// 🔐 Google login
//   Future<void> _loginWithGoogle() async {
//     setState(() => _isLoading = true);

//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final userCredential =
//           await FirebaseAuth.instance.signInWithCredential(credential);

//       final user = userCredential.user;
//       if (user == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       bool needsConsent = false;

//       try {
//         needsConsent = await DatabaseService.instance
//             .needsLegalAcceptanceFor(user)
//             .timeout(const Duration(seconds: 8));
//       } catch (_) {
//         // Safety fallback: allow user through
//         needsConsent = false;
//       }

//       if (!mounted) return;

//       if (needsConsent) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const ConsentScreen()),
//           (_) => false,
//         );
//       } else {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const BottomBar()),
//           (_) => false,
//         );
//       }
//     } catch (_) {
//       Fluttertoast.showToast(msg: 'error_generic'.tr());
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   /// 🔗 Legal link widget
//   Widget _legalLink({required String label, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Text(
//         label,
//         style: const TextStyle(
//           color: Color(0xFF2563EB),
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   /// 📄 Modal bottom sheet
//   void _openLegalModal(BuildContext context, Widget page) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => FractionallySizedBox(
//         heightFactor: 0.92,
//         child: page,
//       ),
//     );
//   }
// }

//adding log in with apple.
import 'dart:ui' as ui;

import 'package:trustydr/features/auth/providers/auth_provider.dart';
import 'package:trustydr/pages/legal_disclaimer_page.dart';
import 'package:trustydr/pages/login_signup/consent_screen.dart';
import 'package:trustydr/pages/login_signup/otp.dart';
import 'package:trustydr/pages/privacy_policy_page.dart';
import 'package:trustydr/pages/terms_conditions_page.dart';
import 'package:trustydr/widgets/StaticInfoHeader.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trustydr/pages/bottom_bar.dart';

// 🔴 IMPORTANT: adjust this import path to where your auth_controller.dart is

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  PhoneNumber number = PhoneNumber(isoCode: 'IQ', dialCode: '+964');
  String phoneNumber = '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StaticInfoHeader(
              title: 'login_title'.tr(),
              showBack: false,
            ),

            const SizedBox(height: 20),

            Text(
              'login_title'.tr(),
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              'login_subtitle'.tr(),
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 30),

            /// 📱 Phone input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: InternationalPhoneNumberInput(
                  initialValue: number,
                  textFieldController: phoneController,
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.DIALOG,
                  ),
                  inputBorder: InputBorder.none,
                  autoValidateMode: AutovalidateMode.disabled,
                  textStyle: const TextStyle(fontSize: 16),
                  selectorTextStyle: const TextStyle(fontSize: 16),
                  inputDecoration: InputDecoration(
                    hintText: 'phone'.tr(),
                    border: InputBorder.none,
                  ),
                  onInputChanged: (PhoneNumber num) {
                    phoneNumber = num.phoneNumber ?? '';
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ▶️ Continue button (Phone)
            ElevatedButton(
              onPressed: _isLoading ? null : _continue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('continue'.tr()),
            ),

            const SizedBox(height: 12),

            Text(
              'otp_info'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 30),

            /// 🍎 Apple login
            // ElevatedButton(
            //   onPressed: _isLoading ? null : _loginWithApple,
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.black,
            //     foregroundColor: Colors.white,
            //     minimumSize: const Size.fromHeight(50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(30),
            //     ),
            //   ),
            //   child: Text('login_continue_apple'.tr()),
            // ),

            // const SizedBox(height: 12),

            /// 🔵 Google login
            ElevatedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('login_continue_google'.tr()),
            ),

            const SizedBox(height: 16),

            Text(
              'login_privacy_note'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ➡️ Phone → OTP
  void _continue() {
    if (phoneNumber.isEmpty || phoneController.text.trim().length < 7) {
      Fluttertoast.showToast(msg: 'please_login'.tr());
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPScreen(phoneNumber: phoneNumber),
      ),
    );
  }

  /// 🍎 Apple login
  Future<void> _loginWithApple() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();
      final user = ref.read(authControllerProvider).value;

      if (user == null) throw Exception();

      final needsConsent = await ref
          .read(authControllerProvider.notifier)
          .checkNeedsConsent(user);

      if (!mounted) return;

      _navigateAfterLogin(needsConsent);
    } catch (e) {
      Fluttertoast.showToast(msg: 'auth_failed_try_again'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔵 Google login
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      final user = ref.read(authControllerProvider).value;

      if (user == null) throw Exception();

      final needsConsent = await ref
          .read(authControllerProvider.notifier)
          .checkNeedsConsent(user);

      if (!mounted) return;

      _navigateAfterLogin(needsConsent);
    } catch (_) {
      Fluttertoast.showToast(msg: 'auth_failed_try_again'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterLogin(bool needsConsent) {
    if (needsConsent) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ConsentScreen()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomBar()),
        (_) => false,
      );
    }
  }
}
