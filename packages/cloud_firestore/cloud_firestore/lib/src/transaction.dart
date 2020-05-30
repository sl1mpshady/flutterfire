// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// The [TransactionHandler] may be executed multiple times; it should be able
/// to handle multiple executions.
typedef Future<T> TransactionHandler<T>(Transaction transaction);

class Transaction {
  final Firestore _firestore;
  final TransactionPlatform _delegate;

  Transaction._(this._firestore, this._delegate) {
    TransactionPlatform.verifyExtends(_delegate);
  }

  Future<void> _commit() => _delegate.commit();

  /// Reads the document referenced by the provided DocumentReference.
  Future<DocumentSnapshot> get(DocumentReference documentReference) async {
    DocumentSnapshotPlatform documentSnapshotPlatform =
        await _delegate.get(documentReference.path);

    return DocumentSnapshot._(_firestore, documentSnapshotPlatform);
  }

  /// Deletes the document referred to by the provided [documentReference].
  ///
  /// Awaiting the returned [Future] is optional and will be done automatically
  /// when the transaction handler completes.
  Transaction delete(DocumentReference documentReference) {
    assert(documentReference != null);
    assert(documentReference.firestore == _firestore,
        "the document provided is from a different Firestore instance");

    return Transaction._(_firestore, _delegate.delete(documentReference.path));
  }

  /// Updates fields in the document referred to by [documentReference].
  /// The update will fail if applied to a document that does not exist.
  ///
  /// Awaiting the returned [Future] is optional and will be done automatically
  /// when the transaction handler completes.
  Transaction update(
      DocumentReference documentReference, Map<String, dynamic> data) {
    assert(documentReference != null);
    assert(data != null);
    assert(documentReference.firestore == _firestore,
        "the document provided is from a different Firestore instance");

    return Transaction._(
        _firestore,
        _delegate.update(documentReference.path,
            _CodecUtility.replaceValueWithDelegatesInMap(data)));
  }

  /// Writes to the document referred to by the provided [DocumentReference].
  /// If the document does not exist yet, it will be created. If you pass
  /// SetOptions, the provided data can be merged into the existing document.
  ///
  /// Awaiting the returned [Future] is optional and will be done automatically
  /// when the transaction handler completes.
  Transaction set(
      DocumentReference documentReference, Map<String, dynamic> data,
      [SetOptions options]) {
    assert(documentReference.firestore == _firestore,
        "the document provided is from a different Firestore instance");

    return Transaction._(
        _firestore,
        _delegate.set(documentReference.path,
            _CodecUtility.replaceValueWithDelegatesInMap(data), options));
  }
}
