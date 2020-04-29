// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

class FirebaseApp extends platform.FirebaseAppPlatform {
  FirebaseApp(this.name, this.options) : super(name, options);

  /// The name of this app.
  final String name;

  /// A copy of the options for this app. These are non-modifiable.
  ///
  /// This getter is asynchronous because apps can also be configured by native
  /// code.
  ///
  @override
  Future<platform.FirebaseOptions> get options async {
    final platform.FirebaseAppPlatform app =
        await platform.FirebaseCorePlatform.instance.appNamed(name);
    assert(app != null);
    return app.options;
  }

  /// Returns the default (first initialized) instance of the FirebaseApp.
  static final FirebaseApp instance = FirebaseApp(name: defaultAppName);

}
