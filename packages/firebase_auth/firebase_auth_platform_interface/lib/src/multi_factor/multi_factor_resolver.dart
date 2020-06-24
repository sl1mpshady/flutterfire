// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_assertion.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_info.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_session.dart';
import 'package:firebase_auth_platform_interface/src/result/platform_auth_result.dart';

/// The class used to facilitate recovery from [MultiFactorException] when
/// a user needs to provide a second factor to sign in.
class MultiFactorResolver {
  /// The auth instance used to sign in with the first factor.
  FirebaseAuthPlatform auth;

  /// The list of hints for the second factors needed to complete the sign-in
  /// for the current session.
  List<MultiFactorInfo> hints;

  /// The session identifier for the current sign-in flow, which can be used
  /// to complete the second factor sign-in.
  MultiFactorSession session;

  /// A helper function to help users complete sign in with a second factor
  /// using a [MultiFactorAssertion] confirming the user successfully completed
  /// the second factor challenge.
  Future<PlatformAuthResult> resolveSignIn(MultiFactorAssertion assertion) {
    // todo implement
  }
}
