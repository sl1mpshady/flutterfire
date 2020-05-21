// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A DocumentSnapshot contains data read from a document in your Firestore
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
class DocumentSnapshot {
  final Firestore _firestore;
  final DocumentSnapshotPlatform _delegate;

  DocumentSnapshot._(this._firestore, this._delegate) {
    DocumentSnapshotPlatform.verifyExtends(_delegate);
  }

  String get id => _delegate.id;

  DocumentReference get reference =>
      _firestore.document(_delegate.reference.path);

  /// Metadata about this snapshot concerning its source and if it has local
  /// modifications.
  SnapshotMetadata get metadata => SnapshotMetadata._(_delegate.metadata);

  /// Returns `true` if the document exists.
  bool get exists => data != null;

  /// Contains all the data of this snapshot.
  Map<String, dynamic> data() {
    // TODO(ehesp): Handle SnapshotOptions options:
    return _CodecUtility.replaceDelegatesWithValueInMap(
        _delegate.data(), _firestore);
  }

  // TODO(ehesp): Confirm whether this is needed here - can the he platform interface can handle it
  dynamic operator [](String key) => data()[key];
}
