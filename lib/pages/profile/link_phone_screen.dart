import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import 'package:trustydr/pages/bottom_bar.dart';
import 'package:trustydr/widgets/StaticInfoHeader.dart';

enum _Phase { phone, sending, otp, linking, failed }

class LinkPhoneScreen extends StatefulWidget {
  /// true  → replace the full stack with BottomBar after success (consent gate)
  /// false → pop back and show a toast (profile flow)
  final bool navigateToHomeOnSuccess;

  const LinkPhoneScreen({super.key, this.navigateToHomeOnSuccess = false});

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _phoneController = TextEditingController();
  PhoneNumber _number = PhoneNumber(isoCode: 'IQ', dialCode: '+964');
  String _fullPhoneNumber = '';

  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  String? _verificationId;
  int? _resendToken;

  _Phase _phase = _Phase.phone;
  String _failureMessage = '';
  bool _sendingOtp = false;
  bool _completed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp) return;
    if (_fullPhoneNumber.isEmpty) {
      Fluttertoast.showToast(msg: 'auth.enterPhoneNumber'.tr());
      return;
    }
    _sendingOtp = true;

    if (mounted) setState(() => _phase = _Phase.sending);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (_completed) return;
          _completed = true;
          await _linkCredential(credential);
        },
        verificationFailed: (e) {
          _sendingOtp = false;
          if (mounted) {
            setState(() {
              _phase = _Phase.failed;
              _failureMessage = _localizedError(e.code);
            });
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _sendingOtp = false;
          if (mounted) setState(() => _phase = _Phase.otp);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          _sendingOtp = false;
          if (mounted && _phase == _Phase.sending) {
            setState(() => _phase = _Phase.otp);
          }
        },
      );
    } catch (_) {
      _sendingOtp = false;
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _failureMessage = 'otp_send_failed'.tr();
        });
      }
    }
  }

  Future<void> _verifyAndLink() async {
    if (_completed) return;
    final otp = _otpControllers.map((c) => c.text).join();
    if (_verificationId == null || otp.length != 6) {
      Fluttertoast.showToast(msg: 'otp_invalid'.tr());
      return;
    }

    setState(() => _phase = _Phase.linking);

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    await _linkCredential(credential);
  }

  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _phase = _Phase.phone);
      return;
    }

    try {
      _completed = true;
      await user.linkWithCredential(credential);
      await user.reload();
      _onSuccess();
    } on FirebaseAuthException catch (e) {
      _completed = false;
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _failureMessage = _localizedError(e.code);
        });
      }
    } catch (_) {
      _completed = false;
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _failureMessage = 'otp_send_failed'.tr();
        });
      }
    }
  }

  void _onSuccess() {
    if (!mounted) return;
    if (widget.navigateToHomeOnSuccess) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomBar()),
        (_) => false,
      );
    } else {
      Fluttertoast.showToast(msg: 'link_phone.success'.tr());
      Navigator.pop(context, true);
    }
  }

  String _localizedError(String? code) {
    switch (code) {
      case 'credential-already-in-use':
        return 'link_phone.phone_in_use'.tr();
      case 'provider-already-linked':
        return 'link_phone.already_linked'.tr();
      case 'too-many-requests':
        return 'otp_too_many_attempts'.tr();
      default:
        return 'otp_send_failed'.tr();
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
            StaticInfoHeader(
              title: 'link_phone.title'.tr(),
              showBack: !widget.navigateToHomeOnSuccess,
            ),
            const SizedBox(height: 20),
            Text(
              'link_phone.description'.tr(),
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'link_phone.security_note'.tr(),
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.rtl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 30),
            if (_phase == _Phase.phone) _buildPhoneInput(),
            if (_phase == _Phase.sending) _buildSending(),
            if (_phase == _Phase.otp) _buildOtpInput(),
            if (_phase == _Phase.linking) _buildSending(),
            if (_phase == _Phase.failed) _buildFailed(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: InternationalPhoneNumberInput(
              initialValue: _number,
              textFieldController: _phoneController,
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
                _number = num;
                _fullPhoneNumber = num.phoneNumber ?? '';
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _sendOtp,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'link_phone.send_otp'.tr(),
            textDirection: ui.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildSending() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
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
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
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
          onPressed: _verifyAndLink,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'link_phone.link_button'.tr(),
            textDirection: ui.TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            for (final c in _otpControllers) {
              c.clear();
            }
            setState(() => _phase = _Phase.phone);
          },
          child: Text(
            'otp_resend'.tr(),
            textDirection: ui.TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(
            _failureMessage,
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.rtl,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              for (final c in _otpControllers) {
                c.clear();
              }
              setState(() {
                _phase = _Phase.phone;
                _failureMessage = '';
                _completed = false;
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'otp_resend'.tr(),
              textDirection: ui.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
