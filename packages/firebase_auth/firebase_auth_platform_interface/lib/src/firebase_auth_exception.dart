// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    show FirebaseException;
import 'package:meta/meta.dart';
import 'auth_credential.dart';
import 'multi_factor_resolver.dart';

/// Generic exception related to Firebase Authentication.
/// Check the error code and message for more details.
class FirebaseAuthException extends FirebaseException implements Exception {
  FirebaseAuthException({
    @required this.message,
    this.code,
    this.email,
    this.credential,
    this.resolver,
  }) : super(plugin: "firebase_auth", message: message, code: code);

  /// Unique error code
  final String code;

  /// Complete error message.
  final String message;

  /// The email of the user's account used for sign-in/linking.
  final String email;

  /// The [AuthCredential] that can be used to resolve the error.
  final AuthCredential credential;

  final MultiFactorResolver resolver;
}
