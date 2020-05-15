// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseApp', () {
    MockFirebaseCore mock;

    const FirebaseOptions testOptions = FirebaseOptions(
        apiKey: 'apiKey',
        appId: 'appId',
        messagingSenderId: 'messagingSenderId',
        projectId: 'projectId');

    String testAppName = 'testApp';

    setUp(() async {
      mock = MockFirebaseCore();
      FirebaseCorePlatform.instance = mock;

      final FirebaseAppPlatform platformApp =
          FirebaseAppPlatform(testAppName, testOptions);

      when(mock.apps).thenReturn([platformApp]);
      when(mock.app(testAppName)).thenReturn(platformApp);
      when(mock.initializeApp(name: testAppName, options: testOptions))
          .thenAnswer((_) {
        return Future.value(platformApp);
      });
    });

    test('.apps', () {
      List<FirebaseApp> apps = FirebaseCore.instance.apps;
      verify(mock.apps);
      expect(apps[0], FirebaseCore.instance.app(testAppName));
    });

    test('.app()', () {
      FirebaseApp app = FirebaseCore.instance.app(testAppName);
      verify(mock.app(testAppName));

      expect(app.name, testAppName);
      expect(app.options, testOptions);
    });

    test('.initializeApp()', () async {
      FirebaseApp initializedApp = await FirebaseCore.instance
          .initializeApp(name: testAppName, options: testOptions);
      FirebaseApp app = FirebaseCore.instance.app(testAppName);

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(name: testAppName, options: testOptions),
        mock.app(testAppName),
      ]);
    });

//
//
//
//
//
//
//    test('should initialize dynamic apps', () async {
//      final FirebaseApp reconfiguredApp =
//          await FirebaseCore.instance.initializeApp(
//        name: 'testApp',
//        options: testOptions,
//      );
//
//
//      expect(reconfiguredApp, equals(testApp));
//      final FirebaseApp newApp = await FirebaseApp.configure(
//        name: 'newApp',
//        options: testOptions,
//      );
//      expect(newApp.name, equals('newApp'));
//      // It's ugly to specify mockito verification types
//      // ignore: always_specify_types
//      verifyInOrder([
//        mock.app('testApp'),
//        mock.app('newApp'),
//      ]);
//    });
//
//    test('should provide app instance by name', () async {
//      final FirebaseApp existingApp =
//          await FirebaseCore.instance.app('testApp');
//      expect(existingApp.name, equals('testApp'));
//      expect((await existingApp.options), equals(testOptions));
//      final FirebaseApp missingApp =
//          await FirebaseCore.instance.app('missingApp');
//      expect(missingApp, isNull);
//      // It's ugly to specify mockito verification types
//      // ignore: always_specify_types
//      verifyInOrder([
//        mock.app('testApp'),
//        mock.app('missingApp'),
//      ]);
//    });
//
//    test('should provide an array of apps', () async {
//      final List<FirebaseApp> allApps = await FirebaseCore.instance.apps;
//      expect(allApps, equals(<FirebaseAppPlatform>[testApp]));
//      verify(mock.apps);
//    });
//
//    test('should allow apps to dynamically toggle automatic data collection',
//        () async {
//      final FirebaseApp existingApp =
//          await FirebaseCore.instance.app('testApp');
//      expect(existingApp.isAutomaticDataCollectionEnabled, equals(true));
//      await existingApp.setAutomaticDataCollectionEnabled(false);
//      expect(existingApp.isAutomaticDataCollectionEnabled, equals(false));
//    });
//
//    test('should allow apps to be deleted', () async {
//      final FirebaseApp toBeDeletedApp = await FirebaseCore.instance
//          .initializeApp(name: 'toBeDeletedApp', options: testOptions);
//      expect(toBeDeletedApp.name, equals('testApp'));
//
//      await toBeDeletedApp.delete();
//      expect(() {
//        toBeDeletedApp.delete();
//      }, throwsA(equals('Firebase App named toBeDeletedApp already deleted')));
//
//      expect(() {
//        FirebaseCore.instance.app('toBeDeletedApp');
//      },
//          throwsA(equals(
//              'No Firebase App toBeDeletedApp has been created - call FirebaseCore.instance.initializeApp()')));
//    });
//
//    test('should prevent the default app from being deleted', () async {
//      final FirebaseApp defaultApp = await FirebaseCore.instance.app();
//      expect(defaultApp, isNotNull);
//
//      expect(() {
//        defaultApp.delete();
//      },
//          throwsA(
//              equals('The default Firebase app instance cannot be deleted.')));
//    });
  });
}

class MockFirebaseCore extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseCorePlatform {}
