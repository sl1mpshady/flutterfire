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

  /// Initializes a new [FirebaseAppPlatform] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// The default app instance cannot be initialized here and should be created
  /// using the platform Firebase integration.
  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String name, FirebaseOptions options}) async {
    firebase.App app;

    try {
      app = firebase.initializeApp(
        name: name,
        apiKey: options.apiKey,
        authDomain: options.authDomain,
        databaseURL: options.databaseURL,
        projectId: options.projectId,
        storageBucket: options.storageBucket,
        messagingSenderId: options.messagingSenderId,
        appId: options.appId,
        measurementId: options.measurementId,
      );
    } catch (e) {
      // TODO catch & log error
    }

    return _createFromJsApp(app);
  }

  /// Returns a [FirebaseAppPlatform] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
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
