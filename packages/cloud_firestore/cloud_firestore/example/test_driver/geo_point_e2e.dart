// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runGeoPointTests() {
  group('$GeoPoint', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    testWidgets('sets a $GeoPoint & returns one', (WidgetTester tester) async {
      DocumentReference doc = await initializeTest('geo-point');
      await doc.setData({'foo': GeoPoint(10, -10)});
      DocumentSnapshot snapshot = await doc.get();
      GeoPoint geopoint = snapshot.data()['foo'];
      expect(geopoint, isA<GeoPoint>());
      expect(geopoint.latitude, equals(10));
      expect(geopoint.longitude, equals(-10));
    });

    testWidgets('updates a $GeoPoint & returns', (WidgetTester tester) async {
      DocumentReference doc = await initializeTest('geo-point-update');
      await doc.setData({'foo': GeoPoint(10, -10)});
      await doc.updateData({'foo': GeoPoint(-10, 10)});
      DocumentSnapshot snapshot = await doc.get();
      GeoPoint geopoint = snapshot.data()['foo'];
      expect(geopoint, isA<GeoPoint>());
      expect(geopoint.latitude, equals(-10));
      expect(geopoint.longitude, equals(10));
    });
  });
}