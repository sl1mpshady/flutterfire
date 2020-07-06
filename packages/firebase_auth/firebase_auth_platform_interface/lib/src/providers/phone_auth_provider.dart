// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:meta/meta.dart';

const _kProviderId = 'phone';

/// This class should be used to either create a new Phone credential with an
/// verification ID and SMS code.
///
/// Typically this provider will be used when calling [verifyPhoneNumber] to generate
/// a new [PhoneAuthCredential] when a SMS code has been sent.
class PhoneAuthProvider extends AuthProvider {
  PhoneAuthProvider() : super(_kProviderId);

  static String get PHONE_SIGN_IN_METHOD {
    return _kProviderId;
  }

  static String get PROVIDER_ID {
    return _kProviderId;
  }

  /// Create a new [PhoneAuthCredential] from a provided [verificationId] and
  /// [smsCode].
  static AuthCredential credential(String verificationId, String smsCode) {
    assert(verificationId != null);
    assert(smsCode != null);
    return PhoneAuthCredential._credential(verificationId, smsCode);
  }

  /// Create a [PhoneAuthCredential] from an internal token, where the ID relates
  /// to a natively stored credential.
  @protected
  static AuthCredential credentialFromToken(int token) {
    assert(token != null);
    return PhoneAuthCredential._credentialFromToken(token);
  }

  @Deprecated('Deprecated in favor of `PhoneAuthProvider.credential()`')
  static AuthCredential getCredential({
    @required String verificationId,
    @required String smsCode,
  }) {
    return PhoneAuthProvider.credential(verificationId, smsCode);
  }
}

/// The authentical credential returned from calling [PhoneAuthProvider.credential].
class PhoneAuthCredential extends AuthCredential {
  PhoneAuthCredential._({this.verificationId, this.smsCode, this.token})
      : super(
          providerId: _kProviderId,
          signInMethod: _kProviderId,
          token: token,
        );

  factory PhoneAuthCredential._credential(
      String verificationId, String smsCode) {
    return PhoneAuthCredential._(
        verificationId: verificationId, smsCode: smsCode);
  }

  factory PhoneAuthCredential._credentialFromToken(int token) {
    return PhoneAuthCredential._(token: token);
  }

  /// The phone auth verification ID.
  final String verificationId;

  /// The SMS code sent to and entered by the user.
  final String smsCode;

  /// An token relating to a internally stored credential.
  final int token;

  /// Returns the credential as a serialized [Map].
  @override
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'verificationId': verificationId,
      'smsCode': smsCode,
      'token': token,
    };
  }
}
