// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:meta/meta.dart';

const _kProviderId = 'phone';

/// Phone number auth provider.
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

  static AuthCredential credentialFromHandle(int handle) {
    assert(handle != null);
    return PhoneAuthCredential._credentialFromHandle(handle);
  }

  @Deprecated('Deprecated in favor of `PhoneAuthProvider.credential()`')
  static AuthCredential getCredential({
    @required String verificationId,
    @required String smsCode,
  }) {
    return PhoneAuthProvider.credential(verificationId, smsCode);
  }
}

class PhoneAuthCredential extends AuthCredential {
  PhoneAuthCredential._({this.verificationId, this.smsCode, this.handle})
      : super(
          providerId: _kProviderId,
          signInMethod: _kProviderId,
        );

  factory PhoneAuthCredential._credential(
      String verificationId, String smsCode) {
    return PhoneAuthCredential._(
        verificationId: verificationId, smsCode: smsCode);
  }

  factory PhoneAuthCredential._credentialFromHandle(int handle) {
    return PhoneAuthCredential._(handle: handle);
  }

  final String verificationId;
  final String smsCode;
  final int handle;

  @override
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'verificationId': verificationId,
      'smsCode': smsCode,
      'handle': handle,
    };
  }
}
