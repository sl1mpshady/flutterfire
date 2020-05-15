// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:firebase_core/firebase_core.dart';
@TestOn('browser')

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('no default app', () {
    setUp(() async {
      FirebaseCorePlatform.instance = FirebaseCoreWeb();
    });

    test('should throw exception if no default app is available', () async {
      try {
        await FirebaseCore.instance.initializeApp();
      } on FirebaseException catch (e) {
        expect(e, coreNotInitialized());
        return;
      }

      fail("FirebaseException not thrown");
    });
  });

  group('.initializeApp()', () {
    setUp(() async {
      FirebaseCorePlatform.instance = FirebaseCoreWeb();
    });

    test('should throw if trying to initialize default app', () async {
      try {
        await FirebaseCore.instance
            .initializeApp(name: defaultFirebaseAppName);
      } on FirebaseException catch (e) {
        expect(e, noDefaultAppInitialization());
        return;
      }

      fail("FirebaseException not thrown");
    });

    group('secondary apps', () {
      test('should throw if no options are provided with a named app',
          () async {
        try {
          await FirebaseCore.instance.initializeApp(name: 'foo');
        } catch (e) {
          assert(
              e.toString().contains(
                  "FirebaseOptions cannot be null when creating a secondary Firebase app."),
              true);
        }
      });
    });
  });

  // TODO(ehesp): needs reenabling once firebase.js can be initialized within the test
  group('.app()', () {
    setUp(() async {
      FirebaseCorePlatform.instance = FirebaseCoreWeb();
    });

    test('should throw if no named app was found', () async {
      String name = 'foo';
      try {
        FirebaseCore.instance.app(name);
      } on FirebaseException catch (e) {
        expect(e, noAppExists(name));
        return;
      }

      fail("FirebaseException not thrown");
    });
  });
}
