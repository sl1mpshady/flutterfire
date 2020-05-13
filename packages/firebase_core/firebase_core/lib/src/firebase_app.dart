// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

/// Represents a single Firebase app instance.
class FirebaseApp implements FirebaseAppPlatform {
  @deprecated
  FirebaseApp({@required String name}) {
    assert(name != null);
    _delegate = FirebaseAppPlatform(name, FirebaseOptions.fromMap({}));
  }

  /// TODO
  FirebaseAppPlatform _delegate;

  /// TODO
  FirebaseApp._(this._delegate) {
    FirebaseAppPlatform.verifyExtends(_delegate);
  }

  /// Deletes this app and frees up system resources.
  ///
  /// Once deleted, any plugin functionality using this app instance will throw
  /// an error.
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

  /// Returns the name of this app.
  @override
  String get name => _delegate.name;

  /// Returns the [FirebaseOptions] this app was created with.
  @override
  FirebaseOptions get options => _delegate.options;

  /// Returns whether automatic data collection is enabled or disabled for this
  /// app.
  @override
  bool get isAutomaticDataCollectionEnabled =>
      _delegate.isAutomaticDataCollectionEnabled;

  /// Sets whether automatic data collection is enabled or disabled for this
  /// app.
  ///
  /// To check whether it is currently enabled or not, call [isAutomaticDataCollectionEnabled].
  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    return _delegate.setAutomaticDataCollectionEnabled(enabled);
  }

  /// Sets whether automatic resource management is enabled or disabled for this
  /// app.
  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return _delegate.setAutomaticResourceManagementEnabled(enabled);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseAppPlatform) return false;
    return other.name == name && other.options == options;
  }

  @override
  int get hashCode => hash2(name, options);

  @override
  String toString() => '$FirebaseApp($name)';
}
