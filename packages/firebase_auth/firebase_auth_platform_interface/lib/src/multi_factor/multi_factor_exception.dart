// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_exception.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_resolver.dart';

/// The exception thrown when the user needs to provide a second factor to
/// sign in successfully. The error code for this error is
/// auth/multi-factor-auth-required. This error provides a [MultiFactorResolver]
/// object, which can be used to get the second sign-in factor from a user.
abstract class MultiFactorException extends AuthException {
  // todo: constuct

  /// The multi-factor resolver to complete second factor sign-in.
  final MultiFactorResolver resolver;
}
