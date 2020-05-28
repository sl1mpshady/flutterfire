// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runWriteBatchTests() {
  group('$WriteBatch', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<CollectionReference> initializeTest(String id) async {
      CollectionReference collection =
          firestore.collection('flutter-tests/$id/query-tests');
      QuerySnapshot snapshot = await collection.get();
      await Future.forEach(snapshot.documents,
          (DocumentSnapshot documentSnapshot) {
        return documentSnapshot.reference.delete();
      });
      return collection;
    }

    testWidgets('performs batch operations', (WidgetTester tester) async {
      CollectionReference collection = await initializeTest('write-batch-ops');
      WriteBatch batch = firestore.batch();

      DocumentReference doc1 = await collection.document('doc1'); // delete
      DocumentReference doc2 = await collection.document('doc2'); // set
      DocumentReference doc3 = await collection.document('doc3'); // update
      DocumentReference doc4 =
          await collection.document('doc4'); // update w/ merge
      DocumentReference doc5 =
          await collection.document('doc5'); // update w/ mergeFields

      await Future.wait([
        doc1.setData({'foo': 'bar'}),
        doc2.setData({'foo': 'bar'}),
        doc3.setData({'foo': 'bar', 'bar': 'baz'}),
        doc4.setData({'foo': 'bar'}),
        doc5.setData({'foo': 'bar', 'bar': 'baz'}),
      ]);

      batch.delete(doc1);
      batch.setData(doc2, <String, dynamic>{'bar': 'baz'});
      batch.updateData(doc3, <String, dynamic>{'bar': 'ben'});
      batch.setData(
          doc4, <String, dynamic>{'bar': 'ben'}, SetOptions(merge: true));
      batch.setData(doc5, <String, dynamic>{'bar': 'ben'},
          SetOptions(mergeFields: ['bar']));

      await batch.commit();

      QuerySnapshot snapshot = await collection.get();

      expect(snapshot.documents.length, equals(4));
      expect(
          snapshot.documents.where((doc) => doc.id == 'doc1').isEmpty, isTrue);
      expect(
          snapshot.documents.firstWhere((doc) => doc.id == 'doc2').data(),
          equals(<String, dynamic>{
            'bar': 'baz',
          }));
      expect(
          snapshot.documents.firstWhere((doc) => doc.id == 'doc3').data(),
          equals(<String, dynamic>{
            'foo': 'bar',
            'bar': 'ben',
          }));
      expect(
          snapshot.documents.firstWhere((doc) => doc.id == 'doc4').data(),
          equals(<String, dynamic>{
            'foo': 'bar',
            'bar': 'ben',
          }));
      expect(
          snapshot.documents.firstWhere((doc) => doc.id == 'doc5').data(),
          equals(<String, dynamic>{
            'foo': 'bar',
            'bar': 'ben',
          }));
    });
  });
}
