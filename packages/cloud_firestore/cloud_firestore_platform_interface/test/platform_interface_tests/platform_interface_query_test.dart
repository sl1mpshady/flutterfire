// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

Map<String, dynamic> kMockParameters = {
  'orderBy': ['foo'],
  'limit': 1
};

class TestQuery extends QueryPlatform {
  TestQuery._() : super(FirestorePlatform.instance, null);
}

class TestQueryWithParameters extends QueryPlatform {
  TestQueryWithParameters._(Map<String, dynamic> parameters)
      : super(FirestorePlatform.instance, parameters);
}

void main() {
  initializeMethodChannel();

  group("$QueryPlatform()", () {
    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:123:ios:123',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '123',
        ),
      );
    });

    test("constructor", () {
      final query = TestQuery._();
      expect(query, isInstanceOf<QueryPlatform>());
    });

    test("verifyExtends", () {
      final query = TestQuery._();
      QueryPlatform.verifyExtends(query);
      expect(query, isInstanceOf<QueryPlatform>());
    });

    test("should have default parameters", () {
      _hasDefaultParameters(TestQuery._().parameters);
    });

    test("should set parameters", () {
      final query = TestQueryWithParameters._(kMockParameters);
      expect(query.parameters, equals(kMockParameters));
    });

    group("Unimplemented Methods", () {
      // TODO(helena) test for each method
      test("limit", () {
        try {
          TestQuery._().limit(1);
        } on UnimplementedError catch (e) {
          expect(e.message, equals("limit() is not implemented"));
          return;
        }
        fail('Should have thrown an [UnimplementedError]');
      });
    });
  });
}

void _hasDefaultParameters(Map<String, dynamic> input) {
  expect(input["where"], equals([]));
  expect(input["orderBy"], equals([]));
}
