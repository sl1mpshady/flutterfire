// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// The entry point for accessing a [Firestore].
///
/// You can get an instance by calling [Firestore.instance]. The instance
/// can also be created with a secondary [Firebase] app by calling
/// [Firestore.instanceFor], for example:
///
/// ```dart
/// FirebaseApp secondaryApp = Firebase.app('SecondaryApp');
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

  /// The [FirebaseApp] for this current [Firestore] instance.
  FirebaseApp app;

  Firestore._({this.app})
      : super(app.name, 'plugins.flutter.io/cloud_firestore');

  /// Returns an instance using the default [FirebaseApp].
  static Firestore get instance {
    return Firestore._(
      app: Firebase.app(),
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
    assert(!collectionPath.contains("//"),
        "a collection path must not contain '//'");
    assert(isValidCollectionPath(collectionPath),
        "a collection path must point to a valid collection.");

    return CollectionReference._(this, _delegate.collection(collectionPath));
  }

  /// Returns a [WriteBatch], used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// Unlike [Transaction]s, [WriteBatch]es are persisted offline and therefore are
  /// preferable when you don’t need to condition your writes on read data.
  WriteBatch batch() {
    return WriteBatch._(this, _delegate.batch());
  }

  /// Clears any persisted data for the current instance.
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

  /// Instructs [Firestore] to disable the network for the instance.
  ///
  /// Once disabled, any writes will only resolve once connection has been
  /// restored. However, the local database will still be updated and any
  /// listeners will still trigger.
  Future<void> disableNetwork() {
    return _delegate.disableNetwork();
  }

  /// Gets a [DocumentReference] for the specified Firestore path.
  DocumentReference doc(String documentPath) {
    assert(documentPath != null, "a document path cannot be null");
    assert(
        documentPath.isNotEmpty, "a document path must be a non-empty string");
    assert(!documentPath.contains("//"),
        "a collection path must not contain '//'");
    assert(isValidDocumentPath(documentPath),
        "a document path must point to a valid document.");

    return DocumentReference._(this, _delegate.doc(documentPath));
  }

  @Deprecated("Deprecated in favor of `.doc()`")
  DocumentReference document(String documentPath) => doc(documentPath);

  /// Enables the network for this instance. Any pending local-only writes
  /// will be written to the remote servers.
  Future<void> enableNetwork() {
    return _delegate.enableNetwork();
  }

  /// Returns a [Stream] which is called each time all of the active listeners
  /// have been synchronised.
  Stream<void> snapshotsInSync() {
    return _delegate.snapshotsInSync();
  }

  /// Executes the given [TransactionHandler] and then attempts to commit the
  /// changes applied within an atomic transaction.
  ///
  /// In the [TransactionHandler], a set of reads and writes can be performed
  /// atomically using the [Transaction] object passed to the [TransactionHandler].
  /// After the [TransactionHandler] is run, [Firestore] will attempt to apply the
  /// changes to the server. If any of the data read has been modified outside
  /// of this [Transaction] since being read, then the transaction will be
  /// retried by executing the `updateBlock` again. If the transaction still
  /// fails after 5 retries, then the transaction will fail.s
  ///
  /// The [TransactionHandler] may be executed multiple times, it should be able
  /// to handle multiple executions.
  ///
  /// Data accessed with the transaction will not reflect local changes that
  /// have not been committed. For this reason, it is required that all
  /// reads are performed before any writes. Transactions must be performed
  /// while online. Otherwise, reads will fail, and the final commit will fail.
  ///
  /// By default transactions are limited to 5 seconds of execution time. This
  /// timeout can be adjusted by setting the timeout parameter.
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
      {Duration timeout = const Duration(seconds: 5)}) {
    assert(transactionHandler != null, "transactionHandler cannot be null");
    return _delegate.runTransaction<T>((transaction) {
      return transactionHandler(Transaction._(this, transaction));
    }, timeout: timeout);
  }

  /// Instructs the current [Firestore] instance to use the provided [settings].
  ///
  /// If the instance has already been consumed, the settings will take effect
  /// the next time it is created.
  Future<void> settings(Settings settings) {
    return _delegate.settings(settings);
  }

  /// Terminates this [Firestore] instance.
  ///
  /// After calling [terminate()] only the [clearPersistence()] method may be used.
  /// Any other method will throw a [FirebaseException].
  ///
  /// Termination does not cancel any pending writes, and any promises that are
  /// awaiting a response from the server will not be resolved. If you have
  /// persistence enabled, the next time you start this instance, it will resume
  ///  sending these writes to the server.
  ///
  /// Note: Under normal circumstances, calling [terminate()] is not required.
  /// This method is useful only when you want to force this instance to release
  ///  all of its resources or in combination with [clearPersistence()] to ensure
  ///  that all local state is destroyed between test runs.
  Future<void> terminate() {
    return _delegate.terminate();
  }

  /// Waits until all currently pending writes for the active user have been
  /// acknowledged by the backend.
  ///
  /// The returned Future resolves immediately if there are no outstanding writes.
  /// Otherwise, the Promise waits for all previously issued writes (including
  /// those written in a previous app session), but it does not wait for writes
  /// that were added after the method is called. If you want to wait for
  /// additional writes, call [waitForPendingWrites] again.
  ///
  /// Any outstanding [waitForPendingWrites] calls are rejected during user changes.
  Future<void> waitForPendingWrites() {
    return _delegate.waitForPendingWrites();
  }

  @override
  bool operator ==(dynamic o) => o is Firestore && o.app.name == app.name;

  @override
  int get hashCode => hash2(app.name, app.options);

  @override
  String toString() => '$Firestore(app: ${app.name})';
}
