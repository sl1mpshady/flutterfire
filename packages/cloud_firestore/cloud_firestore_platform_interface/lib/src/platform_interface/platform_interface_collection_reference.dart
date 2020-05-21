// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

/// A CollectionReference object can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [QueryPlatform]).
/// Note: QueryPlatform extends PlatformInterface already.
abstract class CollectionReferencePlatform extends QueryPlatform {
  final Pointer _pointer;

  /// Create a [CollectionReferencePlatform] using [pathComponents]
  CollectionReferencePlatform(
    FirestorePlatform firestore,
    this._pointer,
  ) : super(firestore);

  /// Identifier of the referenced collection.
  String get id => _pointer.id;

  /// For subcollections, parent returns the containing [DocumentReferencePlatform].
  ///
  /// For root collections, `null` is returned.
  DocumentReferencePlatform get parent {
    String parentPath = _pointer.parentPath();

    if (parentPath == null) {
      return null;
    }

    return firestore.document(parentPath);
  }

  /// A string containing the slash-separated path to this [CollectionReferencePlatform]
  /// (relative to the root of the database).
  String get path => _pointer.path;

  /// Returns a `DocumentReference` with the provided path.
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  DocumentReferencePlatform document([String path]) {
    throw UnimplementedError("document() is not implemented");
  }

  /// Returns a `DocumentReference` with an auto-generated ID, after
  /// populating it with provided [data].
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  Future<DocumentReferencePlatform> add(Map<String, dynamic> data) async {
    throw UnimplementedError("add() is not implemented");
  }
}
