// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_assertion.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_info.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_session.dart';

/// This is the interface that defines the multi-factor related properties and
/// operations pertaining to a [PlatformUser].
class MultiFactorUser {
  const MultiFactorUser({this.enrolledFactors});

  /// Returns a list of the user's enrolled second factors.
  final List<MultiFactorInfo> enrolledFactors;

  /// Enrolls a second factor as identified by the [MultiFactorAssertion] for the
  /// current user.
  Future<void> enroll(MultiFactorAssertion assertion, {String displayName}) {
    // todo
  }

  /// Returns the session identifier for a second factor enrollment operation.
  Future<MultiFactorSession> getSession() {
    // todo
  }

  /// Unenrolls the specified second factor.
  Future<void> unenroll(dynamic option) {
    // option: MultiFactorInfo or String
    // todo
  }
}
