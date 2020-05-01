// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// The implementation of `firebase_core` for web.
class FirebaseCoreWeb extends FirebaseCorePlatform {
  /// Registers that [FirebaseCoreWeb] is the platform implementation.
  static void registerWith(Registrar registrar) {
    FirebaseCorePlatform.instance = FirebaseCoreWeb();
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return firebase.apps.map(_createFromJsApp).toList(growable: false);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({ String name, FirebaseOptions options }) async {
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

  @override
  FirebaseAppPlatform app(String name) {
    firebase.App app = firebase.app(name);
    if (app == null) return null;
    return _createFromJsApp(app);
  }
}

