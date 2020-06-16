// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/method_channel_firestore.dart';

/// Defines an interface to work with [FirestorePlatform] on web and mobile
abstract class FirestorePlatform extends PlatformInterface {
  /// The [FirebaseApp] this instance was initialized with.
  @protected
  final FirebaseApp appInstance;

  /// Create an instance using [app]
  FirestorePlatform({this.appInstance}) : super(token: _token);

  /// Returns the [FirebaseApp] for the current instance.
  FirebaseApp get app {
    if (appInstance == null) {
      return Firebase.app();
    }

    return appInstance;
  }

  static final Object _token = Object();

  /// Create an instance using [app] using the existing implementation
  factory FirestorePlatform.instanceFor({FirebaseApp app}) {
    return FirestorePlatform.instance.delegateFor(app: app);
  }

  /// The current default [FirestorePlatform] instance.
  ///
  /// It will always default to [MethodChannelFirestore]
  /// if no other implementation was provided.
  static FirestorePlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirestore(app: Firebase.app());
    }
    return _instance;
  }

  static FirestorePlatform _instance;

  /// Sets the [FirestorePlatform.instance]
  static set instance(FirestorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance is required by the user.
  @protected
  FirestorePlatform delegateFor({FirebaseApp app}) {
    throw UnimplementedError('delegateFor() is not implemented');
  }

  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// Unlike transactions, write batches are persisted offline and therefore are
  /// preferable when you don’t need to condition your writes on read data.
  WriteBatchPlatform batch() {
    throw UnimplementedError('batch() is not implemented');
  }

  /// Clears any persisted data for the current instance.
  Future<void> clearPersistence() {
    throw UnimplementedError('clearPersistence() is not implemented');
  }

  /// Gets a [CollectionReferencePlatform] for the specified Firestore path.
  CollectionReferencePlatform collection(String collectionPath) {
    throw UnimplementedError('collection() is not implemented');
  }

  /// Gets a [QueryPlatform] for the specified collection group.
  QueryPlatform collectionGroup(String collectionPath) {
    throw UnimplementedError('collectionGroup() is not implemented');
  }

  /// Disables network usage for this instance. It can be re-enabled via
  /// enableNetwork(). While the network is disabled, any snapshot listeners or
  /// get() calls will return results from cache, and any write operations will
  /// be queued until the network is restored.
  Future<void> disableNetwork() {
    throw UnimplementedError('disableNetwork() is not implemented');
  }

  /// Gets a [DocumentReferencePlatform] for the specified Firestore path.
  DocumentReferencePlatform doc(String documentPath) {
    throw UnimplementedError('doc() is not implemented');
  }

  /// Re-enables use of the network for this Firestore instance after a prior
  /// call to disableNetwork().
  Future<void> enableNetwork() {
    throw UnimplementedError('enableNetwork() is not implemented');
  }

  /// Returns a [Steam] which is called each time all of the active listeners
  /// have been synchronised.
  Stream<void> snapshotsInSync() {
    throw UnimplementedError('onSnapshotsInSync() is not implemented');
  }

  /// Executes the given [TransactionHandler] and then attempts to commit the
  /// changes applied within an atomic transaction.
  ///
  /// In the [TransactionHandler], a set of reads and writes can be performed
  /// atomically using the [MethodChannelTransaction] object passed to the [TransactionHandler].
  /// After the [TransactionHandler] is run, Firestore will attempt to apply the
  /// changes to the server. If any of the data read has been modified outside
  /// of this transaction since being read, then the transaction will be
  /// retried by executing the updateBlock again. If the transaction still
  /// fails after 5 retries, then the transaction will fail.
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
  /// timeout can be adjusted by setting the [timeout] parameter.
  Future<T> runTransaction<T>(TransactionHandler transactionHandler,
      {Duration timeout = const Duration(seconds: 5)}) {
    throw UnimplementedError('runTransaction() is not implemented');
  }

  /// Setup [FirestorePlatform] with settings.
  ///
  /// If [sslEnabled] has a non-null value, the [host] must have non-null value as well.
  ///
  /// If [cacheSizeBytes] is `null`, then default values are used.
  Future<void> settings(Settings settings) {
    throw UnimplementedError('settings() is not implemented');
  }

  /// Terminates this Firestore instance.
  ///
  /// After calling terminate() only the clearPersistence() method may be used.
  /// Any other method will throw a [FirebaseException].
  ///
  /// Termination does not cancel any pending writes, and any promises that are
  /// awaiting a response from the server will not be resolved. If you have
  /// persistence enabled, the next time you start this instance, it will resume
  ///  sending these writes to the server.
  ///
  /// Note: Under normal circumstances, calling terminate() is not required.
  /// This method is useful only when you want to force this instance to release
  ///  all of its resources or in combination with clearPersistence() to ensure
  ///  that all local state is destroyed between test runs.
  Future<void> terminate() {
    throw UnimplementedError('terminate() is not implemented');
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
    throw UnimplementedError('waitForPendingWrites() is not implemented');
  }

  @override
  bool operator ==(dynamic o) =>
      o is FirestorePlatform && o.app.name == app.name;

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$FirestorePlatform(app: ${app.name})';
}
