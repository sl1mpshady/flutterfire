// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platoform_interface;

/// The interface that implementations of `firebase_core` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `firebase_core` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [FirebaseCorePlatform] methods.
abstract class FirebaseCorePlatform {

  /// Returns all initialized FirebaseApp instances.
  static List<FirebaseAppPlatform> get apps {
    throw UnimplementedError('apps has not been implemented.');
  }

  /// Initializes a new FirebaseApp with the given [name].
  static Future<FirebaseAppPlatform> initializeApp({ String name, FirebaseOptions options }) {
    throw UnimplementedError('initializeApp() has not been implemented.');
  }

  /// Returns a Firebase app with the given [name].
  ///
  /// If there is no such app, returns null.
  static FirebaseAppPlatform app(String name) {
    throw UnimplementedError('app() has not been implemented.');
  }
}