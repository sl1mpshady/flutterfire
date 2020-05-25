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
  Firestore firestoreSecondary;

  group("$DocumentReference", () {
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
      firestoreSecondary = Firestore.instanceFor(app: secondayApp);
    });

    test('equality', () {
      DocumentReference ref = firestore.document('foo/bar');
      DocumentReference ref2 = firestore.document('foo/bar/baz/bert');

      expect(ref, equals(firestore.document('foo/bar')));
      expect(ref2, equals(firestore.document('foo/bar/baz/bert')));

      expect(ref == firestoreSecondary.document('foo/bar'), isFalse);
      expect(ref2 == firestoreSecondary.document('foo/bar/baz/bert'), isFalse);
    });

    test("returns document() returns a $DocumentReference", () {
      DocumentReference ref = firestore.document('foo/bar');
      DocumentReference ref2 = firestore.document('foo/bar/baz/bert');

      expect(ref, isA<DocumentReference>());
      expect(ref2, isA<DocumentReference>());
    });

    test("returns the same firestore instance", () {
      DocumentReference ref = firestore.document('foo/bar');
      DocumentReference ref2 = firestoreSecondary.document('foo/bar');

      expect(ref.firestore, equals(firestore));
      expect(ref2.firestore, equals(firestoreSecondary));
    });

    test("returns the correct ID", () {
      DocumentReference ref = firestore.document('foo/bar');
      DocumentReference ref2 = firestore.document('foo/bar/baz/bert');

      expect(ref, isA<DocumentReference>());
      expect(ref.id, equals('bar'));
      expect(ref2.id, equals('bert'));
    });

    group('.parent', () {
      test("returns a $CollectionReference", () {
        DocumentReference ref = firestore.document('foo/bar');

        expect(ref.parent, isA<CollectionReference>());
      });

      test("returns the correct $CollectionReference", () {
        DocumentReference ref = firestore.document('foo/bar');
        CollectionReference colRef = firestore.collection('foo');

        expect(ref.parent, equals(colRef));
      });
    });
  });
}