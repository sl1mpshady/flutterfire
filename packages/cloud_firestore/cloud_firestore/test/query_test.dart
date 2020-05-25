// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;
  Query query;

  group("$Query", () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp();
      FirebaseApp secondayApp = await FirebaseCore.instance.initializeApp(
          name: 'foo',
          options: FirebaseOptions(
            apiKey: '123',
            appId: '123',
            messagingSenderId: '123',
            projectId: '123',
          ));

      firestore = Firestore.instance;
    });

    setUp(() {
      // Reset the query before each test
      query = firestore.collection('foo');
    });

    // TODO(ehesp): Query equality checks
    // test('equality', () {
    //   CollectionReference ref = firestore.collection('foo');
    //   CollectionReference ref2 = firestoreSecondary.collection('foo');

    //   expect(ref == firestore.collection('foo'), isTrue);
    //   expect(ref2 == firestoreSecondary.collection('foo'), isTrue);
    // });

    group('cursor queries', () {
      test('throws if fields are not a String or FieldPath', () {
        expect(() => query.endAt([123, {}]), throwsAssertionError);
        expect(() => query.startAt(['123', []]), throwsAssertionError);
        expect(() => query.endBefore([true]), throwsAssertionError);
        expect(() => query.startAfter([false]), throwsAssertionError);
      });

      test('throws if fields is greater than the number of orders', () {
        expect(() => query.endAt(['123']), throwsAssertionError);
        expect(() => query.startAt([FieldPath(['123'])]), throwsAssertionError);
      });

      test('endAt() replaces all end parameters', () {
        query.orderBy('foo').endBefore(['123']);
        expect(query.parameters['endBefore'], equals([FieldPath.fromString('123')]));
        query.endAt(['456']);
        expect(query.parameters['endBefore'], isNull);
        expect(query.parameters['endAt'], equals([FieldPath.fromString('456')]));
      });
    });
  });
}
