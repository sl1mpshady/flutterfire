// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A CollectionReference object can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [Query]).
class CollectionReference extends Query {
  final CollectionReferencePlatform _delegate;

  CollectionReference._(Firestore firestore, this._delegate)
      : super._(firestore, _delegate);

  /// ID of the referenced collection.
  String get id => _delegate.id;

  /// For subcollections, parent returns the containing [DocumentReference].
  ///
  /// For root collections, null is returned.
  DocumentReference get parent {
    DocumentReferencePlatform _documentReferencePlatform = _delegate.parent;
    
    // Only subcollections have a parent
    if (_documentReferencePlatform == null) {
      return null;
    }
  
    return DocumentReference._(firestore, _documentReferencePlatform);
  }

  /// A string containing the slash-separated path to this  CollectionReference
  /// (relative to the root of the database).
  String get path => _delegate.path;

  /// Returns a `DocumentReference` with an auto-generated ID, after
  /// populating it with provided [data].
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final DocumentReference newDocument = document();
    await newDocument.setData(data);
    return newDocument;
  }

  /// Returns a `DocumentReference` with the provided path.
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  DocumentReference document([String path]) =>
      DocumentReference._(firestore, _delegate.document(path));

  @override
  bool operator ==(dynamic o) =>
      o is CollectionReference &&
      o.firestore == firestore &&
      o.path == path;

  @override
  int get hashCode => hash2(firestore, path);

  @override
  String toString() => '$CollectionReference($path)';
}
