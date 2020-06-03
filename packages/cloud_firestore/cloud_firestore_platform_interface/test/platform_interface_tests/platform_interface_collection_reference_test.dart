// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kCollectionId = "test";
const _kDocumentId = "document";
const _kSubCollectionId = "subTest";

class TestCollectionReference extends CollectionReferencePlatform {
  TestCollectionReference._()
      : super(FirestorePlatform.instance, '$_kCollectionId');
}

class TestSubCollectionReference extends CollectionReferencePlatform {
  TestSubCollectionReference._()
      : super(FirestorePlatform.instance,
            '$_kCollectionId/$_kDocumentId/$_kSubCollectionId');
}

void main() {
  initializeMethodChannel();

  group("$CollectionReferencePlatform()", () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp();
    });
    test("Parent", () {
      final collection = TestSubCollectionReference._();
      final parent = collection.parent;
      final parentPath = parent.path;
      expect(parent, isInstanceOf<DocumentReferencePlatform>());
      expect(parentPath, equals("$_kCollectionId/$_kDocumentId"));
    });

    test("id", () {
      final collection = TestCollectionReference._();
      expect(collection.id, equals(_kCollectionId));
    });

    test("Path", () {
      final document = TestCollectionReference._();
      expect(document.path, equals("$_kCollectionId"));
    });
  });
}
