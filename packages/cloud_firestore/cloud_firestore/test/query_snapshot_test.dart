// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './mock.dart';

void main() {
  setupCloudFirestoreMocks();

  MethodChannelFirestore.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Query#getDocuments') {
      Map<String, bool> metadata = {
        'hasPendingWrites': false,
        'isFromCache': false,
      };
      Map<String, dynamic> change = {
        'type': DocumentChangeType.added,
        'oldIndex': -1,
        'newIndex': 123,
        'document': {'foo': 'bar'},
        'path': 'foo/bar',
      };

      return {
        'paths': ['foo/bar', 'bar/baz'],
        'documents': [
          {'foo', 'bar'},
          {'bar', 'baz'},
        ],
        'documentChanges': [change, change],
        'metadatas': [metadata, metadata],
        'metadata': metadata,
      };
    }

    return null;
  });

  Firestore firestore;

  group("$DocumentSnapshot", () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp();
      firestore = Firestore.instance;
    });

    test('returns the size (length) of documents', () async {
      QuerySnapshot snapshot = await firestore.collection('foo').get();
      expect(snapshot.size, equals(2));
    });

    test('returns SnapshotMetadata', () async {
      QuerySnapshot snapshot = await firestore.collection('foo').get();
      expect(snapshot.metadata, isA<SnapshotMetadata>());
      expect(snapshot.metadata.isFromCache, isFalse);
      expect(snapshot.metadata.hasPendingWrites, isFalse);
    });

    test('returns a List of QueryDocumentSnapshot', () async {
      QuerySnapshot snapshot = await firestore.collection('foo').get();
      expect(snapshot.documents, isA<List<QueryDocumentSnapshot>>());
      expect(snapshot.documents[0].data(), equals({'foo': 'bar'}));
      expect(snapshot.documents[1].data(), equals({'bar': 'baz'}));
    });

    test('returns a List of DocumentChange', () async {
      QuerySnapshot snapshot = await firestore.collection('foo').get();
      expect(snapshot.documents, isA<List<DocumentChange>>());
      expect(snapshot.documentChanges.length, equals(2));
    });
  });
}
