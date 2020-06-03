// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_query.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../utils/test_common.dart';

const _kQueryPath = "test/collection";

class TestQuery extends MethodChannelQuery {
  TestQuery._() : super(FirestorePlatform.instance, _kQueryPath);
}

void main() {
  initializeMethodChannel();

  group("$QueryPlatform()", () {
    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );
    });
    test("parameters", () {
      _hasDefaultParameters(TestQuery._().parameters);
    });

    test("limit", () {
      final testQuery = TestQuery._().limit(1);
      expect(testQuery.parameters["limit"], equals(1));
      _hasDefaultParameters(testQuery.parameters);
    });
  });
}

void _hasDefaultParameters(Map<String, dynamic> input) {
  expect(input["where"], equals([]));
  expect(input["orderBy"], equals([]));
}
