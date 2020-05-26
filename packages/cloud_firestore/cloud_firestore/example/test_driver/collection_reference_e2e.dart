// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runCollectionReferenceTests() {
  group('$CollectionReference', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<CollectionReference> initializeTest() async {
      String prefixedPath = 'flutter-tests';
      return firestore.collection(prefixedPath);
    }

    testWidgets('add() adds a document',
        (WidgetTester tester) async {
      CollectionReference collection = await initializeTest();
      var rand = Random();
      var randNum = rand.nextInt(999999);
      DocumentReference doc = await collection.add({
        'value': randNum,
      });
      DocumentSnapshot snapshot = await doc.get();
      expect(randNum, equals(snapshot.data()['value']));
    });
  });
}
