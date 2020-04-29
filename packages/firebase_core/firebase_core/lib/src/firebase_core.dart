// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

class FirebaseCore implements platform.FirebaseCorePlatform {
  static Map<String, FirebaseApp> _appInstances = {};

  static bool _coreInitialized = false;

  /// Returns a previously created FirebaseApp instance with the given name,
  /// or null if no such app exists.
  static FirebaseApp app({String name = '[DEFAULT]'}) {
    // TODO
//    final platform.PlatformFirebaseApp app =
//        await platform.FirebaseCorePlatform.instance.appNamed(name);
//    return app == null ? null : FirebaseApp(name: app.name);
    return null;
  }



  /// Initialize a Firebase app with the given [name] and [options].
  ///
  /// Configuring the default app is not currently supported. Plugins that
  /// can interact with the default app should configure it automatically at
  /// plugin registration time.
  ///
  /// Changing the options of a configured app is not supported.
  static Future<FirebaseApp> initializeApp({
    String name = '[DEFAULT]',
    platform.FirebaseOptions options,
  }) async {
    assert(name != null);
    if (options != null) {
      assert(name != defaultAppName);
      assert(options.googleAppID != null);
    }

    // TODO if core not inited, await core
    if (!_coreInitialized) {
    }


    final FirebaseApp existingApp = _appInstances[name];
    if (existingApp != null) {
      return existingApp;
    }

    // TODO call native initializeApp

    await platform.FirebaseCorePlatform.instance.configure(name, options);
    return FirebaseApp(name: name);
  }

  /// Returns a list of all extant FirebaseApp instances, or null if there are
  /// no FirebaseApp instances.
  static Future<List<FirebaseApp>> allApps() async {
    final List<platform.FirebaseAppPlatform> result =
    await platform.FirebaseCorePlatform.instance.allApps();
    return result
        ?.map<FirebaseApp>(
          (platform.FirebaseAppPlatform app) => FirebaseApp(name: app.name),
    )
        ?.toList();
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseApp) return false;
    return other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => '$FirebaseApp($name)';
}
