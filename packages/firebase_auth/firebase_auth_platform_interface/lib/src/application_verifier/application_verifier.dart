// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// A verifier for domain verification and abuse prevention.
/// Currently, the only implementation is [RecaptchaVerifier].
class ApplicationVerifier {
  const ApplicationVerifier(this.type);

  /// Identifies the type of the application verifier
  /// (for example, "recaptcha")
  final String type;

  /// Executes the verification process.
  /// Returns a [Future] for a token that can be used to
  /// assert the validity of a request
  Future<String> verify() {
    throw UnimplementedError("verify() is not implemented");
  }
}
