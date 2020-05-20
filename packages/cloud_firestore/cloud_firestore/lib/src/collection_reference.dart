// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A CollectionReference object can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [Query]).
// todo extend query once ready
//class CollectionReference implements CollectionReferencePlatform {
class CollectionReference  {
//  final CollectionReferencePlatform _delegate;
//
//  CollectionReference._(Firestore firestore, this._delegate) {
//    // TODO(ehesp): Should this verify extends of QueryPlatform?
//  }
//
//  /// ID of the referenced collection.
//  String get id => _delegate.id;
//
//  /// A string containing the slash-separated path to this  CollectionReference
//  /// (relative to the root of the database).
////  String get path => _delegate.path;
//  // TODO(ehesp): Fix once query is implemented
//  String get path => 'TODO';
//
//  /// For subcollections, parent returns the containing [DocumentReference].
//  ///
//  /// For root collections, null is returned.
//  DocumentReference get parent {
//    return DocumentReference._(firestore, _delegate.parent);
//  }
//
//  /// Returns a `DocumentReference` with the provided path.
//  ///
//  /// If no [path] is provided, an auto-generated ID is used.
//  ///
//  /// The unique key generated is prefixed with a client-generated timestamp
//  /// so that the resulting list will be chronologically-sorted.
//  DocumentReference document([String path]) =>
//      DocumentReference._(firestore, _delegate.document(path));
//
//  /// Returns a `DocumentReference` with an auto-generated ID, after
//  /// populating it with provided [data].
//  ///
//  /// The unique key generated is prefixed with a client-generated timestamp
//  /// so that the resulting list will be chronologically-sorted.
//  Future<DocumentReference> add(Map<String, dynamic> data) async {
//    final DocumentReference newDocument = document();
//    await newDocument.setData(data);
//    return newDocument;
//  }
}
