// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// The entry point for accessing a Firestore.
///
/// You can get an instance by calling [Firestore.instance]. The instance
/// can also be created with a secondary Firebase app by calling
/// [Firestore.instanceFor], for example:
///
/// ```dart
/// FirebaseApp secondaryApp = FirebaseCore.instance.app('SecondaryApp');
///
/// Firestore firestore = Firestore.instanceFor(app: secondaryApp);
/// ```
class Firestore extends FirebasePluginPlatform {
  // Cached and lazily loaded instance of [FirestorePlatform] to avoid
  // creating a [MethodChannelFirestore] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirestorePlatform _delegatePackingProperty;

  FirestorePlatform get _delegate {
    if (_delegatePackingProperty == null) {
      _delegatePackingProperty = FirestorePlatform.instanceFor(app: app);
    }
    return _delegatePackingProperty;
  }

  FirebaseApp app;

  Firestore._({this.app})
      : super(app.name, 'plugins.flutter.io/cloud_firestore');

  /// Returns an instance using the default [FirebaseApp].
  static Firestore get instance {
    return Firestore._(
      app: FirebaseCore.instance.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static Firestore instanceFor({FirebaseApp app}) {
    assert(app != null);
    return Firestore._(app: app);
  }

  @Deprecated(
      "Constructing Firestore is deprecated, use 'Firestore.instance' or 'Firestore.instanceFor' instead")
  factory Firestore({FirebaseApp app}) {
    return Firestore.instanceFor(app: app);
  }

  /// Gets a [CollectionReference] for the specified Firestore path.
  CollectionReference collection(String collectionPath) {
    assert(collectionPath != null, "a collection path cannot be null");
    assert(collectionPath.isNotEmpty,
        "a collectionPath path must be a non-empty string");
    assert(isValidCollectionPath(collectionPath),
        "a collection path must point to a valid collection.");

    return CollectionReference._(this, _delegate.collection(collectionPath));
  }

  @protected
  FirestorePlatform delegateFor({FirebaseApp app}) {
    throw UnimplementedError();
  }

  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// Unlike transactions, write batches are persisted offline and therefore are
  /// preferable when you don’t need to condition your writes on read data.
  WriteBatch batch() {
    return WriteBatch._(_delegate.batch());
  }

  // TODO docs
  Future<void> clearPersistence() {
    return _delegate.clearPersistence();
  }

  /// Gets a [Query] for the specified collection group.
  Query collectionGroup(String collectionPath) {
    assert(collectionPath != null, "a collection path cannot be null");
    assert(collectionPath.isNotEmpty,
        "a collection path must be a non-empty string");
    assert(!collectionPath.contains("/"),
        "a collection path passed to collectionGroup() cannot contain '/'");

    return Query._(this, _delegate.collectionGroup(collectionPath));
  }

  // TODO docs
  Future<void> disableNetwork() {
    return _delegate.disableNetwork();
  }

  /// Gets a [DocumentReference] for the specified Firestore path.
  DocumentReference document(String documentPath) {
    assert(documentPath != null, "a document path cannot be null");
    assert(
        documentPath.isNotEmpty, "a document path must be a non-empty string");
    assert(isValidDocumentPath(documentPath),
        "a document path must point to a valid document.");

    return DocumentReference._(this, _delegate.document(documentPath));
  }

  Future<void> enableNetwork() {
    return _delegate.enableNetwork();
  }

  Future<void> onSnapshotsInSync() {
    return _delegate.onSnapshotsInSync();
  }

  /// Executes the given TransactionHandler and then attempts to commit the
  /// changes applied within an atomic transaction.
  ///
  /// In the TransactionHandler, a set of reads and writes can be performed
  /// atomically using the Transaction object passed to the TransactionHandler.
  /// After the TransactionHandler is run, Firestore will attempt to apply the
  /// changes to the server. If any of the data read has been modified outside
  /// of this transaction since being read, then the transaction will be
  /// retried by executing the updateBlock again. If the transaction still
  /// fails after 5 retries, then the transaction will fail.
  ///
  /// The TransactionHandler may be executed multiple times, it should be able
  /// to handle multiple executions.
  ///
  /// Data accessed with the transaction will not reflect local changes that
  /// have not been committed. For this reason, it is required that all
  /// reads are performed before any writes. Transactions must be performed
  /// while online. Otherwise, reads will fail, and the final commit will fail.
  ///
  /// By default transactions are limited to 5 seconds of execution time. This
  /// timeout can be adjusted by setting the timeout parameter.
  Future<Map<String, dynamic>> runTransaction(
      TransactionHandler transactionHandler,
      {Duration timeout = const Duration(seconds: 5)}) {
    return _delegate.runTransaction(
        (transaction) => transactionHandler(Transaction._(this, transaction)),
        timeout: timeout);
  }

  Future<void> settings(Settings settings) {
    return _delegate.settings(settings);
  }

  Future<void> terminate() {
    // TODO: implement terminate
    throw UnimplementedError();
  }

  Future<void> waitForPendingWrites() {
    // TODO: implement waitForPendingWrites
    throw UnimplementedError();
  }

  @override
  bool operator ==(dynamic o) => o is Firestore && o.app.name == app.name;

  @override
  int get hashCode => hash2(app.name, app.options);

  @override
  String toString() => '$Firestore(app: ${app.name})';
}
