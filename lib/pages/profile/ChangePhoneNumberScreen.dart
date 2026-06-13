import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import 'package:trustydr/widgets/StaticInfoHeader.dart';

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
          textColor: Colors.white);
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
          textColor: Colors.white,
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
          textColor: Colors.white,
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
        textColor: Colors.white,
      );
      return;
    }

    if (_verificationId == null) {
      Fluttertoast.showToast(
        msg: tr('auth.verificationIdMissing'),
        backgroundColor: Colors.black,
        textColor: Colors.white,
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
        textColor: Colors.white,
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
        textColor: Colors.white,
      );

      // ✅ Close screen cleanly
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: '${tr('auth.errorUpdatingPhone')}: $e',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StaticInfoHeader(title: tr('auth.changePhone'), showBack: true),
            const SizedBox(height: 24),
            if (!_otpSent) _buildPhoneSection(context),
            if (_otpSent) _buildOtpSection(context),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection(BuildContext context) {
    return Column(
      children: [
        Text(
          tr('auth.enterNewPhoneNumber'),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.rtl,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
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
                hintText: tr('auth.phoneNumber'),
                border: InputBorder.none,
              ),
              onInputChanged: (PhoneNumber num) {
                phoneNumber = num.phoneNumber ?? '';
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOTP,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            tr('auth.sendOtp'),
            textDirection: ui.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection(BuildContext context) {
    return Column(
      children: [
        Text(
          '${tr('auth.enterOtpSentTo')} $phoneNumber',
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.rtl,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            tr('auth.verifyOtp'),
            textDirection: ui.TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('auth.didntReceiveOtp'),
              textDirection: ui.TextDirection.rtl,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isLoading ? null : _sendOTP,
              child: Text(tr('auth.resend')),
            ),
          ],
        ),
      ],
    );
  }
}
