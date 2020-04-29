// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// The implementation of `firebase_core` for web.
class FirebaseCoreWeb implements FirebaseCorePlatform {
  /// TODO
  static List<FirebaseAppPlatform> get apps {
    final List<firebase.App> jsApps = firebase.apps;
    return jsApps.map<FirebaseAppPlatform>(_createFromJsApp).toList();
  }

  /// TODO
  static FirebaseAppPlatform app(String name) {
    firebase.App app = firebase.app(name);
    if (app == null) return null;
    // TODO is firebase error?
    return _createFromJsApp(app);
  }

  /// TODO
  static Future<FirebaseAppPlatform> initializeApp({ String name, FirebaseOptions options }) async {
    firebase.App app = firebase.initializeApp(
      name: name,
      apiKey: options.apiKey,
      databaseURL: options.databaseURL,
      projectId: options.projectID,
      storageBucket: options.storageBucket,
      messagingSenderId: options.gcmSenderID,
      measurementId: options.trackingID,
      appId: options.googleAppID,
    );
    return _createFromJsApp(app);
  }
}