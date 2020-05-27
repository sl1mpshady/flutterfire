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

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    testWidgets('throw a [FirebaseException] if permission is denied', (WidgetTester tester) async {
      // TODO(ehesp): Implement once handled
      // fail("TODO");
    });


  });
}
