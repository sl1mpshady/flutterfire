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
import 'utils/exception.dart';

/// The entry point for accessing a Firestore.
///
/// You can get an instance by calling [Firestore.instance].
class MethodChannelFirestore extends FirestorePlatform {
  /// Create an instance of [MethodChannelFirestore] with optional [FirebaseApp]
  MethodChannelFirestore({FirebaseApp app})
      : assert(app != null),
        super(app: app) {
    if (_initialized) return;
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'Firestore#snapshotsInSync':
          await _handleSnapshotsInSync(call.arguments);
          break;
        case 'Firestore#QuerySnapshot':
          await _handleQuerySnapshot(call.arguments);
          break;
        case 'Firestore#QuerySnapshotError':
          await _handleQuerySnapshotError(call.arguments);
          break;
        case 'Firestore#DocumentSnapshot':
          await _handleDocumentSnapshot(call.arguments);
          break;
        case 'Firestore#DocumentSnapshotError':
          await _handleDocumentSnapshotError(call.arguments);
          break;
        case 'Transaction#attempt':
          return _handleTransactionAttempt(call.arguments);
          break;
        default:
          throw FallThroughError();
      }
    });
    _initialized = true;
  }

  void _handleSnapshotsInSync(Map<dynamic, dynamic> arguments) async {
    snapshotInSyncObservers[arguments['handle']].add(null);
  }

  /// When a [QuerySnapshot] event is fired on the [MethodChannel],
  /// add a [MethodChannelQuerySnapshot] to the [StreamController].
  void _handleQuerySnapshot(Map<dynamic, dynamic> arguments) async {
    queryObservers[arguments['handle']]
        .add(MethodChannelQuerySnapshot(this, arguments['snapshot']));
  }

  /// When a [QuerySnapshot] error event is fired on the [MethodChannel],
  /// send the [StreamController] the arguments to throw a [FirebaseException].
  void _handleQuerySnapshotError(Map<dynamic, dynamic> arguments) {
    _handleError(queryObservers[arguments['handle']], arguments);
  }

  /// When a [DocumentSnapshot] event is fired on the [MethodChannel],
  /// add a [DocumentSnapshotPlatform] to the [StreamController].
  void _handleDocumentSnapshot(Map<dynamic, dynamic> arguments) async {
    Map<String, dynamic> snapshotMap =
        Map<String, dynamic>.from(arguments['snapshot']);
    final DocumentSnapshotPlatform snapshot = DocumentSnapshotPlatform(
      this,
      snapshotMap['path'],
      <String, dynamic>{
        'data': snapshotMap['data'],
        'metadata': snapshotMap['metadata'],
      },
    );

    documentObservers[arguments['handle']].add(snapshot);
  }

  /// When a [DocumentSnapshot] error event is fired on the [MethodChannel],
  /// send the [StreamController] the arguments to throw a [FirebaseException].
  void _handleDocumentSnapshotError(Map<dynamic, dynamic> arguments) {
    _handleError(documentObservers[arguments['handle']], arguments);
  }

  /// When a transaction is attempted, it sends a [MethodChannel] call.
  /// The user handler is executed, and the result or error is emitted via
  /// a stream to the [runTransaction] handler. Once the handler has completed,
  /// a response to continue (with commands) or abort the transaction is sent.
  Future<Map<String, dynamic>> _handleTransactionAttempt(
      Map<dynamic, dynamic> arguments) async {
    final int transactionId = arguments['transactionId'];
    final TransactionPlatform transaction =
        MethodChannelTransaction(transactionId, arguments["appName"]);
    final StreamController controller =
        _transactionStreamControllerHandlers[transactionId];

    try {
      dynamic result = await _transactionHandlers[transactionId](transaction);

      // Broadcast the result. This allows the [runTransaction] handler to update
      // the current result. We can't send the result to native, since in some
      // cases it could be a non-primitive which would lose it's context (e.g.
      // returning a [DocumentSnapshot]).
      // If the transaction re-runs, the result will be updated.
      controller.add(result);

      // Once the user Future has completed, send the commands to native
      // to process the transaction.
      return <String, dynamic>{
        'type': 'SUCCESS',
        'commands': transaction.commands,
      };
    } catch (error) {
      // Allow the [runTransaction] method to listen to an error.
      controller.addError(error);

      // Signal native that a user error occurred, and finish the
      // transaction
      return <String, dynamic>{
        'type': 'ERROR',
      };
    }
  }

  /// Attach a [FirebaseException] to a given [StreamController].
  void _handleError(
      StreamController controller, Map<dynamic, dynamic> arguments) async {
    assert(controller != null);
    Map<String, dynamic> errorMap =
        Map<String, dynamic>.from(arguments['error']);

    FirebaseException exception = FirebaseException(
      plugin: 'cloud_firestore',
      code: errorMap['code'],
      message: errorMap['message'],
    );
    controller.addError(exception);
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

  static final Map<int, StreamController<void>> snapshotInSyncObservers =
      <int, StreamController<void>>{};

  /// Stores the users [TransactionHandlers] for usage when a transaction is
  /// running.
  static final Map<int, TransactionHandler> _transactionHandlers =
      <int, TransactionHandler>{};

  /// Stores a transactions [StreamController]
  static final Map<int, StreamController> _transactionStreamControllerHandlers =
      <int, StreamController>{};

  /// A locally stored index of the transactions. This is incrememented each
  /// time a user calls [runTransaction].
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
    await channel
        .invokeMethod<void>('Firestore#clearPersistence')
        .catchError(catchPlatformException);
  }

  @override
  CollectionReferencePlatform collection(String path) {
    return MethodChannelCollectionReference(this, path);
  }

  @override
  QueryPlatform collectionGroup(String path) {
    return MethodChannelQuery(this, path, isCollectionGroup: true);
  }

  @override
  Future<void> disableNetwork() async {
    await channel
        .invokeMethod<void>('Firestore#disableNetwork', <String, String>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  DocumentReferencePlatform document(String path) {
    return MethodChannelDocumentReference(this, path);
  }

  @override
  Future<void> enableNetwork() async {
    await channel
        .invokeMethod<void>('Firestore#enableNetwork', <String, String>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Stream<void> snapshotsInSync() {
    Future<int> _handle;

    StreamController<QuerySnapshotPlatform> controller; // ignore: close_sinks
    controller = StreamController<QuerySnapshotPlatform>.broadcast(
      onListen: () {
        _handle = MethodChannelFirestore.channel.invokeMethod<int>(
          'Firestore#addSnapshotsInSyncListener',
          <String, dynamic>{
            'appName': app.name,
          },
        ).then<int>((dynamic result) => result);
        _handle.then((int handle) {
          MethodChannelFirestore.snapshotInSyncObservers[handle] = controller;
        });
      },
      onCancel: () {
        _handle.then((int handle) async {
          await MethodChannelFirestore.channel.invokeMethod<void>(
            'Firestore#removeListener',
            <String, dynamic>{'handle': handle},
          );
          MethodChannelFirestore.snapshotInSyncObservers.remove(handle);
        });
      },
    );
    return controller.stream;
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler transactionHandler, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    assert(timeout.inMilliseconds > 0,
        'Transaction timeout must be more than 0 milliseconds');

    final int transactionId = _transactionHandlerId++;
    StreamController streamController = StreamController();

    _transactionHandlers[transactionId] = transactionHandler;
    _transactionStreamControllerHandlers[transactionId] = streamController;

    T result;
    Object exception;

    // If the uses [TransactionHandler] throws an error, the stream broadcasts
    // it so we don't lose it's context.
    StreamSubscription subscription =
        streamController.stream.listen((Object data) {
      result = data;
    }, onError: (Object e) {
      exception = e;
    });

    await channel.invokeMethod<T>('Transaction#create', <String, dynamic>{
      'appName': app.name,
      'transactionId': transactionId,
      'timeout': timeout.inMilliseconds
    }).catchError((Object e) {
      exception = e;
    });

    // The transaction is successful, cleanup the stream
    await subscription.cancel();
    _transactionStreamControllerHandlers.remove(transactionId);

    if (exception != null) {
      if (exception is PlatformException) {
        return Future.error(platformExceptionToFirebaseException(exception));
      } else {
        return Future.error(exception);
      }
    }

    return result;
  }

  @override
  Future<void> settings(Settings settings) async {
    await channel.invokeMethod<void>('Firestore#settings', <String, dynamic>{
      'appName': app.name,
      'settings': settings.asMap,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> terminate() async {
    await channel.invokeMethod<void>('Firestore#terminate', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> waitForPendingWrites() async {
    await channel
        .invokeMethod<void>('Firestore#waitForPendingWrites', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }
}
