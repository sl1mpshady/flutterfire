// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';

/// An [AuthCredential] for authenticating via phone.
class PhoneAuthCredential extends AuthCredential {
  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId = 'phone';

  // todo: below no longer needed?

//  const PhoneAuthCredential(
//      {@required this.verificationId, @required this.smsCode})
//      : _jsonObject = null,
//        super(_providerId);
//
//  /// On Android, when the SMS code is automatically detected, the credential
//  /// is returned serialized as JSON.
//  const PhoneAuthCredential._fromDetectedOnAndroid(
//      {@required String jsonObject})
//      : _jsonObject = jsonObject,
//        verificationId = null,
//        smsCode = null,
//        super(_providerId);
//
//  /// The verification ID returned from [FirebaseAuthPlatform.verifyPhoneNumber].
//  final String verificationId;
//
//  /// The verification code sent to the user's phone.
//  final String smsCode;
//
//  /// The credential serialized to JSON.
//  ///
//  /// See [PhoneAuthCredential._fromDetectedOnAndroid].
//  final String _jsonObject;
//
//  @override
//  Map<String, String> _asMap() {
//    final Map<String, String> result = <String, String>{};
//    if (verificationId != null) {
//      result['verificationId'] = verificationId;
//    }
//    if (smsCode != null) {
//      result['smsCode'] = smsCode;
//    }
//    if (_jsonObject != null) {
//      result['jsonObject'] = _jsonObject;
//    }
//    return result;
//  }
}
