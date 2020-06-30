// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class MultiFactorUserPlatform extends PlatformInterface {
  MultiFactorUserPlatform(FirebaseAuthPlatform auth, {this.enrolledFactors})
      : assert(enrolledFactors != null),
        super(token: _token);

  static final Object _token = Object();

  static verifyExtends(MultiFactorUserPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  final List<MultiFactorInfo> enrolledFactors;

  Future<void> enroll(MultiFactorAssertion multiFactorAssertion,
      [String displayName]) {
    throw UnimplementedError("enroll() is not implemented");
  }

  Future<void> unenroll(MultiFactorInfo multiFactorInfo) {
    throw UnimplementedError("unenroll() is not implemented");
  }
}
