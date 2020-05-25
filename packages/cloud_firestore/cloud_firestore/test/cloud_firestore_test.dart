// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;
  Firestore firestoreSecondary;
  FirebaseApp secondayApp;

  group('$Firestore', () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp();
      secondayApp = await FirebaseCore.instance.initializeApp(
          name: 'foo',
          options: FirebaseOptions(
            apiKey: '123',
            appId: '123',
            messagingSenderId: '123',
            projectId: '123',
          ));

      firestore = Firestore.instance;
      firestoreSecondary = Firestore.instanceFor(app: secondayApp);
    });

    test('equality', () {
      expect(firestore, equals(Firestore.instance));
      expect(
          firestoreSecondary, equals(Firestore.instanceFor(app: secondayApp)));
    });

    test('returns the correct $FirebaseApp', () {
      expect(firestore.app, equals(FirebaseCore.instance.app()));
      expect(firestoreSecondary.app, equals(FirebaseCore.instance.app('foo')));
    });

    group('.collection()', () {
      test('returns a $CollectionReference', () {
        expect(firestore.collection('foo'), isA<CollectionReference>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.collection(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.collection(''), throwsAssertionError);
      });

      test('does accept an invalid path', () {
        // 'foo/bar' points to a document
        expect(() => firestore.collection('foo/bar'), throwsAssertionError);
      });
    });

    group('.collectionGroup()', () {
      test('returns a $Query', () {
        expect(firestore.collectionGroup('foo'), isA<Query>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.collectionGroup(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.collectionGroup(''), throwsAssertionError);
      });

      test('does accept a path containing "/"', () {
        expect(() => firestore.collectionGroup('foo/bar/baz'),
            throwsAssertionError);
      });
    });

    group('.document()', () {
      test('returns a $DocumentReference', () {
        expect(firestore.document('foo/bar'), isA<DocumentReference>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.document(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.document(''), throwsAssertionError);
      });

      test('does accept an invalid path', () {
        // 'foo' points to a collection
        expect(() => firestore.document('bar'), throwsAssertionError);
      });
    });
  });
}
