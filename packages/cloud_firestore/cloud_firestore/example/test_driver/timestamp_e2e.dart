// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runTimestampTests() {
  group('$Timestamp', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    testWidgets('sets a $Timestamp & returns one', (WidgetTester tester) async {
      DocumentReference doc = await initializeTest('timestamp');
      DateTime date = DateTime.utc(3000, 01, 01);

      await doc.setData({'foo': Timestamp.fromDate(date)});
      DocumentSnapshot snapshot = await doc.get();
      Timestamp timestamp = snapshot.data()['foo'];
      expect(timestamp, isA<Timestamp>());
      expect(timestamp.millisecondsSinceEpoch,
          equals(date.millisecondsSinceEpoch));
    });

    testWidgets('updates a $Timestamp & returns', (WidgetTester tester) async {
      DocumentReference doc = await initializeTest('geo-point-update');
      DateTime date = DateTime.utc(3000, 01, 02);
      await doc.setData({'foo': DateTime.utc(3000, 01, 01)});
      await doc.updateData({'foo': date});
      DocumentSnapshot snapshot = await doc.get();
      Timestamp timestamp = snapshot.data()['foo'];
      expect(timestamp, isA<Timestamp>());
      expect(timestamp.millisecondsSinceEpoch,
          equals(date.millisecondsSinceEpoch));
    });
  });
}
