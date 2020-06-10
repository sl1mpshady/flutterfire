// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runDocumentChangeTests() {
  group('$DocumentChange', () {
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

    test('returns the correct metadata when adding and removing', () async {
      CollectionReference collection =
          await initializeTest('add-remove-document');
      DocumentReference doc1 = collection.document('doc1');

      // Set something in the database
      await doc1.setData({'name': 'doc1'});

      Stream<QuerySnapshot> stream = collection.snapshots();
      int call = 0;

      StreamSubscription subscription =
          stream.listen(expectAsync1((QuerySnapshot snapshot) {
        call++;
        if (call == 1) {
          expect(snapshot.documents.length, equals(1));
          expect(snapshot.documentChanges.length, equals(1));
          expect(snapshot.documentChanges[0], isA<DocumentChange>());
          DocumentChange change = snapshot.documentChanges[0];
          expect(change.newIndex, equals(0));
          expect(change.oldIndex, equals(-1));
          expect(change.type, equals(DocumentChangeType.added));
          expect(change.document.data()['name'], equals('doc1'));
        } else if (call == 2) {
          expect(snapshot.documents.length, equals(0));
          expect(snapshot.documentChanges.length, equals(1));
          expect(snapshot.documentChanges[0], isA<DocumentChange>());
          DocumentChange change = snapshot.documentChanges[0];
          expect(change.newIndex, equals(-1));
          expect(change.oldIndex, equals(0));
          expect(change.type, equals(DocumentChangeType.removed));
          expect(change.document.data()['name'], equals('doc1'));
        } else {
          fail("Should not have been called");
        }
      }, count: 2, reason: "Stream should only have been called twice."));

      await Future.delayed(Duration(seconds: 1)); // Ensure listener fires
      await doc1.delete();

      subscription.cancel();
    });

    test('returns the correct metadata when modifying', () async {
      CollectionReference collection =
          await initializeTest('add-modify-document');
      DocumentReference doc1 = collection.document('doc1');
      DocumentReference doc2 = collection.document('doc2');
      DocumentReference doc3 = collection.document('doc3');

      await doc1.setData({'value': 1});
      await doc2.setData({'value': 2});
      await doc3.setData({'value': 3});

      Stream<QuerySnapshot> stream = collection.orderBy('value').snapshots();

      int call = 0;
      StreamSubscription subscription =
          stream.listen(expectAsync1((QuerySnapshot snapshot) {
        call++;
        if (call == 1) {
          expect(snapshot.documents.length, equals(3));
          expect(snapshot.documentChanges.length, equals(3));
          snapshot.documentChanges
              .asMap()
              .forEach((int index, DocumentChange change) {
            expect(change.oldIndex, equals(-1));
            expect(change.newIndex, equals(index));
            expect(change.type, equals(DocumentChangeType.added));
            expect(change.document.data()['value'], equals(index + 1));
          });
        } else if (call == 2) {
          expect(snapshot.documents.length, equals(3));
          expect(snapshot.documentChanges.length, equals(1));
          DocumentChange change = snapshot.documentChanges[0];
          expect(change.oldIndex, equals(0));
          expect(change.newIndex, equals(2));
          expect(change.type, equals(DocumentChangeType.modified));
          expect(change.document.id, equals('doc1'));
        } else {
          fail("Should not have been called");
        }
      }, count: 2, reason: "Stream should only have been called twice."));

      await Future.delayed(Duration(seconds: 1)); // Ensure listener fires
      await doc1.updateData({'value': 4});

      subscription.cancel();
    });
  });
}
