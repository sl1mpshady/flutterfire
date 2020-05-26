// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runQueryTests() {
  group('$Query', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<CollectionReference> initializeTest(String id) async {
      CollectionReference collection =
          firestore.collection('flutter-tests/$id/query-tests');
      QuerySnapshot snapshot = await collection.get();
      snapshot.documents.forEach((doc) async {
        await firestore.document(doc.reference.path).delete();
      });
      return collection;
    }

    group('endAt()', () {
      testWidgets('ends at string field paths', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('endAt-string');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.document('doc2').setData({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.document('doc3').setData({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot snapshot = await collection
            .orderBy('bar.value', descending: true)
            .endAt([2]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));

        QuerySnapshot snapshot2 =
            await collection.orderBy('foo').endAt([2]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc1'));
        expect(snapshot2.documents[1].id, equals('doc2'));
      });

      testWidgets('ends at field paths', (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('endAt-field-path');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.document('doc2').setData({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.document('doc3').setData({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot snapshot = await collection
            .orderBy(FieldPath(['bar', 'value']), descending: true)
            .endAt([2]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));

        QuerySnapshot snapshot2 =
            await collection.orderBy(FieldPath(['foo'])).endAt([2]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc1'));
        expect(snapshot2.documents[1].id, equals('doc2'));
      });

      testWidgets('endAtDocument() ends at a document field value',
          (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('endAt-document');
        await Future.wait([
          collection.document('doc1').setData({
            'bar': {'value': 3}
          }),
          collection.document('doc2').setData({
            'bar': {'value': 2}
          }),
          collection.document('doc3').setData({
            'bar': {'value': 1}
          }),
        ]);

        DocumentSnapshot endAtSnapshot =
            await collection.document('doc2').get();

        QuerySnapshot snapshot = await collection
            .orderBy('bar.value')
            .endAtDocument(endAtSnapshot)
            .get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));
      });

      testWidgets('endAtDocument() ends at a document',
          (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('endAt-document');
        await Future.wait([
          collection.document('doc1').setData({
            'bar': {'value': 1}
          }),
          collection.document('doc2').setData({
            'bar': {'value': 2}
          }),
          collection.document('doc3').setData({
            'bar': {'value': 3}
          }),
          collection.document('doc4').setData({
            'bar': {'value': 4}
          }),
        ]);

        DocumentSnapshot endAtSnapshot =
            await collection.document('doc3').get();

        QuerySnapshot snapshot =
            await collection.endAtDocument(endAtSnapshot).get();

        expect(snapshot.documents.length, equals(3));
        expect(snapshot.documents[0].id, equals('doc1'));
        expect(snapshot.documents[1].id, equals('doc2'));
        expect(snapshot.documents[2].id, equals('doc3'));
      });
    });
  });
}
