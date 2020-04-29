// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platoform_interface;

/// A data class storing the name and options of a Firebase app.
///
/// This is created as a result of calling
/// [`firebase.initializeApp`](https://firebase.google.com/docs/reference/js/firebase#initialize-app)
/// in the various platform implementations.
///
/// This class is different from `FirebaseApp` declared in
/// `package:firebase_core`: `FirebaseApp` is initialized synchronously, and
/// the options for the app are obtained via a call that returns
/// `Future<FirebaseOptions>`. This class is the platform representation of a
/// Firebase app.
abstract class FirebaseAppPlatform extends PlatformInterface {
  FirebaseAppPlatform(this.name, this.options) : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [FirebaseAppPlatform].
  ///
  /// This is used by the app-facing [FirebaseApp] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(FirebaseAppPlatform instance) {
    if (instance is! FirebaseAppPlatform) {
      PlatformInterface.verifyToken(instance, _token);
    }
  }

  /// The name of this Firebase app.
  final String name;

  /// The options that this app was configured with.
  final FirebaseOptions options;

  /// Deletes the current FirebaseApp instance.
  Future<void> delete() async {
    throw UnimplementedError('delete() has not been implemented.');
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
  String toString() => '$FirebaseAppPlatform($name)';
}
