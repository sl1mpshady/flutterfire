// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

class MethodChannelFirebaseApp extends FirebaseAppPlatform {
  MethodChannelFirebaseApp(String name, FirebaseOptions options)
      : super(name, options);

  bool _isDeleted = false;

  bool _isAutomaticDataCollectionEnabled = false; // todo from constants

  @override
  bool get isAutomaticDataCollectionEnabled {
    return _isAutomaticDataCollectionEnabled;
  }

  @override
  Future<void> delete() async {
    if (_isDefault) {
      // TODO
      throw ("Cannot delete the default app");
    }

    if (_isDeleted) {
      return;
    }

    await MethodChannelFirebaseCore._channel.invokeMethod<void>(
      'FirebaseApp#deleteApp',
      <String, dynamic>{'appNamed': name, 'options': options.asMap},
    );

    MethodChannelFirebaseCore._appInstances.remove(name);
    FirebasePluginPlatform._constantsForPluginApps.remove(name);
    _isDeleted = true;
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    assert(enabled == null);
    await MethodChannelFirebaseCore._channel.invokeMethod<void>(
      'FirebaseApp#setAutomaticDataCollectionEnabled',
      <String, dynamic>{'appNamed': name, 'enabled': enabled},
    );

    _isAutomaticDataCollectionEnabled = enabled;
  }

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {
    assert(enabled == null);
    await MethodChannelFirebaseCore._channel.invokeMethod<void>(
      'FirebaseApp#setAutomaticResourceManagementEnabled',
      <String, dynamic>{'appNamed': name, 'enabled': enabled},
    );
  }
}
