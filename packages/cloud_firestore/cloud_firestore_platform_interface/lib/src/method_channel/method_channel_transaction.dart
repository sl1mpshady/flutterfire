// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_firestore.dart';

/// An implementation of [TransactionPlatform] which uses [MethodChannel] to
/// communication with native plugin
class MethodChannelTransaction extends TransactionPlatform {
  /// [FirebaseApp] name used for this [MethodChannelTransaction]
  final String appName;
  int _transactionId;
  FirestorePlatform _firestore;

  /// Constructor.
  MethodChannelTransaction(int transactionId, this.appName)
      : _transactionId = transactionId,
        super() {
    _firestore = FirestorePlatform.instanceFor(app: Firebase.app(appName));
  }

  int _documentGetCount = 0;

  List<Map<String, dynamic>> _commands = [];

  @override
  List<Map<String, dynamic>> get commands {
    if (_documentGetCount > 0) {
      assert(_documentGetCount <= _commands.length,
          "All transaction get operations must also be written.");
    }

    return _commands;
  }

  @override
  Future<DocumentSnapshotPlatform> get(documentPath) async {
    assert(_commands.isEmpty,
        "Transactions require all reads to be executed before all writes.");

    final Map<String, dynamic> result = await MethodChannelFirestore.channel
        .invokeMapMethod<String, dynamic>('Transaction#get', <String, dynamic>{
      'appName': appName,
      'transactionId': _transactionId,
      'path': documentPath,
    });
    _documentGetCount++;

    return DocumentSnapshotPlatform(
      _firestore,
      documentPath,
      Map<String, dynamic>.from(result),
    );
  }

  @override
  MethodChannelTransaction delete(String documentPath) {
    _commands.add(<String, String>{
      'type': 'DELETE',
      'path': documentPath,
    });

    return this;
  }

  @override
  MethodChannelTransaction update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    _commands.add(<String, dynamic>{
      'type': 'UPDATE',
      'path': documentPath,
      'data': data,
    });

    return this;
  }

  @override
  MethodChannelTransaction set(String documentPath, Map<String, dynamic> data,
      [SetOptions options]) {
    _commands.add(<String, dynamic>{
      'type': 'SET',
      'path': documentPath,
      'data': data,
      'options': {
        'merge': options?.merge,
        'mergeFields': options?.mergeFields,
      },
    });

    return this;
  }
}
