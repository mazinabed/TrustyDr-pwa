// import 'dart:ui' as ui;

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/login_signup/consent_screen.dart';
// import 'package:trustydr/pages/screens.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:page_transition/page_transition.dart';
// import '../bottom_bar.dart';
// import 'package:easy_localization/easy_localization.dart';

// class OTPScreen extends StatefulWidget {
//   final String phoneNumber;
//   const OTPScreen({super.key, required this.phoneNumber});

//   @override
//   _OTPScreenState createState() => _OTPScreenState();
// }

// class _OTPScreenState extends State<OTPScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final List<TextEditingController> otpControllers =
//       List.generate(6, (_) => TextEditingController());
//   final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

//   String? _verificationId;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _sendOTP();
//   }

//   Future<void> _sendOTP() async {
//     setState(() => _isLoading = true);

//     await _auth.verifyPhoneNumber(
//       phoneNumber: widget.phoneNumber,
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await _auth.signInWithCredential(credential);
//         await _checkUserInFirestore();
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         setState(() => _isLoading = false);
//         Fluttertoast.showToast(
//           msg: e.message ?? 'otp_send_failed'.tr(),
//           backgroundColor: Colors.black,
//           textColor: whiteColor,
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           _isLoading = false;
//         });
//         Fluttertoast.showToast(
//           msg: 'otp_sent'.tr(namedArgs: {
//             'phone': widget.phoneNumber,
//           }),
//           backgroundColor: Colors.black,
//           textColor: whiteColor,
//         );
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }

//   Future<void> _verifyOTP() async {
//     String otp = otpControllers.map((c) => c.text).join();
//     if (otp.length != 6) {
//       Fluttertoast.showToast(
//         msg: 'otp_invalid_length'.tr(),
//         backgroundColor: Colors.black,
//         textColor: whiteColor,
//       );
//       return;
//     }

//     if (_verificationId == null) {
//       Fluttertoast.showToast(
//         msg: 'otp_verification_missing'.tr(),
//         backgroundColor: Colors.black,
//         textColor: whiteColor,
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );

//       await _auth.signInWithCredential(credential);
//       await _checkUserInFirestore();
//     } on FirebaseAuthException catch (e) {
//       setState(() => _isLoading = false);
//       Fluttertoast.showToast(
//         msg: e.message ?? 'otp_invalid'.tr(),
//         backgroundColor: Colors.black,
//         textColor: whiteColor,
//       );
//     }
//   }

//   Future<void> _checkUserInFirestore() async {
//     final user = FirebaseAuth.instance.currentUser;
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

//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;

//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('assets/doctor_bg.jpg'),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Stack(
//         children: <Widget>[
//           Positioned(
//             top: 0,
//             left: 0,
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
//               appBar: AppBar(
//                 backgroundColor: Colors.transparent,
//                 elevation: 0,
//                 iconTheme: IconThemeData(color: whiteColor),
//                 leading: IconButton(
//                   icon: Icon(Icons.arrow_back, color: whiteColor),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//               body: ListView(
//                 physics: const BouncingScrollPhysics(),
//                 padding: const EdgeInsets.all(20.0),
//                 children: [
//                   const SizedBox(height: 20),
//                   Text('otp_title'.tr(), style: loginBigTextStyle),
//                   const SizedBox(height: 10),
//                   Text(
//                     'otp_description'.tr(namedArgs: {
//                       'phone': widget.phoneNumber,
//                     }),
//                     style: whiteSmallLoginTextStyle,
//                   ),
//                   const SizedBox(height: 50),
//                   if (_isLoading)
//                     const Center(
//                       child: CircularProgressIndicator(color: Colors.white),
//                     )
//                   else
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: List.generate(6, (index) {
//                         return Container(
//                           width: 50,
//                           height: 50,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200]!.withValues(alpha: 0.3),
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                           child: TextField(
//                             controller: otpControllers[index],
//                             focusNode: focusNodes[index],
//                             style: inputOtpTextStyle,
//                             keyboardType: TextInputType.number,
//                             cursorColor: whiteColor,
//                             textAlign: TextAlign.center,
//                             maxLength: 1,
//                             decoration: const InputDecoration(
//                               counterText: '',
//                               border: InputBorder.none,
//                             ),
//                             onChanged: (v) {
//                               if (v.isNotEmpty && index < 5) {
//                                 FocusScope.of(context)
//                                     .requestFocus(focusNodes[index + 1]);
//                               } else if (v.isEmpty && index > 0) {
//                                 FocusScope.of(context)
//                                     .requestFocus(focusNodes[index - 1]);
//                               }
//                             },
//                           ),
//                         );
//                       }),
//                     ),
//                   const SizedBox(height: 30),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(30),
//                       onTap: _verifyOTP,
//                       child: Container(
//                         height: 50,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(30),
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
//                             Text('otp_verify'.tr(), style: inputLoginTextStyle),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('otp_didnt_receive'.tr(), style: greySmallTextStyle),
//                       const SizedBox(width: 10),
//                       InkWell(
//                         onTap: _sendOTP,
//                         child:
//                             Text('otp_resend'.tr(), style: inputLoginTextStyle),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// // }

// class OTPScreen extends StatefulWidget {
//   final String phoneNumber;
//   const OTPScreen({super.key, required this.phoneNumber});

//   @override
//   State<OTPScreen> createState() => _OTPScreenState();
// }

// class _OTPScreenState extends State<OTPScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   final otpControllers = List.generate(6, (_) => TextEditingController());
//   final focusNodes = List.generate(6, (_) => FocusNode());

//   String? _verificationId;

//   bool _isLoading = false;
//   bool _sendingOtp = false;
//   bool _completed = false;

//   @override
//   void initState() {
//     super.initState();
//     _sendOTP();
//   }

//   Future<void> _sendOTP() async {
//     if (_sendingOtp) return;
//     _sendingOtp = true;

//     if (mounted) setState(() => _isLoading = true);

//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: widget.phoneNumber,
//         timeout: const Duration(seconds: 60),

//         // Auto verify
//         verificationCompleted: (credential) async {
//           if (_completed) return;
//           _completed = true;

//           try {
//             await _auth.signInWithCredential(credential);
//             await _onLoginSuccess();
//           } catch (e) {
//             _completed = false;
//             if (mounted) setState(() => _isLoading = false);
//             Fluttertoast.showToast(msg: 'otp_invalid'.tr());
//           }
//         },

//         verificationFailed: (e) {
//           _sendingOtp = false;
//           if (mounted) setState(() => _isLoading = false);
//           Fluttertoast.showToast(msg: e.message ?? 'otp_send_failed'.tr());
//         },

//         codeSent: (verificationId, _) {
//           _verificationId = verificationId;
//           _sendingOtp = false;
//           if (mounted) setState(() => _isLoading = false);
//         },

//         codeAutoRetrievalTimeout: (verificationId) {
//           _verificationId = verificationId;
//           _sendingOtp = false;
//           if (mounted) setState(() => _isLoading = false);
//         },
//       );
//     } catch (e) {
//       // ✅ IMPORTANT: verifyPhoneNumber can throw BEFORE callbacks
//       _sendingOtp = false;
//       if (mounted) setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: 'otp_send_failed'.tr());
//     }
//   }

//   Future<void> _verifyOTP() async {
//     if (_completed) return;

//     final otp = otpControllers.map((c) => c.text).join();

//     if (_verificationId == null || otp.length != 6) {
//       Fluttertoast.showToast(msg: 'otp_invalid'.tr());
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       _completed = true;

//       final credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );

//       await _auth.signInWithCredential(credential);
//       await _onLoginSuccess();
//     } on FirebaseAuthException catch (e) {
//       _completed = false;
//       if (mounted) setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: e.message ?? 'otp_invalid'.tr());
//     } catch (_) {
//       _completed = false;
//       if (mounted) setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: 'otp_invalid'.tr());
//     }
//   }

//   Future<void> _onLoginSuccess() async {
//     if (!mounted) return;

//     final user = _auth.currentUser;
//     if (user == null) {
//       setState(() => _isLoading = false);
//       _completed = false;
//       return;
//     }

//     bool needsConsent = false;

//     try {
//       needsConsent = await DatabaseService.instance
//           .needsLegalAcceptanceFor(user)
//           .timeout(const Duration(seconds: 8));
//     } catch (_) {
//       // Safety: if something goes wrong, treat as existing user
//       needsConsent = false;
//     }

//     if (!mounted) return;

//     if (needsConsent) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const ConsentScreen(), // we will create this
//         ),
//         (_) => false,
//       );
//     } else {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const BottomBar()),
//         (_) => false,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     for (final c in otpControllers) {
//       c.dispose();
//     }
//     for (final f in focusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: ui.TextDirection.ltr, // 🔒 lock layout
//       child: Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//           centerTitle: true,
//           title: Text('otp_title'.tr(), textDirection: ui.TextDirection.rtl),
//         ),
//         body: ListView(
//           padding: const EdgeInsets.all(20),
//           children: [
//             Text('otp_description'.tr(namedArgs: {'phone': widget.phoneNumber}),
//                 textAlign: TextAlign.center,
//                 textDirection: ui.TextDirection.rtl),
//             const SizedBox(height: 24),
//             Directionality(
//               textDirection: ui.TextDirection.ltr, // ✅ FIX
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: List.generate(6, (i) {
//                   return SizedBox(
//                     width: 48,
//                     child: TextField(
//                       controller: otpControllers[i],
//                       focusNode: focusNodes[i],
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       maxLength: 1,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       decoration: const InputDecoration(counterText: ''),
//                       onChanged: (v) {
//                         if (v.isNotEmpty && i < 5) {
//                           focusNodes[i + 1].requestFocus();
//                         } else if (v.isEmpty && i > 0) {
//                           focusNodes[i - 1].requestFocus();
//                         }
//                       },
//                     ),
//                   );
//                 }),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _verifyOTP,
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 22,
//                       height: 22,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : Text('otp_verify'.tr(),
//                       textDirection: ui.TextDirection.rtl),
//             ),
//             const SizedBox(height: 12),
//             TextButton(
//               onPressed: _isLoading ? null : _sendOTP,
//               child:
//                   Text('otp_resend'.tr(), textDirection: ui.TextDirection.rtl),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// }

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:trustydr/widgets/StaticInfoHeader.dart';
import 'package:trustydr/pages/login_signup/consent_screen.dart';
import 'package:trustydr/pages/bottom_bar.dart';
import 'package:trustydr/services/database_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final otpControllers = List.generate(6, (_) => TextEditingController());
  final focusNodes = List.generate(6, (_) => FocusNode());

  String? _verificationId;

  bool _isLoading = false;
  bool _sendingOtp = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  Future<void> _sendOTP() async {
    if (_sendingOtp) return;
    _sendingOtp = true;

    if (mounted) setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (_completed) return;
          _completed = true;

          try {
            await _auth.signInWithCredential(credential);
            await _onLoginSuccess();
          } catch (_) {
            _completed = false;
            if (mounted) setState(() => _isLoading = false);
            Fluttertoast.showToast(msg: 'otp_invalid'.tr());
          }
        },
        verificationFailed: (e) {
          _sendingOtp = false;
          if (mounted) setState(() => _isLoading = false);
          Fluttertoast.showToast(msg: e.message ?? 'otp_send_failed'.tr());
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          _sendingOtp = false;
          if (mounted) setState(() => _isLoading = false);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          _sendingOtp = false;
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (_) {
      _sendingOtp = false;
      if (mounted) setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'otp_send_failed'.tr());
    }
  }

  Future<void> _verifyOTP() async {
    if (_completed) return;

    final otp = otpControllers.map((c) => c.text).join();

    if (_verificationId == null || otp.length != 6) {
      Fluttertoast.showToast(msg: 'otp_invalid'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      _completed = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      await _onLoginSuccess();
    } catch (_) {
      _completed = false;
      if (mounted) setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'otp_invalid'.tr());
    }
  }

  Future<void> _onLoginSuccess() async {
    if (!mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      _completed = false;
      return;
    }

    bool needsConsent = false;

    try {
      needsConsent = await DatabaseService.instance
          .needsLegalAcceptanceFor(user)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      needsConsent = false;
    }

    if (!mounted) return;

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

  @override
  void dispose() {
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr, // layout always LTR
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            /// Header (same as login)
            StaticInfoHeader(
              title: 'otp_title'.tr(),
              showBack: true,
            ),

            const SizedBox(height: 20),

            Text(
              'otp_description'.tr(namedArgs: {'phone': widget.phoneNumber}),
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl, // Arabic text only
            ),

            const SizedBox(height: 30),

            /// OTP card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 44,
                      child: TextField(
                        controller: otpControllers[i],
                        focusNode: focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
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
                  : Text(
                      'otp_verify'.tr(),
                      textDirection: ui.TextDirection.rtl,
                    ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _isLoading ? null : _sendOTP,
              child: Text(
                'otp_resend'.tr(),
                textDirection: ui.TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
