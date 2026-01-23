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
  try {
    debugPrint('[AppleAuth] Starting Apple Sign-In');

    // 1. Generate Nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // 2. Request Credential from Apple
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    debugPrint('[AppleAuth] Apple credential received');
    
    // Safety check: Ensure tokens exist before proceeding
    if (appleCredential.identityToken == null || appleCredential.authorizationCode == null) {
      throw FirebaseAuthException(
        code: 'missing-apple-tokens',
        message: 'Apple did not return the required tokens.',
      );
    }

    // 3. Create Firebase Credential
    // THE FIX: We now include the accessToken (authorizationCode)
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode, // <--- CRITICAL FIX
      rawNonce: rawNonce, 
    );

    // 4. Sign in to Firebase
    final result = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

// UPDATE THE USER'S DISPLAY NAME
if (appleCredential.givenName != null) {
  final String firstName = appleCredential.givenName ?? "";
  final String lastName = appleCredential.familyName ?? "";
  final String fullName = "$firstName $lastName".trim();

  // Save the name to the Firebase user profile
  await result.user?.updateDisplayName(fullName);
  await result.user?.reload(); // Refresh local user state
  final user = result.user!;

  // ✅ SAVE TO FIRESTORE (this is what Home uses)
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({
        'name': fullName,
        'email': user.email,
        'provider': 'apple',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
    debugPrint('[AppleAuth] Firebase sign-in complete. UID=${result.user?.uid}');
    return result;

  } on FirebaseAuthException catch (e) {
    debugPrint('[AppleAuth] FIREBASE ERROR: ${e.code} - ${e.message}');
    rethrow;
  } catch (e, st) {
    debugPrint('[AppleAuth] UNKNOWN ERROR TYPE: ${e.runtimeType}');
    debugPrint('[AppleAuth] ERROR VALUE: $e');
    debugPrintStack(stackTrace: st);
    rethrow;
  }
}



void debugJwt(String jwt) {
  final parts = jwt.split('.');
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  debugPrint('APPLE JWT PAYLOAD = $payload');
}

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
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
