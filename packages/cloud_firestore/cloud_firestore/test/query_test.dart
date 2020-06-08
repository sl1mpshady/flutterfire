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
      // secondary app
      await FirebaseCore.instance.initializeApp(
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

    group('limit()', () {
      test('throws if limit is negative', () {
        expect(() => query.limit(0), throwsAssertionError);
        expect(() => query.limitToLast(-1), throwsAssertionError);
      });
    });

    group('where()', () {
      test('throws if field is invalid', () {
        expect(() => query.where(123), throwsAssertionError);
      });

      test('throws if multiple inequalities on different paths is provided',
          () {
        expect(
            () => query
                .where('foo.bar', isGreaterThanOrEqualTo: 123)
                .where('bar', isLessThan: 123),
            throwsAssertionError);
      });

      test('allows inequality on the same path', () {
        query
            .where('foo.bar', isGreaterThan: 123)
            .where('foo.bar', isGreaterThan: 1234);
      });

      test('throws if inequality is different to first orderBy', () {
        expect(() => query.where('foo', isGreaterThan: 123).orderBy('bar'),
            throwsAssertionError);
        expect(() => query.orderBy('bar').where('foo', isGreaterThan: 123),
            throwsAssertionError);
        expect(
            () => query
                .where('foo', isGreaterThan: 123)
                .orderBy('bar')
                .orderBy('foo'),
            throwsAssertionError);
        expect(
            () => query
                .orderBy('bar')
                .orderBy('foo')
                .where('foo', isGreaterThan: 123),
            throwsAssertionError);
      });

      test('throws if whereIn query length is greater than 10', () {
        expect(
            () => query
                .where('foo.bar', whereIn: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
            throwsAssertionError);
      });

      test('throws if arrayContainsAny query length is greater than 10', () {
        expect(
            () => query.where('foo',
                arrayContainsAny: [1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9]),
            throwsAssertionError);
      });

      test('throws if empty array used for whereIn filters', () {
        expect(() => query.where('foo', whereIn: []), throwsAssertionError);
      });

      test('throws if empty array used for arrayContainsAny filters', () {
        expect(() => query.where('foo', arrayContainsAny: []),
            throwsAssertionError);
      });

      test('throws if multiple array filters in query', () {
        expect(
            () => query
                .where('foo.bar', arrayContains: 1)
                .where('foo.bar', arrayContains: 2),
            throwsAssertionError);
        expect(
            () => query
                .where('foo.bar', arrayContains: 1)
                .where('foo.bar', arrayContainsAny: [2, 3]),
            throwsAssertionError);
        expect(
            () => query.where('foo.bar',
                arrayContainsAny: [1, 2]).where('foo.bar', arrayContains: 3),
            throwsAssertionError);
      });

      test('throws if multiple disjunctive filters in query', () {
        expect(
            () => query
                .where('foo', whereIn: [1, 2]).where('foo', whereIn: [2, 3]),
            throwsAssertionError);
        expect(
            () => query.where('foo', arrayContainsAny: [1]).where('foo',
                arrayContainsAny: [2, 3]),
            throwsAssertionError);
        expect(
            () => query.where('foo', arrayContainsAny: [2, 3]).where('foo',
                whereIn: [2, 3]),
            throwsAssertionError);
        expect(
            () => query.where('foo', whereIn: [2, 3]).where('foo',
                arrayContainsAny: [2, 3]),
            throwsAssertionError);
        expect(
            () => query
                .where('foo', whereIn: [2, 3])
                .where('foo', arrayContains: 1)
                .where('foo', arrayContainsAny: [2]),
            throwsAssertionError);
        expect(
            () => query.where('foo', arrayContains: 1).where('foo',
                whereIn: [2, 3]).where('foo', arrayContainsAny: [2]),
            throwsAssertionError);
      });

      test('allows arrayContains with whereIn filter', () {
        query.where('foo', arrayContains: 1).where('foo', whereIn: [2, 3]);
        query.where('foo', whereIn: [2, 3]).where('foo', arrayContains: 1);
        // cannot use more than one 'array-contains' or 'whereIn' filter
        expect(
            () => query
                .where('foo', whereIn: [2, 3])
                .where('foo', arrayContains: 1)
                .where('foo', arrayContains: 2),
            throwsAssertionError);
        expect(
            () => query
                .where('foo', arrayContains: 1)
                .where('foo', whereIn: [2, 3]).where('foo', whereIn: [2, 3]),
            throwsAssertionError);
      });

      // TODO: validation when filtering on FieldPath.documentId
      // when querying with documentId, can't be empty string
      // when querying with documentId, string can't contain slashes
      // when querying with documentId, value can't be int (has to be string)
      // when querying with documentId, value must result in valid path, can't be odds number of segments
      // when querying with documentId, can't perform arrayContains
      // when querying with documentId, can't perform arrayContainsAny
      // when querying with documentId, whereIn must have proper doc references in array [''] - check !empty string
      // when querying with documentId, whereIn must provide a plain doc ID, ['foo/bar/baz'] - check !slashes
      // when querying with documentId, whereIn must provide valid string, [1] - check !number
    });

    group('cursor queries', () {
      test('throws if starting or ending point specified after orderBy', () {
        var q = query.orderBy('foo');
        expect(() => q.startAt([1]).orderBy('bar'), throwsAssertionError);
        expect(() => q.startAfter([1]).orderBy('bar'), throwsAssertionError);
        expect(() => q.endAt([1]).orderBy('bar'), throwsAssertionError);
        expect(() => q.endBefore([1]).orderBy('bar'), throwsAssertionError);
      });

      test('throws if inconsistent arguments number', () {
        expect(() => query.orderBy('foo').startAt(['bar', 'baz']),
            throwsAssertionError);
        expect(() => query.orderBy('foo').startAfter(['bar', 'baz']),
            throwsAssertionError);
        expect(() => query.orderBy('foo').endAt(['bar', 'baz']),
            throwsAssertionError);
        expect(() => query.orderBy('foo').endBefore(['bar', 'baz']),
            throwsAssertionError);
      });

      test('throws if fields are not a String or FieldPath', () {
        expect(() => query.endAt([123, {}]), throwsAssertionError);
        expect(() => query.startAt(['123', []]), throwsAssertionError);
        expect(() => query.endBefore([true]), throwsAssertionError);
        expect(() => query.startAfter([false]), throwsAssertionError);
      });

      test('throws if fields is greater than the number of orders', () {
        expect(() => query.endAt(['123']), throwsAssertionError);
        expect(
            () => query.startAt([
                  FieldPath(['123'])
                ]),
            throwsAssertionError);
      });

      test('endAt() replaces all end parameters', () {
        var q = query.orderBy('foo').endBefore(['123']);
        expect(
            q.parameters['endBefore'], equals([FieldPath.fromString('123')]));
        q = q.endAt(['456']);
        expect(q.parameters['endBefore'], isNull);
        expect(q.parameters['endAt'], equals([FieldPath.fromString('456')]));
      });

      test('throws if order-by-key bounds are strings with slashes', () {
        expect(() => query.orderBy('foo').startAt(['foo/bar']),
            throwsAssertionError);
      });
    });
  });
}