// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@TestOn('browser')

import 'dart:js' as js;

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseCoreWeb', () {
    setUp(() async {
      firebaseMock = FirebaseMock(
          app: js.allowInterop(
                (String name) => FirebaseAppMock(
                name: name,
                options: FirebaseAppOptionsMock(
                    apiKey: 'abc',
                    appId: '123',
                    messagingSenderId: 'msg',
                    projectId: 'test'
                ),
            )
          ));

      FirebaseCorePlatform.instance = FirebaseCoreWeb();
    });

    test('setUp wires up mock objects properly', () async {
      firebase.App app = firebase.app('[DEFAULT]');
      expect(app.options.apiKey, equals('abc'));
      expect(app.options.appId, equals('123'));
      expect(app.options.messagingSenderId, equals('msg'));
      expect(app.options.projectId, equals('test'));
    });

    test('FirebaseApp.allApps() calls firebase.apps', () async {
      js.context['firebase']['apps'] = js.JsArray<dynamic>();
      final List<FirebaseApp> apps = await FirebaseApp.allApps();
      expect(apps, hasLength(0));
    });

    test('FirebaseApp.appNamed() calls firebase.app', () async {
      js.context['firebase']['app'] = js.allowInterop((String name) {
        return js.JsObject.jsify(<String, dynamic>{
          'name': name,
          'options': <String, String>{
            'apiKey': 'abc',
            'appId': '123',
            'messagingSenderId': 'msg',
            'projectId': 'test'
          },
        });
      });
      final FirebaseApp app = await FirebaseApp.appNamed('foo');
      expect(app.name, equals('foo'));

      final FirebaseOptions options = await app.options;
      expect(options.apiKey, equals('abc'));
      expect(options.appId, equals('123'));
      expect(options.messagingSenderId, equals('msg'));
      expect(options.projectId, equals('test'));
    });

    test('FirebaseApp.configure() calls firebase.initializeApp', () async {
      bool appConfigured = false;

      js.context['firebase']['app'] = js.allowInterop((String name) {
        if (appConfigured) {
          return js.JsObject.jsify(<String, dynamic>{
            'name': name,
            'options': <String, String>{
              'apiKey': 'abc',
              'appId': '123',
              'messagingSenderId': 'msg',
              'projectId': 'test'
            },
          });
        } else {
          return null;
        }
      });
      js.context['firebase']['initializeApp'] =
          js.allowInterop((js.JsObject options, String name) {
            appConfigured = true;
            return js.JsObject.jsify(<String, dynamic>{
              'name': name,
              'options': options,
            });
          });
      final FirebaseApp app = await FirebaseApp.configure(
        name: 'foo',
        options: const FirebaseOptions(
          apiKey: 'abc',
          appId: '123',
          messagingSenderId: 'msg',
          projectId: 'test',
        ),
      );
      expect(app.name, equals('foo'));

      final FirebaseOptions options = await app.options;
      expect(options.appId, equals('123'));
    });
  });
}
