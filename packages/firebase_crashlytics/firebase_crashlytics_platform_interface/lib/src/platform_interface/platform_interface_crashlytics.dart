// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../method_channel/method_channel_crashlytics.dart';

abstract class FirebaseCrashlyticsPlatform extends PlatformInterface {
  @protected
  final FirebaseApp appInstance;

  /// Create an instance using [app]
  FirebaseCrashlyticsPlatform({this.appInstance}) : super(token: _token);

  static final Object _token = Object();

  /// Returns the [FirebaseApp] for the current instance.
  FirebaseApp get app {
    if (appInstance == null) {
      return Firebase.app();
    }

    return appInstance;
  }

  static FirebaseCrashlyticsPlatform _instance;

  /// The current default [FirebaseFirestorePlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseFirestore]
  /// if no other implementation was provided.
  static FirebaseCrashlyticsPlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirebaseCrashlytics(app: Firebase.app());
    }
    return _instance;
  }

  /// Sets the [FirebaseFirestorePlatform.instance]
  static set instance(FirebaseCrashlyticsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  
}
