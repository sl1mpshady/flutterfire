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

  /// Returns all created [FirebaseAppPlatform] instances.
  @override
  List<FirebaseAppPlatform> get apps {
    return firebase.apps.map(_createFromJsApp).toList(growable: false);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String name, FirebaseOptions options}) async {
    firebase.App app;

    try {
      app = firebase.initializeApp(
        name: name,
        apiKey: options.apiKey,
        databaseURL: options.databaseURL,
        projectId: options.projectID,
        storageBucket: options.storageBucket,
        messagingSenderId: options.gcmSenderID,
        measurementId: options.trackingID,
        appId: options.googleAppID,
      );
    } catch (e) {
      // TODO...
    }

    return _createFromJsApp(app);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    firebase.App app;

    try {
      app = firebase.app(name);
    } catch (e) {
      if (_getJSErrorCode(e) == 'app/no-app') {
        throw noAppExists(name);
      }

      throw _catchJSError(e);
    }

    return _createFromJsApp(app);
  }
}
