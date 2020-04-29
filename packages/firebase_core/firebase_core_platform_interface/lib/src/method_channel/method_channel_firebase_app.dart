// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platoform_interface;

class MethodChannelFirebaseApp extends FirebaseAppPlatform {
  MethodChannelFirebaseApp(String name, FirebaseOptions options) : super(name, options);

  @override
  Future<FirebaseAppPlatform> delete({ String name, FirebaseOptions options }) {
    return MethodChannelFirebaseCore.channel.invokeMethod<void>(
      'FirebaseApp#deleteApp',
      <String, dynamic>{'name': name, 'options': options.asMap},
    );
  }
}
