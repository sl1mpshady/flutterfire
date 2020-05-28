// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:async';

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

    /**
     * get
     */

    group('get()', () {
      testWidgets('returns a [QuerySnapshot]', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get');
        QuerySnapshot qs = await collection.get();
        expect(qs, isA<QuerySnapshot>());
      });

      testWidgets('uses [GetOptions] cache', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get');
        QuerySnapshot qs =
            await collection.get(GetOptions(source: Source.cache));
        expect(qs, isA<QuerySnapshot>());
        expect(qs.metadata.isFromCache, isTrue);
      });

      testWidgets('uses [GetOptions] server', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get');
        QuerySnapshot qs =
            await collection.get(GetOptions(source: Source.server));
        expect(qs, isA<QuerySnapshot>());
        expect(qs.metadata.isFromCache, isFalse);
      });
    });

    /**
     * snapshots
     */

    group('snapshots()', () {
      testWidgets('returns a [Stream]', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get');
        Stream<QuerySnapshot> stream = collection.snapshots();
        expect(stream, isA<Stream<QuerySnapshot>>());
      });

      testWidgets('listens to a single response', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get-single');
        await collection.add({'foo': 'bar'});
        Stream<QuerySnapshot> stream = collection.snapshots();
        int call = 0;

        stream.listen(expectAsync1((QuerySnapshot snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.documents.length, equals(1));
            DocumentSnapshot documentSnapshot = snapshot.documents[0];
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else {
            fail("Should not have been called");
          }
        }, count: 1, reason: "Stream should only have been called once."));
      });

      testWidgets('listens to a multiple changes response',
          (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('get-multiple');
        await collection.add({'foo': 'bar'});

        Stream<QuerySnapshot> stream = collection.snapshots();
        int call = 0;

        StreamSubscription subscription = stream.listen(expectAsync1(
            (QuerySnapshot snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.documents.length, equals(1));
            DocumentSnapshot documentSnapshot = snapshot.documents[0];
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else if (call == 2) {
            expect(snapshot.documents.length, equals(2));
            DocumentSnapshot documentSnapshot =
                snapshot.documents.firstWhere((doc) => doc.id == 'doc1');
            expect(documentSnapshot.data()['bar'], equals('baz'));
          } else if (call == 3) {
            expect(snapshot.documents.length, equals(1));
            expect(snapshot.documents.where((doc) => doc.id == 'doc1').isEmpty,
                isTrue);
          } else if (call == 4) {
            expect(snapshot.documents.length, equals(2));
            DocumentSnapshot documentSnapshot =
                snapshot.documents.firstWhere((doc) => doc.id == 'doc2');
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else if (call == 5) {
            expect(snapshot.documents.length, equals(2));
            DocumentSnapshot documentSnapshot =
                snapshot.documents.firstWhere((doc) => doc.id == 'doc2');
            expect(documentSnapshot.data()['foo'], equals('baz'));
          } else {
            fail("Should not have been called");
          }
        },
            count: 5,
            reason: "Stream should only have been called five times."));

        await collection.document('doc1').setData({'bar': 'baz'});
        await collection.document('doc1').delete();
        await collection.document('doc2').setData({'foo': 'bar'});
        await collection.document('doc2').updateData({'foo': 'baz'});

        subscription.cancel();
      });
    });

    /**
     * End At
     */

    group('endAt{Document}()', () {
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

    /**
     * Start At
     */

    group('startAt{Document}()', () {
      testWidgets('starts at string field paths', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('startAt-string');
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
            .startAt([2]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc1'));

        QuerySnapshot snapshot2 =
            await collection.orderBy('foo').startAt([2]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc2'));
        expect(snapshot2.documents[1].id, equals('doc3'));
      });

      testWidgets('starts at field paths', (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('startAt-field-path');
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
            .startAt([2]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc1'));

        QuerySnapshot snapshot2 =
            await collection.orderBy(FieldPath(['foo'])).startAt([2]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc2'));
        expect(snapshot2.documents[1].id, equals('doc3'));
      });

      testWidgets('startAtDocument() starts at a document field value',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('startAt-document');
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

        DocumentSnapshot startAtSnapshot =
            await collection.document('doc2').get();

        QuerySnapshot snapshot = await collection
            .orderBy('bar.value')
            .startAtDocument(startAtSnapshot)
            .get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc1'));
      });

      testWidgets('startAtDocument() starts at a document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('startAt-document');
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

        DocumentSnapshot startAtSnapshot =
            await collection.document('doc3').get();

        QuerySnapshot snapshot =
            await collection.startAtDocument(startAtSnapshot).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc4'));
      });
    });

    /**
     * End Before
     */

    group('endBefore{Document}()', () {
      testWidgets('ends before string field paths',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('endBefore-string');
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
            .endBefore([1]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));

        QuerySnapshot snapshot2 =
            await collection.orderBy('foo').endBefore([3]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc1'));
        expect(snapshot2.documents[1].id, equals('doc2'));
      });

      testWidgets('ends before field paths', (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('endBefore-field-path');
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
            .endBefore([1]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));

        QuerySnapshot snapshot2 =
            await collection.orderBy(FieldPath(['foo'])).endBefore([3]).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc1'));
        expect(snapshot2.documents[1].id, equals('doc2'));
      });

      testWidgets('endbeforeDocument() ends before a document field value',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('endBefore-document');
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
            await collection.document('doc1').get();

        QuerySnapshot snapshot = await collection
            .orderBy('bar.value')
            .endBeforeDocument(endAtSnapshot)
            .get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));
      });

      testWidgets('endBeforeDocument() ends before a document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('endBefore-document');
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
            await collection.document('doc4').get();

        QuerySnapshot snapshot =
            await collection.endBeforeDocument(endAtSnapshot).get();

        expect(snapshot.documents.length, equals(3));
        expect(snapshot.documents[0].id, equals('doc1'));
        expect(snapshot.documents[1].id, equals('doc2'));
        expect(snapshot.documents[2].id, equals('doc3'));
      });
    });

    /**
     * Start & End
     */

    group('Start & End Queries', () {
      testWidgets('starts at & ends at a document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('start-end-string');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
          collection.document('doc4').setData({
            'foo': 4,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.orderBy('foo').startAt([2]).endAt([3]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc3'));
      });

      testWidgets('starts at & ends before a document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('start-end-string');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
          collection.document('doc4').setData({
            'foo': 4,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.orderBy('foo').startAt([2]).endBefore([4]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc3'));
      });

      testWidgets('starts after & ends at a document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('start-end-field-path');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
          collection.document('doc4').setData({
            'foo': 4,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.orderBy('foo').startAfter([1]).endAt([3]).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc3'));
      });

      testWidgets('starts a document and ends before document',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('start-end-document');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
          collection.document('doc4').setData({
            'foo': 4,
          }),
        ]);

        DocumentSnapshot startAtSnapshot =
            await collection.document('doc2').get();
        DocumentSnapshot endBeforeSnapshot =
            await collection.document('doc4').get();

        QuerySnapshot snapshot = await collection
            .startAtDocument(startAtSnapshot)
            .endBeforeDocument(endBeforeSnapshot)
            .get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc3'));
      });
    });

    /**
     * Limit
     */

    group('limit{toLast}()', () {
      testWidgets('limits documents', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('limit');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
        ]);

        QuerySnapshot snapshot = await collection.limit(2).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc1'));
        expect(snapshot.documents[1].id, equals('doc2'));

        QuerySnapshot snapshot2 =
            await collection.orderBy('foo', descending: true).limit(2).get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc3'));
        expect(snapshot2.documents[1].id, equals('doc2'));
      });

      testWidgets('limits to last documents', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('limitToLast');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.orderBy('foo').limitToLast(2).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].id, equals('doc2'));
        expect(snapshot.documents[1].id, equals('doc3'));

        QuerySnapshot snapshot2 = await collection
            .orderBy('foo', descending: true)
            .limitToLast(2)
            .get();

        expect(snapshot2.documents.length, equals(2));
        expect(snapshot2.documents[0].id, equals('doc2'));
        expect(snapshot2.documents[1].id, equals('doc1'));
      });
    });

    /**
     * Order
     */
    group('orderBy()', () {
      testWidgets('orders async by default', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('order-asc');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 3,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 1,
          }),
        ]);

        QuerySnapshot snapshot = await collection.orderBy('foo').get();

        expect(snapshot.documents.length, equals(3));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));
        expect(snapshot.documents[2].id, equals('doc1'));
      });

      testWidgets('orders descending', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('order-desc');
        await Future.wait([
          collection.document('doc1').setData({
            'foo': 1,
          }),
          collection.document('doc2').setData({
            'foo': 2,
          }),
          collection.document('doc3').setData({
            'foo': 3,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.orderBy('foo', descending: true).get();

        expect(snapshot.documents.length, equals(3));
        expect(snapshot.documents[0].id, equals('doc3'));
        expect(snapshot.documents[1].id, equals('doc2'));
        expect(snapshot.documents[2].id, equals('doc1'));
      });
    });

    /**
     * Where filters
     */

    group('where()', () {
      testWidgets('returns with equal checks', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('where-equal');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': rand,
          }),
          collection.document('doc2').setData({
            'foo': rand,
          }),
          collection.document('doc3').setData({
            'foo': rand + 1,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', isEqualTo: rand).get();

        expect(snapshot.documents.length, equals(2));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'], equals(rand));
        });
      });

      testWidgets('returns with greater than checks',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-greater-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': rand - 1,
          }),
          collection.document('doc2').setData({
            'foo': rand,
          }),
          collection.document('doc3').setData({
            'foo': rand + 1,
          }),
          collection.document('doc4').setData({
            'foo': rand + 2,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', isGreaterThan: rand).get();

        expect(snapshot.documents.length, equals(2));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'] > rand, isTrue);
        });
      });

      testWidgets('returns with greater than or equal to checks',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-greater-than-equal');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': rand - 1,
          }),
          collection.document('doc2').setData({
            'foo': rand,
          }),
          collection.document('doc3').setData({
            'foo': rand + 1,
          }),
          collection.document('doc4').setData({
            'foo': rand + 2,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', isGreaterThanOrEqualTo: rand).get();

        expect(snapshot.documents.length, equals(3));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'] >= rand, isTrue);
        });
      });

      testWidgets('returns with less than checks', (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-less-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': -(rand) + 1,
          }),
          collection.document('doc2').setData({
            'foo': -(rand) + 2,
          }),
          collection.document('doc3').setData({
            'foo': rand,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', isLessThan: rand).get();

        expect(snapshot.documents.length, equals(2));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'] < rand, isTrue);
        });
      });

      testWidgets('returns with less than equal checks',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-less-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': -(rand) + 1,
          }),
          collection.document('doc2').setData({
            'foo': -(rand) + 2,
          }),
          collection.document('doc3').setData({
            'foo': rand,
          }),
          collection.document('doc4').setData({
            'foo': rand + 1,
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', isLessThanOrEqualTo: rand).get();

        expect(snapshot.documents.length, equals(3));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'] <= rand, isTrue);
        });
      });

      testWidgets('returns with array-contains filter',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-array-contains');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.document('doc1').setData({
            'foo': [1, '2', rand],
          }),
          collection.document('doc2').setData({
            'foo': [1, '2', '$rand'],
          }),
          collection.document('doc3').setData({
            'foo': [1, '2', '$rand'],
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where('foo', arrayContains: '$rand').get();

        expect(snapshot.documents.length, equals(2));
        snapshot.documents.forEach((doc) {
          expect(doc.data()['foo'], equals([1, '2', '$rand']));
        });
      });

      testWidgets('returns with in filter', (WidgetTester tester) async {
        CollectionReference collection = await initializeTest('where-in');

        await Future.wait([
          collection.document('doc1').setData({
            'status': 'Ordered',
          }),
          collection.document('doc2').setData({
            'status': 'Ready to Ship',
          }),
          collection.document('doc3').setData({
            'status': 'Ready to Ship',
          }),
          collection.document('doc4').setData({
            'status': 'Incomplete',
          }),
        ]);

        QuerySnapshot snapshot = await collection
            .where('status', whereIn: ['Ready to Ship', 'Ordered']).get();

        expect(snapshot.documents.length, equals(3));
        snapshot.documents.forEach((doc) {
          String status = doc.data()['status'];
          expect(status == 'Ready to Ship' || status == 'Ordered', isTrue);
        });
      });

      testWidgets('returns with array-contains-any filter',
          (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-array-contains-any');

        await Future.wait([
          collection.document('doc1').setData({
            'category': ['Appliances', 'Housewares', 'Cooking'],
          }),
          collection.document('doc2').setData({
            'category': ['Appliances', 'Electronics', 'Nursery'],
          }),
          collection.document('doc3').setData({
            'category': ['Audio/Video', 'Electronics'],
          }),
          collection.document('doc4').setData({
            'category': ['Beauty'],
          }),
        ]);

        QuerySnapshot snapshot = await collection.where('category',
            arrayContainsAny: ['Appliances', 'Electronics']).get();

        // 2nd record should only be returned once
        expect(snapshot.documents.length, equals(3));
      });

      // When documents have a key with a "." in them, only a [FieldPath]
      // can access the value, rather than a raw string
      testWidgets('returns where FieldPath', (WidgetTester tester) async {
        CollectionReference collection =
            await initializeTest('where-field-path');

        FieldPath fieldPath = FieldPath(['nested', 'foo.bar@gmail.com']);

        await Future.wait([
          collection.document('doc1').setData({
            'nested': {
              'foo.bar@gmail.com': true,
            }
          }),
          collection.document('doc2').setData({
            'nested': {
              'foo.bar@gmail.com': true,
            },
            'foo': 'bar',
          }),
          collection.document('doc3').setData({
            'nested': {
              'foo.bar@gmail.com': false,
            }
          }),
        ]);

        QuerySnapshot snapshot =
            await collection.where(fieldPath, isEqualTo: true).get();

        expect(snapshot.documents.length, equals(2));
        expect(snapshot.documents[0].get(fieldPath), isTrue);
        expect(snapshot.documents[1].get(fieldPath), isTrue);
        expect(snapshot.documents[1].get('foo'), equals('bar'));
      });
    });
  });
}
