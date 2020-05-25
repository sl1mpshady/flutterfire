// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as web;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:cloud_firestore_web/src/collection_reference_web.dart';
import 'package:cloud_firestore_web/src/field_value_factory_web.dart';
import 'package:cloud_firestore_web/src/document_reference_web.dart';
import 'package:cloud_firestore_web/src/query_web.dart';
import 'package:cloud_firestore_web/src/transaction_web.dart';
import 'package:cloud_firestore_web/src/write_batch_web.dart';

/// Web implementation for [FirestorePlatform]
/// delegates calls to firestore web plugin
class FirestoreWeb extends FirestorePlatform {
  /// instance of Firestore from the web plugin
  final web.Firestore _webFirestore;

  /// Called by PluginRegistry to register this plugin for Flutter Web
  static void registerWith(Registrar registrar) {
    FirestorePlatform.instance = FirestoreWeb(app: FirebaseCore.instance.app());
  }

  /// Builds an instance of [CloudFirestoreWeb] with an optional [FirebaseApp] instance
  /// If [app] is null then the created instance will use the default [FirebaseApp]
  FirestoreWeb({FirebaseApp app})
      : assert(app != null),
        _webFirestore = firebase.firestore(firebase.app(app.name)),
        super(app: app) {
    FieldValueFactoryPlatform.instance = FieldValueFactoryWeb();
  }

  @override
  FirestorePlatform delegateFor({FirebaseApp app}) {
    return FirestoreWeb(app: app);
  }

  @override
  CollectionReferencePlatform collection(String path) {
    return CollectionReferenceWeb(this, _webFirestore, path);
  }

  @override
  QueryPlatform collectionGroup(String path) {
    return QueryWeb(this, path, _webFirestore.collectionGroup(path),
        isCollectionGroup: true);
  }

  @override
  DocumentReferencePlatform document(String path) =>
      DocumentReferenceWeb(this, _webFirestore, path);

  @override
  WriteBatchPlatform batch() => WriteBatchWeb(_webFirestore.batch());

  @override
  Future<void> enablePersistence(bool enable) async {
    if (enable) {
      await _webFirestore.enablePersistence();
    }
  }

  @override
  Future<void> settings(Settings settings) async {
    int cacheSizeBytes;

    if (settings.cacheSizeBytes == null) {
      cacheSizeBytes = 40000000;
    } else if (settings.cacheSizeBytes == CACHE_SIZE_UNLIMITED) {
      // https://github.com/firebase/firebase-js-sdk/blob/e67affba53a53d28492587b2f60521a00166db60/packages/firestore/src/local/lru_garbage_collector.ts#L175
      cacheSizeBytes = -1;
    } else {
      cacheSizeBytes = settings.cacheSizeBytes;
    }

    if (settings.host != null && settings.sslEnabled != null) {
      _webFirestore.settings(web.Settings(
          cacheSizeBytes: cacheSizeBytes,
          host: settings.host,
          ssl: settings.sslEnabled));
    } else {
      _webFirestore.settings(web.Settings(cacheSizeBytes: cacheSizeBytes));
    }

    if (settings.persistenceEnabled) {
      await _webFirestore.enablePersistence();
    }
  }

  @override
  Future<Map<String, dynamic>> runTransaction(
      TransactionHandler transactionHandler,
      {Duration timeout = const Duration(seconds: 5)}) async {
    Map<String, dynamic> result;
    await _webFirestore.runTransaction((transaction) async {
      result = await transactionHandler(TransactionWeb(transaction, this));
    }).timeout(timeout);
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }
}
