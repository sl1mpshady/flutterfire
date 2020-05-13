// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// The entry point for accessing a Firebase app instance.
///
/// To get an instance, call the the `app` method on the [FirebaseCore]
/// instance, for example:
///
/// ```dart
/// FirebaseCore.instance.app('SecondaryApp`);
/// ```
class FirebaseAppWeb extends FirebaseAppPlatform {
  FirebaseAppWeb._(String name, FirebaseOptions options) : super(name, options);

  /// Deletes this app and frees up system resources.
  ///
  /// Once deleted, any plugin functionality using this app instance will throw
  /// an error.
  @override
  Future<void> delete() async {
    await firebase.app(name).delete();
  }
}
