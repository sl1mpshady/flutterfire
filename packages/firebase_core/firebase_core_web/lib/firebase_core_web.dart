// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_core_web;

import 'dart:async';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart' as js_util;

part 'src/firebase_app_web.dart';
part 'src/firebase_core_web.dart';

/// Returns a [FirebaseAppWeb] from a [firebase.App].
FirebaseAppPlatform _createFromJsApp(firebase.App jsApp) {
  return FirebaseAppWeb._(jsApp.name, _createFromJsOptions(jsApp.options));
}

/// Returns a [FirebaseOptions] from a [firebase.FirebaseOptions].
FirebaseOptions _createFromJsOptions(firebase.FirebaseOptions options) {
  return FirebaseOptions(
    apiKey: options.apiKey,
    trackingID: options.measurementId,
    gcmSenderID: options.messagingSenderId,
    projectID: options.projectId,
    googleAppID: options.appId,
    databaseURL: options.databaseURL,
    storageBucket: options.storageBucket,
  );
}

/// Returns a code from a JavaScript error.
///
/// When the Firebase JS SDK throws an error, it contains a code which can be
/// used to identify the specific type of error. This helper function is used
/// to keep error messages consistent across different platforms.
String _getJSErrorCode(dynamic e) {
  if (js_util.getProperty(e, 'name') == 'FirebaseError') {
    return js_util.getProperty(e, 'code') ?? '';
  }

  return '';
}

/// Returns a [FirebaseException] if the error is a Firebase Error.
///
/// To keep the error messages consistent across different platforms,
FirebaseException _catchJSError(dynamic e) {
  if (js_util.getProperty(e, 'name') == 'FirebaseError') {
    String rawCode = js_util.getProperty(e, 'code');
    String code = rawCode;
    String message = js_util.getProperty(e, 'message') ?? '';

    if (code.contains('/')) {
      List<String> chunks = code.split('/');
      code = chunks[chunks.length - 1];
    }

    return FirebaseException(
      plugin: 'core',
      code: code,
      message: message.replaceAll(' ($rawCode)', ''),
    );
  }

  throw e;
}
