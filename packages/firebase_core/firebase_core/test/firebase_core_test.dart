// Copyright 2019 The Chromium Authors. All rights reserved.
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
    const FirebaseOptions testOptions = FirebaseOptions(
      apiKey: 'testAPIKey',
      bundleID: 'testBundleID',
      clientID: 'testClientID',
      trackingID: 'testTrackingID',
      gcmSenderID: 'testGCMSenderID',
      projectID: 'testProjectID',
      androidClientID: 'testAndroidClientID',
      googleAppID: 'testGoogleAppID',
      databaseURL: 'testDatabaseURL',
      deepLinkURLScheme: 'testDeepLinkURLScheme',
      storageBucket: 'testStorageBucket',
    );
    final FirebaseAppPlatform testApp = FirebaseAppPlatform(
      'testApp',
      testOptions,
    );

    MockFirebaseCore mock;

    setUp(() async {
      mock = MockFirebaseCore();
      FirebaseCorePlatform.instance = mock;

      final FirebaseAppPlatform app = FirebaseAppPlatform(
        'testApp',
        const FirebaseOptions(
          apiKey: 'testAPIKey',
          bundleID: 'testBundleID',
          clientID: 'testClientID',
          trackingID: 'testTrackingID',
          gcmSenderID: 'testGCMSenderID',
          projectID: 'testProjectID',
          androidClientID: 'testAndroidClientID',
          googleAppID: 'testGoogleAppID',
          databaseURL: 'testDatabaseURL',
          deepLinkURLScheme: 'testDeepLinkURLScheme',
          storageBucket: 'testStorageBucket',
        ),
      );

      when(mock.app('testApp')).thenAnswer((_) {
        return app;
      });

      when(mock.apps).thenAnswer((_) => <FirebaseAppPlatform>[app]);
    });

    test('initializeApp', () async {
      final FirebaseApp reconfiguredApp = await FirebaseCore.instance.initializeApp(
        name: 'testApp',
        options: testOptions,
      );
      expect(reconfiguredApp, equals(testApp));
      final FirebaseApp newApp = await FirebaseApp.configure(
        name: 'newApp',
        options: testOptions,
      );
      expect(newApp.name, equals('newApp'));
      // It's ugly to specify mockito verification types
      // ignore: always_specify_types
      verifyInOrder([
        mock.app('testApp'),
        mock.app('newApp'),
      ]);
    });

    test('app', () async {
      final FirebaseApp existingApp = await FirebaseCore.instance.app('testApp');
      expect(existingApp.name, equals('testApp'));
      expect((await existingApp.options), equals(testOptions));
      final FirebaseApp missingApp = await FirebaseCore.instance.app('missingApp');
      expect(missingApp, isNull);
      // It's ugly to specify mockito verification types
      // ignore: always_specify_types
      verifyInOrder([
        mock.app('testApp'),
        mock.app('missingApp'),
      ]);
    });

    test('apps', () async {
      final List<FirebaseApp> allApps = await FirebaseCore.instance.apps;
      expect(allApps, equals(<FirebaseAppPlatform>[testApp]));
      verify(mock.apps);
    });
  });
}

class MockFirebaseCore extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseCorePlatform {}
