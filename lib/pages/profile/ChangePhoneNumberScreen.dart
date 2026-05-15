import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class ChangePhoneNumberScreen extends StatefulWidget {
  const ChangePhoneNumberScreen({super.key});

  @override
  _ChangePhoneNumberScreenState createState() =>
      _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState extends State<ChangePhoneNumberScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String phoneNumber = '';
  final TextEditingController phoneController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'IQ');

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  String? _verificationId;

  bool _isLoading = false;
  bool _otpSent = false;

  User? currentUser;
  DocumentReference? userRef;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      userRef = _firestore.collection('users').doc(currentUser!.uid);
    }
  }

  Future<void> _sendOTP() async {
    if (phoneNumber.isEmpty) {
      Fluttertoast.showToast(
          msg: tr('auth.enterPhoneNumber'),
          backgroundColor: Colors.black,
          textColor: whiteColor);
      return;
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await currentUser!.updatePhoneNumber(credential);
        await _updatePhoneNumber();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: e.message ?? tr('auth.otpSendingFailed'),
          backgroundColor: Colors.black,
          textColor: whiteColor,
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
          _otpSent = true;
        });
        Fluttertoast.showToast(
          msg: '${tr('auth.otpSentTo')} $phoneNumber',
          backgroundColor: Colors.black,
          textColor: whiteColor,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    String otp = otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      Fluttertoast.showToast(
        msg: tr('auth.enterCompleteOtp'),
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );
      return;
    }

    if (_verificationId == null) {
      Fluttertoast.showToast(
        msg: tr('auth.verificationIdMissing'),
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await currentUser!.updatePhoneNumber(credential);
      await _updatePhoneNumber();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: e.message ?? tr('auth.invalidOtp'),
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );
    }
  }

  Future<void> _updatePhoneNumber() async {
    if (userRef == null) return;

    try {
      await userRef!.update({'phoneNumber': phoneNumber});

      if (!mounted) return;

      // ✅ Reset OTP state
      for (final c in otpControllers) {
        c.clear();
      }

      setState(() {
        _isLoading = false;
        _otpSent = false;
        _verificationId = null;
      });

      Fluttertoast.showToast(
        msg: tr('auth.phoneUpdatedSuccessfully'),
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );

      // ✅ Close screen cleanly
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: '${tr('auth.errorUpdatingPhone')}: $e',
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/doctor_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 1.0),
                  ],
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: whiteColor),
              title:
                  Text(tr('auth.changePhone'), style: whiteSmallLoginTextStyle),
            ),
            body: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                if (!_otpSent)
                  Column(
                    children: [
                      Text(tr('auth.enterNewPhoneNumber'),
                          style: loginBigTextStyle),
                      const SizedBox(height: 20),
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: InternationalPhoneNumberInput(
                          textStyle: inputLoginTextStyle,
                          autoValidateMode: AutovalidateMode.disabled,
                          selectorTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 16.0),
                          initialValue: number,
                          textFieldController: phoneController,
                          inputBorder: InputBorder.none,
                          inputDecoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.only(left: 0.0, bottom: 15.0),
                            hintText: tr('auth.phoneNumber'),
                            hintStyle: inputLoginTextStyle,
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.grey[200]!.withValues(alpha: 0.3),
                          ),
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.DIALOG,
                          ),
                          onInputChanged: (PhoneNumber num) {
                            phoneNumber = num.phoneNumber ?? '';
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: _sendOTP,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.5, 0.9],
                              colors: [
                                Colors.blue[300]!.withValues(alpha: 0.8),
                                Colors.blue[500]!.withValues(alpha: 0.8),
                                Colors.blue[800]!.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Text(tr('auth.sendOtp'),
                              style: inputLoginTextStyle),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text('${tr('auth.enterOtpSentTo')} $phoneNumber',
                          style: loginBigTextStyle),
                      const SizedBox(height: 50),
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[200]!.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: otpControllers[index],
                                focusNode: focusNodes[index],
                                style: inputOtpTextStyle,
                                keyboardType: TextInputType.number,
                                cursorColor: whiteColor,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) {
                                  if (v.isNotEmpty && index < 5) {
                                    FocusScope.of(context)
                                        .requestFocus(focusNodes[index + 1]);
                                  } else if (v.isEmpty && index > 0) {
                                    FocusScope.of(context)
                                        .requestFocus(focusNodes[index - 1]);
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: _verifyOTP,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.5, 0.9],
                              colors: [
                                Colors.blue[300]!.withValues(alpha: 0.8),
                                Colors.blue[500]!.withValues(alpha: 0.8),
                                Colors.blue[800]!.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Text(tr('auth.verifyOtp'),
                              style: inputLoginTextStyle),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tr('auth.didntReceiveOtp'),
                              style: greySmallTextStyle),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _sendOTP,
                            child: Text(tr('auth.resend'),
                                style: inputLoginTextStyle),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
