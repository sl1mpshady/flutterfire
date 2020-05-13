// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// [FirebaseCorePlatform] implementation that delegates to a [MethodChannel].
class MethodChannelFirebaseCore extends FirebaseCorePlatform {
  /// Tracks local [MethodChannelFirebaseApp] instances.
  @visibleForTesting
  static Map<String, MethodChannelFirebaseApp> appInstances = {};

  /// Keeps track of whether users have initialized core.
  @visibleForTesting
  static bool isCoreInitialized = false;

  /// The [MethodChannel] to which calls will be delegated.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  /// Calls the native FirebaseCore#initializeCore method.
  ///
  /// Before any plugins can be consumed, any platforms using the [MethodChannel]
  /// can use initializeCore method to return any initialization data, such as
  /// any Firebase apps created natively and any constants which are required
  /// for a plugin to function correctly before usage.
  Future<void> _initializeCore() async {
    List<Map> apps = await channel.invokeListMethod<Map>(
      'FirebaseCore#initializeCore',
    );

    apps.forEach(_initializeFirebaseAppFromMap);
    isCoreInitialized = true;
  }

  /// Creates and attaches a new [MethodChannelFirebaseApp] to the [MethodChannelFirebaseCore]
  /// and adds any constants to the [FirebasePluginPlatform] class.
  void _initializeFirebaseAppFromMap(Map<dynamic, dynamic> map) {
    MethodChannelFirebaseApp methodChannelFirebaseApp =
        MethodChannelFirebaseApp(
      map['name'],
      FirebaseOptions.fromMap(map['options']),
      isAutomaticDataCollectionEnabled: map['isAutomaticDataCollectionEnabled'],
    );

    MethodChannelFirebaseCore.appInstances[methodChannelFirebaseApp.name] =
        methodChannelFirebaseApp;

    FirebasePluginPlatform
            ._constantsForPluginApps[methodChannelFirebaseApp.name] =
        map['pluginConstants'];
  }

  /// Returns the created [FirebaseAppPlatform] instances.
  @override
  List<FirebaseAppPlatform> get apps {
    return appInstances.values.toList(growable: false);
  }

  /// Initializes a Firebase app instance.
  ///
  /// Internally initializes core if it is not yet ready.
  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String name, FirebaseOptions options}) async {
    if (name == defaultFirebaseAppName) {
      throw noDefaultAppInitialization();
    }

    if (!isCoreInitialized) {
      await _initializeCore();
    }

    if (name == null) {
      MethodChannelFirebaseApp defaultApp =
          appInstances[defaultFirebaseAppName];

      if (defaultApp == null) {
        throw coreNotInitialized();
      }

      return appInstances[defaultFirebaseAppName];
    }

    assert(options != null,
        "FirebaseOptions cannot be null when creating a secondary Firebase app.");

    // Check whether the app has already been initialized
    if (appInstances.containsKey(name)) {
      throw duplicateApp(name);
    }

    _initializeFirebaseAppFromMap(await channel.invokeMapMethod(
      'FirebaseCore#initializeApp',
      <String, dynamic>{'appName': name, 'options': options.asMap},
    ));

    return appInstances[name];
  }

  /// Returns a [FirebaseAppPlatform] by [name].
  ///
  /// Returns the default Firebase app no [name] is provided and throws a
  /// [FirebaseException] if no app with the [name] has been created.
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (appInstances.containsKey(name)) {
      return appInstances[name];
    }

    throw noAppExists(name);
  }
}
