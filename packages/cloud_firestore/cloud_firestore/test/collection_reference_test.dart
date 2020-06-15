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

  group("$CollectionReference", () {
    setUpAll(() async {
      await Firebase.initializeApp();
      FirebaseApp secondayApp = await Firebase.initializeApp(
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

    test('extends $Query', () {
      // The `firestore` property is publically accessible via Query.
      // Is there a better way to test this?
      CollectionReference ref = firestore.collection('foo');

      expect(ref.firestore, equals(firestore));
    });

    test('equality', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestoreSecondary.collection('foo');

      expect(ref == firestore.collection('foo'), isTrue);
      expect(ref2 == firestoreSecondary.collection('foo'), isTrue);
    });

    test('returns the correct id', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.id, equals('foo'));
      expect(ref2.id, equals('baz'));
    });

    test('returns the correct parent', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.parent, isNull);
      expect(ref2.parent, isA<DocumentReference>());

      DocumentReference docRef = firestore.document('foo/bar');
      expect(ref2.parent, equals(docRef));
    });

    test('returns the correct path', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.path, equals('foo'));
      expect(ref2.path, equals('foo/bar/baz'));
    });

    test('.document() returns the correct $DocumentReference', () {
      CollectionReference ref = firestore.collection('foo');

      expect(ref.document('bar'), firestore.document('foo/bar'));
    });
  });
}
