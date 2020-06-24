// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Phone number auth provider.
class PhoneAuthProvider implements AuthProvider {
  PhoneAuthProvider({FirebaseAuthPlatform auth}) {
    // todo
  }

  final String providerId = 'phone';

  // todo: are these props actually needed, see:
  // https://firebase.google.com/docs/reference/js/firebase.auth.FacebookAuthProvider

  /// This corresponds to the sign-in method identifier.
  static String PHONE_SIGN_IN_METHOD;
  static String PROVIDER_ID;

  /// Starts a phone number authentication flow by sending a verification code to the
  /// given phone number.
  /// Returns an ID that can be passed to [PhoneAuthProvider.credential] to identify
  /// this flow.
  Future<String> verifyPhoneNumber(
      dynamic phoneInfoOptions, ApplicationVerifier applicationVerifier) {
    // todo: implement
    // phoneInfoOptions may be a string or PhoneInfoOptions
  }

  // todo: rename getCredential w/o 'get' prefix?
  // (String verificationId, String verificationCode)

  /// The auth provider credential.
  static AuthCredential getCredential({
    @required String verificationId,
    @required String smsCode,
  }) {
    return PhoneAuthCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}
