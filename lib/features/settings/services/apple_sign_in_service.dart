import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInService {
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'Apple Sign-In is not enabled in Firebase Console. '
              'Open Authentication → Sign-in method → Apple and turn it on.';
        case 'invalid-credential':
          return 'Apple credentials were rejected by Firebase. '
              'Check that Apple Sign-In is enabled for project selection-admin.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection and try again.';
        default:
          return error.message ??
              'Firebase authentication failed (${error.code}).';
      }
    }

    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return 'Sign-in was cancelled.';
      }
      return error.message;
    }

    return error.toString();
  }

  static Future<({AuthorizationCredentialAppleID credential, String rawNonce})>
      requestAppleCredentialWithNonce() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    debugPrint('[Apple Sign-In] Requesting Apple ID credential...');
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    debugPrint('[Apple Sign-In] Apple credential received.');

    if (appleCredential.identityToken == null) {
      throw Exception('Apple Sign-In failed: missing identity token.');
    }

    return (credential: appleCredential, rawNonce: rawNonce);
  }

  static Future<UserCredential> signInWithFirebase({
    required AuthorizationCredentialAppleID appleCredential,
    required String rawNonce,
  }) async {
    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: missing identity token.');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    debugPrint('[Apple Sign-In] Signing into Firebase...');
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    debugPrint('[Apple Sign-In] Firebase user: ${userCredential.user?.uid}');

    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    if (givenName != null && givenName.isNotEmpty) {
      final displayName = '$givenName ${familyName ?? ''}'.trim();
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
    }

    return userCredential;
  }

  static Future<UserCredential> signInWithFirebaseFlow() async {
    final result = await requestAppleCredentialWithNonce();
    return signInWithFirebase(
      appleCredential: result.credential,
      rawNonce: result.rawNonce,
    );
  }

  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return SignInWithApple.isAvailable();
    }
    return false;
  }
}
