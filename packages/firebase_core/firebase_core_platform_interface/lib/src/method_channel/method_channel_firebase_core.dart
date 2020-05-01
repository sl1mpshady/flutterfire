// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

class MethodChannelFirebaseCore extends FirebaseCorePlatform {
  static Map<String, MethodChannelFirebaseApp> _appInstances = {};
  static bool _isCoreInitialized = false;

  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  MethodChannel get channel => _channel;

  Future<void> _initializeCore() async {
    List<Map> apps = await _channel.invokeListMethod<Map>(
      'FirebaseCore#initializeCore',
    );

    apps.forEach(_initializeFirebaseAppFromMap);
    _isCoreInitialized = true;
  }

  void _initializeFirebaseAppFromMap(Map<dynamic, dynamic> map) {
    MethodChannelFirebaseApp methodChannelFirebaseApp =
        MethodChannelFirebaseApp(
            map['name'], FirebaseOptions.fromMap(map['options']));

    MethodChannelFirebaseCore._appInstances[methodChannelFirebaseApp.name] =
        methodChannelFirebaseApp;

    FirebasePluginPlatform
            ._constantsForPluginApps[methodChannelFirebaseApp.name] =
        map['pluginConstants'];
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return _appInstances.values.toList(growable: false);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String name, FirebaseOptions options}) async {
    if (name == defaultFirebaseAppName) {
      // TODO
      throw ("Default app cant be inited here");
    }

    if (!_isCoreInitialized) {
      await _initializeCore();
    }

    if (name == null) {
      // TODO what if no default app?
      // TODO warn user about incorrect setup (missing credentials)
      return _appInstances[defaultFirebaseAppName];
    }

    if (options == null) {
      // TODO
      throw ("Options cannot be null when a name is provided.");
    }

    // Check whether the app has already been initialized
    if (_appInstances.containsKey(name)) {
      return _appInstances[name];
    }

    _initializeFirebaseAppFromMap(await _channel.invokeMapMethod(
      'FirebaseCore#initializeApp',
      <String, dynamic>{'name': name, 'options': options.asMap},
    ));

    return _appInstances[name];
  }

  @override
  FirebaseAppPlatform app(String name) {
    if (_appInstances.containsKey(name)) {
      return _appInstances[name];
    }

    return _appInstances[defaultFirebaseAppName];
  }
}
