// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:e2e/e2e.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  FirebaseCore core;
  String testAppName = 'TestApp';
  const FirebaseOptions testAppOptions = FirebaseOptions(
    appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    projectId: 'react-native-firebase-testing',
    messagingSenderId: '448618578101',
  );

  setUpAll(() async {
    core = FirebaseCore.instance;
    await core.initializeApp(name: testAppName, options: testAppOptions);
  });

  testWidgets('FirebaseCore.apps', (WidgetTester tester) async {
    List<FirebaseApp> apps = core.apps;
    expect(apps.length, 1);
    expect(apps[0].name, testAppName);
    expect(apps[0].options, testAppOptions);
  });

  testWidgets('FirebaseCore.app()', (WidgetTester tester) async {
    FirebaseApp app = core.app(testAppName);
    expect(app.name, testAppName);
    expect(app.options, testAppOptions);
  });

  testWidgets('FirebaseCore.app() Exception', (WidgetTester tester) async {
    try {
      await core.app('NoApp');
    } on FirebaseException catch (e) {
      expect(e, noAppExists('NoApp'));
      return;
    }
  });

  testWidgets('FirebaseApp.delete()', (WidgetTester tester) async {
    await core.initializeApp(name: 'SecondaryApp', options: testAppOptions);
    expect(core.apps.length, 2);
    FirebaseApp app = core.app('SecondaryApp');
    await app.delete();
    expect(core.apps.length, 1);
  });

  testWidgets('FirebaseApp.setAutomaticDataCollectionEnabled()',
      (WidgetTester tester) async {
    FirebaseApp app = core.app(testAppName);
    bool enabled = app.isAutomaticDataCollectionEnabled;
    await app.setAutomaticDataCollectionEnabled(!enabled);
    expect(app.isAutomaticDataCollectionEnabled, !enabled);
  });

  testWidgets('FirebaseApp.setAutomaticResourceManagementEnabled()',
      (WidgetTester tester) async {
    FirebaseApp app = core.app(testAppName);
    await app.setAutomaticResourceManagementEnabled(true);
  });
}
