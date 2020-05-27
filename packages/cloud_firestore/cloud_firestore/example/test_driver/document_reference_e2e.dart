// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runDocumentReferenceTests() {
  group('$DocumentReference', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    testWidgets('delete() deletes a document', (WidgetTester tester) async {
      DocumentReference document = await initializeTest('document-delete');
      await document.setData({
        'foo': 'bar',
      });
      DocumentSnapshot snapshot = await document.get();
      expect(snapshot.exists, isTrue);
      await document.delete();
      DocumentSnapshot snapshot2 = await document.get();
      expect(snapshot2.exists, isFalse);
    });

    testWidgets('get() gets a document from server',
        (WidgetTester tester) async {
      DocumentReference document = await initializeTest('document-get-server');
      await document.setData({'foo': 'bar'});
      DocumentSnapshot snapshot =
          await document.get(GetOptions(source: Source.server));
      expect(snapshot.data(), {'foo': 'bar'});
      expect(snapshot.metadata.isFromCache, isFalse);
    });

    testWidgets('get() gets a document from cache',
        (WidgetTester tester) async {
      DocumentReference document = await initializeTest('document-get-cache');
      await document.setData({'foo': 'bar'});
      DocumentSnapshot snapshot =
          await document.get(GetOptions(source: Source.cache));
      expect(snapshot.data(), equals({'foo': 'bar'}));
      expect(snapshot.metadata.isFromCache, isTrue);
    });

    testWidgets('set() sets data', (WidgetTester tester) async {
      DocumentReference document = await initializeTest('document-set');
      await document.setData({'foo': 'bar'});
      DocumentSnapshot snapshot = await document.get();
      expect(snapshot.data(), equals({'foo': 'bar'}));
      await document.setData({'bar': 'baz'});
      DocumentSnapshot snapshot2 = await document.get();
      expect(snapshot2.data(), equals({'bar': 'baz'}));
    });

    testWidgets('set() merges data', (WidgetTester tester) async {
      DocumentReference document = await initializeTest('document-set-merge');
      await document.setData({'foo': 'bar'});
      DocumentSnapshot snapshot = await document.get();
      expect(snapshot.data(), equals({'foo': 'bar'}));
      await document
          .setData({'foo': 'ben', 'bar': 'baz'}, SetOptions(merge: true));
      DocumentSnapshot snapshot2 = await document.get();
      expect(snapshot2.data(), equals({'foo': 'ben', 'bar': 'baz'}));
    });

    testWidgets('set() merges fields', (WidgetTester tester) async {
      DocumentReference document =
          await initializeTest('document-set-merge-fields');
      Map<String, dynamic> initialData = {
        'foo': 'bar',
        'bar': 123,
        'baz': '456',
      };
      Map<String, dynamic> dataToSet = {
        'foo': 'should-not-merge',
        'bar': 456,
        'baz': 'foo',
      };
      await document.setData(initialData);
      DocumentSnapshot snapshot = await document.get();
      expect(snapshot.data(), equals(initialData));
      await document.setData(
          dataToSet,
          SetOptions(mergeFields: [
            'bar',
            FieldPath(['baz'])
          ]));
      DocumentSnapshot snapshot2 = await document.get();
      expect(
          snapshot2.data(), equals({'foo': 'bar', 'bar': 456, 'baz': 'foo'}));
    });

    testWidgets('throws a [FirebaseException] if permission denied',
        (WidgetTester tester) async {
      // TODO(ehesp): Implement once rejection handler is setup

      // DocumentReference document = firestore.document('not-allowed/document');

      // try {
      //   await document.get();
      // } catch(e) {
      //   expect(e, isA<FirebaseException>());
      // }

      // fail("should have thrown a [FirebaseException]");
    });
  });
}
