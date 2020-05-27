// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase/firestore.dart' as web;

import 'package:cloud_firestore_web/src/collection_reference_web.dart';
import 'package:cloud_firestore_web/src/utils/document_reference_utils.dart';
import 'package:cloud_firestore_web/src/utils/codec_utility.dart';

/// Web implementation for firestore [DocumentReferencePlatform]
class DocumentReferenceWeb extends DocumentReferencePlatform {
  /// instance of Firestore from the web plugin
  final web.Firestore firestoreWeb;

  /// instance of DocumentReference from the web plugin
  final web.DocumentReference _delegate;

  /// Creates an instance of [CollectionReferenceWeb] which represents path
  /// at [pathComponents] and uses implementation of [firestoreWeb]
  DocumentReferenceWeb(
    FirestorePlatform firestore,
    this.firestoreWeb,
    String path,
  )   : _delegate = firestoreWeb.doc(path),
        super(firestore, path);

  @override
  Future<void> setData(Map<String, dynamic> data, [SetOptions options]) =>
      _delegate.set(
        CodecUtility.encodeMapData(data),
        // TODO(ehesp): `mergeFields` missing from web implementation
        web.SetOptions(merge: options.merge),
      );

  @override
  Future<void> updateData(Map<String, dynamic> data) =>
      _delegate.update(data: CodecUtility.encodeMapData(data));

  @override
  Future<DocumentSnapshotPlatform> get([GetOptions options]) async {
    // TODO(ehesp): web implementation not handling options
    return fromWebDocumentSnapshotToPlatformDocumentSnapshot(
        await _delegate.get(), this.firestore);
  }

  @override
  Future<void> delete() => _delegate.delete();

  @override
  Stream<DocumentSnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
  }) {
    Stream<web.DocumentSnapshot> querySnapshots = _delegate.onSnapshot;
    if (includeMetadataChanges) {
      querySnapshots = _delegate.onMetadataChangesSnapshot;
    }
    return querySnapshots.map((webSnapshot) =>
        fromWebDocumentSnapshotToPlatformDocumentSnapshot(
            webSnapshot, this.firestore));
  }
}
