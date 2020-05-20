// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [DocumentReference] refers to a document location in a Firestore database
/// and can be used to write, read, or listen to the location.
///
/// The document at the referenced location may or may not exist.
/// A [DocumentReference] can also be used to create a [CollectionReference]
/// to a subcollection.
class DocumentReference implements DocumentReferencePlatform {
  DocumentReferencePlatform _delegate;

  /// The Firestore instance associated with this document reference
  final Firestore firestore;

  DocumentReference._(this.firestore, this._delegate) {
    DocumentReferencePlatform.verifyExtends(_delegate);
  }

//  @override
//  CollectionReference collection(String collectionPath) {
//    return _delegate.collection(collectionPath);
//  }

  @override
  String get id => _delegate.id;

//  @override
//  CollectionReference get parent => _delegate.parent;

  @override
  String get path => _delegate.path;

  /// Deletes the document referred to by this [DocumentReference].
  Future<void> delete() => _delegate.delete();

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// If no document exists, the read will return null.
  @override
  Future<DocumentSnapshot> get({
    Source source = Source.serverAndCache,
  }) async {
    return DocumentSnapshot._(firestore, await _delegate.get(source: source));
  }

  /// Notifies of documents at this location
  @override
  Stream<DocumentSnapshot> snapshots({bool includeMetadataChanges = false}) =>
      _delegate.snapshots(includeMetadataChanges: includeMetadataChanges).map(
          (delegateSnapshot) =>
              DocumentSnapshot._(firestore, delegateSnapshot));

  /// Writes to the document referred to by this [DocumentReference].
  ///
  /// If the document does not yet exist, it will be created.
  ///
  /// If [merge] is true, the provided data will be merged into an
  /// existing document instead of overwriting.
  @override
  Future<void> setData(Map<String, dynamic> data, {bool merge = false}) {
    return _delegate.setData(_CodecUtility.replaceValueWithDelegatesInMap(data),
        merge: merge);
  }

  /// Updates fields in the document referred to by this [DocumentReference].
  ///
  /// Values in [data] may be of any supported Firestore type as well as
  /// special sentinel [FieldValue] type.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateData(Map<String, dynamic> data) {
    return _delegate
        .updateData(_CodecUtility.replaceValueWithDelegatesInMap(data));
  }

  @override
  bool operator ==(dynamic o) =>
      o is DocumentReference && o.firestore == firestore && o.path == path;

  @override
  int get hashCode => _delegate.path.hashCode;

  @override
  String toString() => '$DocumentReference($path)';
}
