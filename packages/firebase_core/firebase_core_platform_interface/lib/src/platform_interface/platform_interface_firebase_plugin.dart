// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// The interface that other FlutterFire plugins must extend.
///
/// This class provides access to common plugin properties and constants which
/// are available once the user has initialized FlutterFire.
abstract class FirebasePluginPlatform extends PlatformInterface {
  // ignore: public_member_api_docs
  FirebasePluginPlatform(this._app, this._methodChannelName)
      : super(token: _token);

  /// The global data store for all constants, for each plugin and [FirebaseAppPlatform] instance.
  ///
  /// When Firebase is initialized by the user with [FirebaseCorePlatform.initializeApp],
  /// any constant values which are required before the plugins can be consumed are registered
  /// here. For example, calling [FirebaseAppPlatform.isAutomaticDataCollectionEnabled]
  /// requires that the value is synchronously available for use after initialization.
  static Map<dynamic, dynamic> _constantsForPluginApps = {};

  final FirebaseAppPlatform _app;

  final String _methodChannelName;

  static final Object _token = Object();

  // ignore: public_member_api_docs
  static verifyExtends(FirebasePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  /// Returns the current [FirebaseAppPlatform] instance for this plugin.
  FirebaseAppPlatform get app => _app;

  /// Returns any plugin constants this plugin app instance has initialized.
  Map<dynamic, dynamic> get pluginConstants {
    if (_constantsForPluginApps[_app.name] != null &&
        _constantsForPluginApps[_app.name][_methodChannelName] != null) {
      return _constantsForPluginApps[_app.name][_methodChannelName];
    }

    return {};
  }
}
