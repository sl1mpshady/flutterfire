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
class DocumentReference {
  DocumentReferencePlatform _delegate;

  /// The Firestore instance associated with this document reference.
  final Firestore firestore;

  DocumentReference._(this.firestore, this._delegate) {
    DocumentReferencePlatform.verifyExtends(_delegate);
  }

  /// This document's given ID within the collection.
  String get id => _delegate.id;

  @Deprecated("Deprecated in favor of 'id'")
  String get documentID => id;

  /// The parent [CollectionReference] of this document.
  CollectionReference get parent =>
      CollectionReference._(firestore, _delegate.parent);

  /// A string representing the path of the referenced document (relative to the root of the database).
  String get path => _delegate.path;

  /// Gets a [CollectionReference] instance that refers to the collection at the specified path.
  CollectionReference collection(String collectionPath) {
    return CollectionReference._(
        firestore, _delegate.collection(collectionPath));
  }

  /// Deletes the current document from the collection.
  Future<void> delete() => _delegate.delete();

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot> get([GetOptions options]) async {
    return DocumentSnapshot._(
        firestore, await _delegate.get(options ?? const GetOptions()));
  }

  /// Notifies of documents at this location
  Stream<DocumentSnapshot> snapshots({bool includeMetadataChanges = false}) =>
      _delegate.snapshots(includeMetadataChanges: includeMetadataChanges).map(
          (delegateSnapshot) =>
              DocumentSnapshot._(firestore, delegateSnapshot));

  /// Writes to the document referred to by this [DocumentReference].
  ///
  /// If the document does not yet exist, it will be created.
  ///
  /// If [SetOptions] are provided, the data will be merged into an existing
  /// document instead of overwriting.
  // TODO(ehesp): should this be `set()`?
  Future<void> setData(Map<String, dynamic> data, [SetOptions options]) {
    return _delegate.setData(
        _CodecUtility.replaceValueWithDelegatesInMap(data), options);
  }

  /// Updates fields in the document referred to by this [DocumentReference].
  ///
  /// Values in [data] may be of any supported Firestore type as well as
  /// special sentinel [FieldValue] type.
  ///
  /// If no document exists yet, the update will fail.
  // TODO(ehesp): should this be `update()`?
  Future<void> updateData(Map<String, dynamic> data) {
    return _delegate
        .updateData(_CodecUtility.replaceValueWithDelegatesInMap(data));
  }

  @override
  bool operator ==(dynamic o) =>
      o is DocumentReference && o.firestore == firestore && o.path == path;

  @override
  int get hashCode => hash2(firestore, path);

  @override
  String toString() => '$DocumentReference($path)';
}
