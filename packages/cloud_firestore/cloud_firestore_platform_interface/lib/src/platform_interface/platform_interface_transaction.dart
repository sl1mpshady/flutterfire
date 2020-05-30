// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The TransactionHandler may be executed multiple times, it should be able
/// to handle multiple executions.
typedef Future<dynamic> TransactionHandler(TransactionPlatform transaction);

/// a [TransactionPlatform] is a set of read and write operations on one or more documents.
abstract class TransactionPlatform extends PlatformInterface {
  /// Constructor.
  TransactionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [TransactionPlatform].
  ///
  /// This is used by the app-facing [Transaction] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(TransactionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  List<Map<String, dynamic>> get commands {
    throw UnimplementedError("commands not implemented");
  }

  Future<void> commit() {
    throw UnimplementedError("commit() not implemented");
  }

  Future<DocumentSnapshotPlatform> get(String documentPath) {
    throw UnimplementedError("get() not implemented");
  }

  TransactionPlatform delete(String documentPath) {
    throw UnimplementedError("delete() not implemented");
  }

  TransactionPlatform update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError("update() not implemented");
  }

  TransactionPlatform set(String documentPath, Map<String, dynamic> data,
      [SetOptions options]) {
    throw UnimplementedError("set() not implemented");
  }
}
