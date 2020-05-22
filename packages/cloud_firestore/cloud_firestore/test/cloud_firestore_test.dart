// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Firestore firestore = Firestore.instance;

  group('$Firestore', () {
    MockFirestore mock;

    setUp(() async {
      mock = MockFirestore();
      FirestorePlatform.instance = mock;
    });

    group('document()', () {
      test('it rejects invalid document paths', () {
        expect(firestore.document(null), throwsAssertionError);
      });
    });

    // test('.apps', () {
    //   List<FirebaseApp> apps = FirebaseCore.instance.apps;
    //   verify(mock.apps);
    //   expect(apps[0], FirebaseCore.instance.app(testAppName));
    // });
  });
}

class MockFirestore extends Mock
    with MockPlatformInterfaceMixin
    implements FirestorePlatform {}
