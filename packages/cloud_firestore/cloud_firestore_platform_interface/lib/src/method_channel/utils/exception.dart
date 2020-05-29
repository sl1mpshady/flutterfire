// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Catches a [PlatformException] and converts it into a [FirebaseException] if
/// it was intentially caught on the native platform.
Future<void> catchPlatformException(Object exception) async {
  if (exception is! PlatformException) {
    throw exception;
  }

  PlatformException platformException = exception as PlatformException;

  if (platformException.code != 'cloud_firestore') {
    throw exception;
  }

  Map<String, String> details = platformException.details != null
      ? Map<String, String>.from(platformException.details)
      : null;

  String code = 'unknown';
  String message = platformException.message;

  if (details != null) {
    code = details['code'] ?? code;
    message = details['message'] ?? message;
  }

  throw FirebaseException(
      plugin: 'cloud_firestore', code: code, message: message);
}
