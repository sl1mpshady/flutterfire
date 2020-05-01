// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

class FirebaseCore implements FirebaseCorePlatform {
  FirebaseCorePlatform _delegate = FirebaseCorePlatform.instance;

  static FirebaseCore get instance => FirebaseCore();

  List<FirebaseApp> get apps {
    return _delegate.apps
        .map((app) => FirebaseApp._(app))
        .toList(growable: false);
  }

  Future<FirebaseApp> initializeApp(
      {String name, FirebaseOptions options}) async {
    FirebaseAppPlatform app = await _delegate.initializeApp();
    return FirebaseApp._(app);
  }

  FirebaseApp app([String name = defaultFirebaseAppName]) {
    FirebaseAppPlatform app = _delegate.app(name);
    return app == null ? null : FirebaseApp._(app);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseCore) return false;
    return other.hashCode == hashCode;
  }

  @override
  int get hashCode => this.toString().hashCode;

  @override
  String toString() => '$FirebaseCore';
}
