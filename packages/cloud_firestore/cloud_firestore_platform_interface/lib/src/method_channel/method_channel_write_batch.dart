// Copyright 2018, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'method_channel_firestore.dart';

/// A [MethodChannelWriteBatch] is a series of write operations to be performed as one unit.
///
/// Operations done on a [MethodChannelWriteBatch] do not take effect until you [commit].
///
/// Once committed, no further operations can be performed on the [MethodChannelWriteBatch],
/// nor can it be committed again.
class MethodChannelWriteBatch extends WriteBatchPlatform {
  /// Create an instance of [MethodChannelWriteBatch]
  MethodChannelWriteBatch(this._firestore) : super();

  /// The Firestore instance of this batch.
  final FirestorePlatform _firestore;

  /// Keeps track of all batch writes in order.
  List<Map<String, dynamic>> _writes = [];

  /// The committed state of the WriteBatch.
  ///
  /// Once a batch has been committed, a [StateError] will
  /// be thrown if the batch is modified after.
  bool _committed = false;

  @override
  Future<void> commit() async {
    _assertNotCommitted();
    _committed = true;

    if (_writes.isEmpty) {
      return;
    }

    await MethodChannelFirestore.channel.invokeMethod<void>('WriteBatch#commit',
        <String, dynamic>{'appName': _firestore.app.name, 'writes': _writes});
  }

  @override
  void delete(DocumentReferencePlatform document) {
    _assertNotCommitted();
    assert(document != null);
    assert(document.firestore == _firestore,
        "the document provided is from a different Firestore instance");
    _writes.add(<String, dynamic>{
      'path': document.path,
      'type': 'DELETE',
    });
  }

  @override
  void setData(DocumentReferencePlatform document, Map<String, dynamic> data,
      [SetOptions options]) {
    _assertNotCommitted();
    assert(document != null);
    assert(data != null);
    assert(document.firestore == _firestore,
        "the document provided is from a different Firestore instance");

    _writes.add(<String, dynamic>{
      'path': document.path,
      'type': 'SET',
      'data': data,
      'options': <String, dynamic>{
        'merge': options?.merge,
        'mergeFields': options?.mergeFields,
      },
    });
  }

  @override
  void updateData(
    DocumentReferencePlatform document,
    Map<String, dynamic> data,
  ) {
    _assertNotCommitted();
    assert(document != null);
    assert(data != null);
    assert(document.firestore == _firestore,
        "the document provided is from a different Firestore instance");

    _writes.add(<String, dynamic>{
      'path': document.path,
      'type': 'UPDATE',
      'data': data,
    });
  }

  void _assertNotCommitted() {
    if (_committed) {
      throw StateError(
          'This batch has already been committed and can no longer be changed.');
    }
  }
}
