// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runTransactionTests() {
  group('$Transaction', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    testWidgets('should resolve with user value', (WidgetTester tester) async {
      int randomValue = Random().nextInt(9999);
      int response =
          await firestore.runTransaction<int>((Transaction transaction) async {
        return randomValue;
      });
      expect(response, equals(randomValue));
    });

    testWidgets('should throw with exception', (WidgetTester tester) async {
      try {
        await firestore.runTransaction((Transaction transaction) async {
          throw StateError('foo');
        });
        fail("Transaction should not have resolved");
      } on StateError catch (e) {
        expect(e.message, equals('foo'));
        return;
      } catch (e) {
        fail("Transaction threw invalid exeption");
      }
    });

    testWidgets(
        'should throw a native error, and convert to a [FirebaseException]',
        (WidgetTester tester) async {
      DocumentReference documentReference =
          firestore.document('not-allowed/document');

      try {
        await firestore.runTransaction((Transaction transaction) async {
          transaction.set(documentReference, {'foo': 'bar'});
        });
        fail("Transaction should not have resolved");
      } on FirebaseException catch (e) {
        expect(e.code, equals('permission-denied'));
        return;
      } catch (e) {
        fail("Transaction threw invalid exeption");
      }
    });

    group('get()', () {
      testWidgets('should throw if get is not written',
          (WidgetTester tester) async {
        DocumentReference documentReference =
            firestore.document('flutter-tests/foo');

        expect(
            () => firestore.runTransaction((Transaction transaction) async {
                  await transaction.get(documentReference);
                }),
            throwsAssertionError);
      });

      testWidgets('should return a document snapshot',
          (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-get');

        DocumentSnapshot snapshot =
            await firestore.runTransaction((Transaction transaction) async {
          DocumentSnapshot returned = await transaction.get(documentReference);
          // required:
          transaction.set(documentReference, {'foo': 'bar'});
          return returned;
        });

        expect(snapshot, isA<DocumentSnapshot>());
        expect(snapshot.reference.path, equals(documentReference.path));
      });
    });

    group('delete()', () {
      testWidgets('should delete a document', (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-delete');

        await documentReference.setData({'foo': 'bar'});

        await firestore.runTransaction((Transaction transaction) async {
          transaction.delete(documentReference);
        });

        DocumentSnapshot snapshot = await documentReference.get();
        expect(snapshot.exists, isFalse);
      });
    });

    group('update()', () {
      testWidgets('should update a document', (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-update');

        await documentReference.setData({'foo': 'bar', 'bar': 1});

        await firestore.runTransaction((Transaction transaction) async {
          DocumentSnapshot documentSnapshot =
              await transaction.get(documentReference);
          transaction.update(documentReference, {
            'bar': documentSnapshot.data()['bar'] + 1,
          });
        });

        DocumentSnapshot snapshot = await documentReference.get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()['bar'], equals(2));
        expect(snapshot.data()['foo'], equals('bar'));
      });
    });

    group('set()', () {
      testWidgets('sets a document', (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-set');

        await documentReference.setData({'foo': 'bar', 'bar': 1});

        await firestore.runTransaction((Transaction transaction) async {
          DocumentSnapshot documentSnapshot =
              await transaction.get(documentReference);
          transaction.set(documentReference, {
            'bar': documentSnapshot.data()['bar'] + 1,
          });
        });

        DocumentSnapshot snapshot = await documentReference.get();
        expect(snapshot.exists, isTrue);
        expect(
            snapshot.data(),
            equals(<String, dynamic>{
              'bar': 2,
            }));
      });

      testWidgets('merges a document with set', (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-set-merge');

        await documentReference.setData({'foo': 'bar', 'bar': 1});

        await firestore.runTransaction((Transaction transaction) async {
          DocumentSnapshot documentSnapshot =
              await transaction.get(documentReference);
          transaction.set(
              documentReference,
              {
                'bar': documentSnapshot.data()['bar'] + 1,
              },
              SetOptions(merge: true));
        });

        DocumentSnapshot snapshot = await documentReference.get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()['bar'], equals(2));
        expect(snapshot.data()['foo'], equals('bar'));
      });

      testWidgets('merges fields a document with set',
          (WidgetTester tester) async {
        DocumentReference documentReference =
            await initializeTest('transaction-set-merge-fields');

        await documentReference.setData({'foo': 'bar', 'bar': 1, 'baz': 1});

        await firestore.runTransaction((Transaction transaction) async {
          DocumentSnapshot documentSnapshot =
              await transaction.get(documentReference);
          transaction.set(
              documentReference,
              {
                'bar': documentSnapshot.data()['bar'] + 1,
                'baz': 'ben',
              },
              SetOptions(mergeFields: ['bar']));
        });

        DocumentSnapshot snapshot = await documentReference.get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data(),
            equals(<String, dynamic>{'foo': 'bar', 'bar': 2, 'baz': 1}));
      });
    });
  });
}
