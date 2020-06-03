// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class TestFirestore extends FirestorePlatform {
  TestFirestore._() : super();
}

void main() {
  initializeMethodChannel();
  group("$FirestorePlatform()", () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp();
    });
    test("app", () {
      final firestore = TestFirestore._();

      expect(firestore.app, isInstanceOf<FirebaseApp>());
      expect(firestore.app, equals(FirebaseCore.instance.app()));
    });
  });
}
