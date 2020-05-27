// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runFieldValueTests() {
  group('$FieldValue', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    group('increment()', () {
      testWidgets('increments a number if it exists',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-increment-exists');
        await doc.setData({'foo': 2});
        await doc.updateData({'foo': FieldValue.increment(1)});
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals(3));
      });

      testWidgets('sets an increment if it does not exist',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-increment-not-exists');
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.exists, isFalse);
        await doc.setData({'foo': FieldValue.increment(1)});
        DocumentSnapshot snapshot2 = await doc.get();
        expect(snapshot2.data()['foo'], equals(1));
      });
    });

    group('serverTimestamp()', () {
      testWidgets('sets a new server time value', (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-server-timestamp-new');
        await doc.setData({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], isA<Timestamp>());
      });

      testWidgets('updates a server time value', (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-server-timestamp-update');
        await doc.setData({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot snapshot = await doc.get();
        Timestamp serverTime1 = snapshot.data()['foo'];
        expect(serverTime1, isA<Timestamp>());
        await Future.delayed(const Duration(milliseconds: 100));
        await doc.updateData({'foo': FieldValue.serverTimestamp()});
        DocumentSnapshot snapshot2 = await doc.get();
        Timestamp serverTime2 = snapshot2.data()['foo'];
        expect(serverTime2, isA<Timestamp>());
        expect(
            serverTime2.microsecondsSinceEpoch >
                serverTime1.microsecondsSinceEpoch,
            isTrue);
      });
    });

    group('delete()', () {
      testWidgets('removes a value', (WidgetTester tester) async {
        DocumentReference doc = await initializeTest('field-value-delete');
        await doc.setData({'foo': 'bar', 'bar': 'baz'});
        await doc.updateData({'bar': FieldValue.delete()});
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data(), equals(<String, dynamic>{'foo': 'bar'}));
      });
    });

    group('arrayUnion()', () {
      testWidgets('updates an existing array', (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-union-update-array');
        await doc.setData({
          'foo': [1, 2]
        });
        await doc.updateData({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([1, 2, 3, 4]));
      });

      testWidgets('updates an array if current value is not an array',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-union-replace');
        await doc.setData({'foo': 'bar'});
        await doc.updateData({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([3, 4]));
      });

      testWidgets('sets an array if current value is not an array',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-union-replace');
        await doc.setData({'foo': 'bar'});
        await doc.setData({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([3, 4]));
      });
    });

    group('arrayRemove()', () {
      testWidgets('removes items in an array', (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-remove-existing');
        await doc.setData({
          'foo': [1, 2, 3, 4]
        });
        await doc.updateData({
          'foo': FieldValue.arrayRemove([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([1, 2]));
      });

      testWidgets('removes & updates an array if existing item is not an array',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-remove-replace');
        await doc.setData({'foo': 'bar'});
        await doc.updateData({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([3, 4]));
      });

      testWidgets('removes & sets an array if existing item is not an array',
          (WidgetTester tester) async {
        DocumentReference doc =
            await initializeTest('field-value-array-remove-replace');
        await doc.setData({'foo': 'bar'});
        await doc.setData({
          'foo': FieldValue.arrayUnion([3, 4])
        });
        DocumentSnapshot snapshot = await doc.get();
        expect(snapshot.data()['foo'], equals([3, 4]));
      });
    });
  });
}
