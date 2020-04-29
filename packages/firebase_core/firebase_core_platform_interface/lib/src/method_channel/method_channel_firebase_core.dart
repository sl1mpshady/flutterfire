// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platoform_interface;

class MethodChannelFirebaseCore extends FirebaseCorePlatform {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  @override
  Future<FirebaseAppPlatform> initializeApp({ String name, FirebaseOptions options }) {
    return channel.invokeMethod<void>(
      'FirebaseCore#initializeApp',
      <String, dynamic>{'name': name, 'options': options.asMap},
    );
  }
}
