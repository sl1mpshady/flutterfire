// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_core_web;

import 'dart:async';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

part 'src/firebase_core_web.dart';
part 'src/firebase_app_web.dart';

FirebaseAppPlatform _createFromJsApp(firebase.App jsApp) {
  return FirebaseAppWeb._(jsApp.name, _createFromJsOptions(jsApp.options));
}

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
