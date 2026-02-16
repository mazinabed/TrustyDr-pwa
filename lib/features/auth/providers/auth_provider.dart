import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trustydr/data/services/auth_service.dart';
import 'package:trustydr/services/database_service.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  String? _verificationId;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      state = AsyncValue.data(cred.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

Future<void> handleWebRedirectResult() async {
  if (!kIsWeb) return;

  try {
    final result = await FirebaseAuth.instance.getRedirectResult();

    if (result.user != null) {
      state = AsyncValue.data(result.user);
    }
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}


Future<void> signInWithApple() async {
  state = const AsyncValue.loading();
  try {
    final cred = await ref.read(authServiceProvider).signInWithApple();
    state = AsyncValue.data(cred.user);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}



Future<bool> checkNeedsConsent(User user) async {
  return await DatabaseService.instance.needsLegalAcceptanceFor(user);
}

  // Future<void> signInWithFacebook() async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final cred = await ref.read(authServiceProvider).signInWithFacebook();
  //     state = AsyncValue.data(cred.user);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).verifyPhoneNumber(
            phoneNumber: phone,
            verificationCompleted: (credential) async {
              final res = await _auth.signInWithCredential(credential);
              state = AsyncValue.data(res.user);
            },
            verificationFailed: (e) {
              state = AsyncValue.error(e, StackTrace.current);
            },
            codeSent: (verificationId, resendToken) {
              _verificationId = verificationId;
              state = const AsyncValue.data(null);
            },
            codeAutoRetrievalTimeout: (verificationId) {
              _verificationId = verificationId;
            },
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOtp(String code) async {
    state = const AsyncValue.loading();
    try {
      final cred = await ref.read(authServiceProvider).signInWithSmsCode(
            verificationId: _verificationId!,
            smsCode: code,
          );
      state = AsyncValue.data(cred.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> registerWithEmail(String email, String pass) async {
    state = const AsyncValue.loading();
    try {
      final cred =
          await ref.read(authServiceProvider).registerWithEmail(email, pass);
      state = AsyncValue.data(cred.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
