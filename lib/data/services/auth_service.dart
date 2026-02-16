import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> signOut() async {
    await _auth.signOut();
  }

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<UserCredential> signInWithApple() async {
  // ---------- WEB / PWA ----------
 // ---------- WEB / PWA ----------
if (kIsWeb) {
  final provider = AppleAuthProvider();
  provider.addScope('email');
  provider.addScope('name');

  // ✅ Use popup instead of redirect
  final result = await FirebaseAuth.instance.signInWithPopup(provider);

  if (result.user == null) {
    throw Exception('Apple sign-in failed on web');
  }

  return result;
}

  

  // ---------- NATIVE IOS ----------
  try {
    debugPrint('[AppleAuth] Starting Apple Sign-In');

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    if (appleCredential.identityToken == null ||
        appleCredential.authorizationCode == null) {
      throw FirebaseAuthException(
        code: 'missing-apple-tokens',
        message: 'Apple did not return the required tokens.',
      );
    }

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    final result =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    // Save name once (Apple only provides it first time)
    if (appleCredential.givenName != null) {
      final fullName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();

      await result.user?.updateDisplayName(fullName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
        'name': fullName,
        'email': result.user?.email,
        'provider': 'apple',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return result;
  } catch (e) {
    rethrow;
  }
}


void debugJwt(String jwt) {
  final parts = jwt.split('.');
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  debugPrint('APPLE JWT PAYLOAD = $payload');
}

Future<UserCredential> signInWithGoogle() async {
  final provider = GoogleAuthProvider();
  provider.setCustomParameters({'prompt': 'select_account'});

  if (kIsWeb) {
    // ✅ PWA / Web: use popup (no refresh)
    return await _auth.signInWithPopup(provider);
  } else {
    // ✅ Mobile apps
    return await _auth.signInWithProvider(provider);
  }
}


  // Future<UserCredential> signInWithFacebook() async {
  //   final LoginResult result = await FacebookAuth.instance.login();
  //   final OAuthCredential credential =
  //       FacebookAuthProvider.credential(result.accessToken!.token);
  //   return await _auth.signInWithCredential(credential);
  // }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }
}
