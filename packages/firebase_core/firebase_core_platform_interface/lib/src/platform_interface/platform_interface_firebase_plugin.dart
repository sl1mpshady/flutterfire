// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// The interface that implementations of `firebase_core` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `firebase_core` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [FirebaseCorePlatform] methods.
abstract class FirebasePluginPlatform extends PlatformInterface {

  static Map<dynamic, dynamic> _constantsForPluginApps = {};

  String _methodChannelName;

  FirebasePluginPlatform(this._app, this._methodChannelName) : super(token: _token);

  static final Object _token = Object();

  static verifyExtends(FirebasePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  FirebaseAppPlatform _app;

  // TODO docs: creates a readonly app instance
  FirebaseAppPlatform get app => _app;

  Map<dynamic, dynamic> get pluginConstants {
    return _constantsForPluginApps[_app.name][_methodChannelName];
  }
}
