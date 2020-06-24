// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:firebase_auth_platform_interface/src/user/platform_additional_user_info.dart';
import 'package:firebase_auth_platform_interface/src/user/platform_user.dart';
import 'package:flutter/foundation.dart';

// TODO: now the time to rename as UserCredential?
/// Represents `UserCredential` from Firebase.
///
/// See also: https://firebase.google.com/docs/reference/js/firebase.auth.html#usercredential
class PlatformAuthResult {
  // TODO: additionalUserInfo still required?
  const PlatformAuthResult({
    @required this.user,
    @required this.credential,
    @required this.additionalUserInfo,
    this.operationType,
  });

  final PlatformUser user;
  final PlatformAdditionalUserInfo additionalUserInfo;
  final AuthCredential credential;
  final String operationType;
}
