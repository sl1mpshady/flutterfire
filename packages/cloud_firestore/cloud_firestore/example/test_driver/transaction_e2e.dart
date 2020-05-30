// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runTransactionTests() {
  group('$Transaction', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    // Future<DocumentReference> initializeTest(String path) async {
    //   String prefixedPath = 'flutter-tests/$path';
    //   await firestore.document(prefixedPath).delete();
    //   return firestore.document(prefixedPath);
    // }

    testWidgets('runs transaction handlers', (WidgetTester tester) async {
      DocumentReference documentReference =
          firestore.document('playground/transaction-test');
      try {
        dynamic result =
            await firestore.runTransaction((Transaction transaction) async {
          // DocumentSnapshot snapshot = await transaction.get(documentReference);

          throw StateError("foo bar");
        });

        print('----------');
        print(result);
        print('----------');
      } on StateError catch(e) {
        print('Gracefully caught exception...');
        print(e);
      } catch (e) {
        print('This was not expected!');
        print(e);
      }
    });
  });
}
