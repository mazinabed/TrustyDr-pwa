import 'package:trustydr/pages/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/services/database_service.dart';
import 'package:trustydr/pages/screens.dart';
import 'package:easy_localization/easy_localization.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('registration_failed_no_user');
      }

      await DatabaseService.instance.createUserDocument(user, extra: {
        'username': username,
        'phoneNumber': phone,
        'email': email,
      });

      Fluttertoast.showToast(
        msg: 'registration_success'.tr(),
        backgroundColor: Colors.green[700],
        textColor: Colors.white,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          duration: const Duration(milliseconds: 600),
          type: PageTransitionType.fade,
          child: const BottomBar(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'registration_email_in_use'.tr();
          break;
        case 'invalid-email':
          message = 'registration_invalid_email'.tr();
          break;
        case 'weak-password':
          message = 'registration_weak_password'.tr();
          break;
        default:
          message = e.message ?? 'error_generic'.tr();
      }
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.red[700],
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red[700],
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        title: Text('registration_title'.tr(),
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: whiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('registration_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  )),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _usernameController,
                label: 'full_name'.tr(),
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.isEmpty ? 'full_name_required'.tr() : null,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _emailController,
                label: 'email_address'.tr(),
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'email_required'.tr();
                  if (!v.contains('@')) return 'email_invalid'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                label: 'phone_optional'.tr(),
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                label: 'password'.tr(),
                icon: Icons.lock,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'password_required'.tr();
                  if (v.length < 6) return 'password_min_length'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'confirm_password'.tr(),
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'passwords_not_match'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        'registration_button'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('registration_have_account'.tr(),
                    style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
