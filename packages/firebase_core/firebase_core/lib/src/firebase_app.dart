// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

class FirebaseApp implements FirebaseAppPlatform {
  @deprecated
  FirebaseApp({@required String name}) {
    assert(name != null);
    _delegate = FirebaseAppPlatform(name, FirebaseOptions.fromMap({}));
  }

  FirebaseAppPlatform _delegate;

  FirebaseApp._(this._delegate) {
    FirebaseAppPlatform.verifyExtends(_delegate);
  }

  Future<void> delete() async {
    await _delegate.delete();
  }

  @Deprecated("Deprecated in favor of FirebaseCore.instance.app()")
  static FirebaseApp appNamed(String name) {
    return FirebaseCore.instance.app(name);
  }

  @Deprecated("Deprecated in favor of FirebaseCore.instance.apps")
  static Future<List<FirebaseApp>> allApps() async {
    return FirebaseCore.instance.apps;
  }

  @Deprecated("Deprecated in favor of FirebaseCore.instance.initializeApp()")
  static Future<FirebaseApp> configure({
    @required String name,
    @required FirebaseOptions options,
  }) {
    return FirebaseCore.instance.initializeApp(name: name, options: options);
  }

  @Deprecated("Deprecated in favor of FirebaseCore.instance.app()")
  static FirebaseApp get instance {
    return FirebaseCore.instance.app();
  }

  @Deprecated("Deprecated in favor of defaultFirebaseAppName")
  static String get defaultAppName {
    return defaultFirebaseAppName;
  }

  @override
  String get name => _delegate.name;

  @override
  FirebaseOptions get options => _delegate.options;

  @override
  bool get isAutomaticDataCollectionEnabled => _delegate.isAutomaticDataCollectionEnabled;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    return _delegate.setAutomaticDataCollectionEnabled(enabled);
  }

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return _delegate.setAutomaticResourceManagementEnabled(enabled);
  }
}
