// Copyright 2020 The Chromium Authors. All rights reserved.
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
abstract class FirebaseCorePlatform extends PlatformInterface {
  FirebaseCorePlatform() : super(token: _token);

  static final Object _token = Object();

  /// The default instance of [FirebaseCorePlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own class
  /// that extends [FirebaseCorePlatform] when they register themselves.
  ///
  /// Defaults to [MethodChannelFirebaseCore].
  static FirebaseCorePlatform get instance => _instance;

  static FirebaseCorePlatform _instance = MethodChannelFirebaseCore();

  static set instance(FirebaseCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns all initialized [FirebaseApp] instances.
  List<FirebaseAppPlatform> get apps {
    throw UnimplementedError('apps has not been implemented.');
  }

  /// Initializes a new [FirebaseApp] with the given [name] and [FirebaseOptions].
  Future<FirebaseAppPlatform> initializeApp(
      {String name, FirebaseOptions options}) {
    throw UnimplementedError('initializeApp() has not been implemented.');
  }

  /// Returns a Firebase app with the given [name].
  ///
  /// If there is no such app, returns null.
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    throw UnimplementedError('app() has not been implemented.');
  }
}
