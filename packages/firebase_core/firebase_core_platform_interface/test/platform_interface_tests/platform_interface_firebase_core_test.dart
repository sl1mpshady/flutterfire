// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseCorePlatform', () {
    // should allow read of default app from native
    test('$MethodChannelFirebaseCore is the default instance', () {
      expect(FirebaseCorePlatform.instance, isA<MethodChannelFirebaseCore>());
    });

    test('Can be extended', () {
      FirebaseCorePlatform.instance = ExtendsFirebaseCorePlatform();
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        FirebaseCorePlatform.instance = ImplementsFirebaseCorePlatform();
      }, throwsNoSuchMethodError);
    });

    test('Can be mocked with `implements`', () {
      final FirebaseCoreMockPlatform mock = FirebaseCoreMockPlatform();
      FirebaseCorePlatform.instance = mock;
    });
  });
}

class ImplementsFirebaseCorePlatform implements FirebaseCorePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp(
          {String name, FirebaseOptions options}) =>
      null;

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return null;
  }

  @override
  List<FirebaseAppPlatform> get apps => null;
}

class ExtendsFirebaseCorePlatform extends FirebaseCorePlatform {}

class FirebaseCoreMockPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseCorePlatform {}
