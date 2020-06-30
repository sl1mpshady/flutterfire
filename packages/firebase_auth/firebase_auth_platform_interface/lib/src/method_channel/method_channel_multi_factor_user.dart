// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'method_channel_firebase_auth.dart';
import 'utils/exception.dart';

class MethodChannelMultiFactorUser extends MultiFactorUserPlatform {
  MethodChannelMultiFactorUser(FirebaseAuthPlatform auth,
      {List<MultiFactorInfo> enrolledFactors})
      : _auth = auth,
        super(auth, enrolledFactors: enrolledFactors);

  FirebaseAuthPlatform _auth;

  @override
  Future<void> enroll(MultiFactorAssertion multiFactorAssertion,
      [String displayName]) {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('MultiFactor#enroll', <String, dynamic>{
      'appName': _auth.app.name,
      'displayName': displayName,
      'multiFactorAssertion': multiFactorAssertion.asMap(),
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> unenroll(MultiFactorInfo multiFactorInfo) {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('MultiFactor#unenroll', <String, dynamic>{
      'appName': _auth.app.name,
      'factorUid': multiFactorInfo.uid,
    }).catchError(catchPlatformException);
  }
}
