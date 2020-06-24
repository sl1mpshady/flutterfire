// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

enum ActionCodeInfoOperation {
  emailSignIn,
  passwordReset,
  recoverEmail,
  revertSecondFactorAddition,
  verifyAndChangeEmail,
  verifyEmail,
  error,
}

class ActionCodeInfo {
  ActionCodeInfo({
    this.operation,
    Map<String, dynamic> data,
  }) : _data = data;

  Map<String, dynamic> _data;

  final ActionCodeInfoOperation operation;

  Map<String, dynamic> get data {
    return <String, dynamic>{
      'email': _data['email'],
      'fromEmail': _data['fromEmail'],
      'previousEmail': _data['previousEmail'],
      'multiFactorInfo': _data['multiFactorInfo'] == null
          ? null
          : MultiFactorInfo(
              displayName: _data['multiFactorInfo']['displayName'],
              enrollmentTime: _data['multiFactorInfo']['enrollmentTime'],
              factorId: _data['multiFactorInfo']['factorId'],
              uid: _data['multiFactorInfo']['uid'],
            ),
    };
  }
}
