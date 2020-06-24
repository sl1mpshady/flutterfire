// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/result/platform_auth_result.dart';

/// A result from a phone number sign-in, link, or reauthenticate call.
class ConfirmationResult {
  const ConfirmationResult(this.verificationId);

  /// The phone number authentication operation's verification ID.
  final String verificationId;

  // todo: implement
  /// Finishes a phone number sign-in, link, or reauthentication, given the code that
  /// was sent to the user's mobile device.
  Future<PlatformAuthResult> confirm(String verificationCode) {}
}
