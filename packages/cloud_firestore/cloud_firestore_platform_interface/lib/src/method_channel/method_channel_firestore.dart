// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_collection_reference.dart';
import 'method_channel_document_reference.dart';
import 'method_channel_query.dart';
import 'method_channel_query_snapshot.dart';
import 'method_channel_transaction.dart';
import 'method_channel_write_batch.dart';
import 'utils/firestore_message_codec.dart';
import 'utils/maps.dart';

/// The entry point for accessing a Firestore.
///
/// You can get an instance by calling [Firestore.instance].
class MethodChannelFirestore extends FirestorePlatform {
  /// Create an instance of [MethodChannelFirestore] with optional [FirebaseApp]
  MethodChannelFirestore({FirebaseApp app})
      : assert(app != null),
        super(app: app) {
    if (_initialized) return;
//    channel.setMethodCallHandler((MethodCall call) async {
//      if (call.method == 'QuerySnapshot') {
//        final QuerySnapshotPlatform snapshot =
//            MethodChannelQuerySnapshot(call.arguments, this);
//        queryObservers[call.arguments['handle']].add(snapshot);
//      } else if (call.method == 'DocumentSnapshot') {
//        final DocumentSnapshotPlatform snapshot = DocumentSnapshotPlatform(
//          call.arguments['path'],
//          asStringKeyedMap(call.arguments['data']),
//          SnapshotMetadataPlatform(
//              call.arguments['metadata']['hasPendingWrites'],
//              call.arguments['metadata']['isFromCache']),
//          this,
//        );
//        documentObservers[call.arguments['handle']].add(snapshot);
//      } else if (call.method == 'DoTransaction') {
//        final int transactionId = call.arguments['transactionId'];
//        final TransactionPlatform transaction =
//            MethodChannelTransaction(transactionId, call.arguments["app"]);
//        final dynamic result =
//            await _transactionHandlers[transactionId](transaction);
//        await transaction.finish();
//        return result;
//      }
//    });
    _initialized = true;
  }

  /// The [FirebaseApp] instance to which this [FirebaseDatabase] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.

  static bool _initialized = false;

  /// The [MethodChannel] used to communicate with the native plugin
  static MethodChannel channel = MethodChannel(
    'plugins.flutter.io/cloud_firestore',
    StandardMethodCodec(FirestoreMessageCodec()),
  );

  /// A map containing all the pending Query Observers, keyed by their id.
  /// This is shared amongst all [MethodChannelQuery] objects, and the `QuerySnapshot`
  /// `MethodCall` handler initialized in the constructor of this class.
  static final Map<int, StreamController<QuerySnapshotPlatform>>
      queryObservers = <int, StreamController<QuerySnapshotPlatform>>{};

  /// A map containing all the pending Document Observers, keyed by their id.
  /// This is shared amongst all [MethodChannelDocumentReference] objects, and the
  /// `DocumentSnapshot` `MethodCall` handler initialized in the constructor of this class.
  static final Map<int, StreamController<DocumentSnapshotPlatform>>
      documentObservers = <int, StreamController<DocumentSnapshotPlatform>>{};

  static final Map<int, TransactionHandler> _transactionHandlers =
      <int, TransactionHandler>{};
  static int _transactionHandlerId = 0;

  /// Gets a [FirestorePlatform] with specific arguments such as a different
  /// [FirebaseApp].
  @override
  FirestorePlatform delegateFor({FirebaseApp app}) {
    return MethodChannelFirestore(app: app);
  }

  @override
  WriteBatchPlatform batch() => MethodChannelWriteBatch(this);

  @override
  Future<void> clearPersistence() async {
    await channel.invokeMethod<void>('Firestore#clearPersistence');
  }

  @override
  CollectionReferencePlatform collection(String path) {
    return MethodChannelCollectionReference(this, path);
  }

  @override
  QueryPlatform collectionGroup(String path) {
//    return MethodChannelQuery(this, Pointer(path), isCollectionGroup: true);
  }

  @override
  Future<void> disableNetwork() async {
    await channel.invokeMethod<void>('Firestore#disableNetwork');
  }

  @override
  DocumentReferencePlatform document(String path) {
    return MethodChannelDocumentReference(this, path);
  }

  @override
  Future<void> enableNetwork() async {
    await channel.invokeMethod<void>('Firestore#enableNetwork');
  }

  @override
  Future<Map<String, dynamic>> runTransaction(
    TransactionHandler transactionHandler, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    assert(timeout.inMilliseconds > 0,
        'Transaction timeout must be more than 0 milliseconds');
    final int transactionId = _transactionHandlerId++;
    _transactionHandlers[transactionId] = transactionHandler;
    final Map<String, dynamic> result = await channel
        .invokeMapMethod<String, dynamic>(
            'Firestore#runTransaction', <String, dynamic>{
      'app': app.name,
      'transactionId': transactionId,
      'transactionTimeout': timeout.inMilliseconds
    });
    return result ?? <String, dynamic>{};
  }

  @override
  Future<void> settings(Settings settings) async {
    await channel.invokeMethod<void>('Firestore#settings', settings.asMap);
  }
}
