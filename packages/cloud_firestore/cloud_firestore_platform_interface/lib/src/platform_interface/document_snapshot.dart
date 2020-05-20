// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Contains data read from a document in your Firestore
/// database.
///
/// The data can be extracted with the [data] property or by using subscript
/// syntax to access a specific field.
class DocumentSnapshotPlatform extends PlatformInterface {
  /// Constructs a [DocumentSnapshotPlatform] using the provided [FirestorePlatform].
  DocumentSnapshotPlatform(this._firestore, this._pointer, this._data) : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [DocumentSnapshotPlatform].
  ///
  /// This is used by the app-facing [DocumentSnapshot] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(DocumentSnapshotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  /// The [FirestorePlatform] used to produce this [DocumentSnapshotPlatform].
  final FirestorePlatform _firestore;

  final Pointer _pointer;

  final Map<String, dynamic> _data;

  /// The database ID of the snapshot's document.
  String get id => _pointer.id;

  /// Metadata about this snapshot concerning its source and if it has local
  /// modifications.
  SnapshotMetadataPlatform get metadata {
    return SnapshotMetadataPlatform(_data['metadata']['hasPendingWrites'],
        _data['metadata']['isFromCache']);
  }

  /// Signals whether or not the data exists. True if the document exists.
  bool get exists {
    return _data['data'] != null;
  }

  /// The reference that produced this snapshot.
  DocumentReferencePlatform get reference => _firestore.document(_pointer.path);

  /// Contains all the data of this snapshot.
  Map<String, dynamic> data() {
    return Map<String, dynamic>.from(_data['data']);
  }

  // TODO(ehesp): Test this works on nested Maps
  /// Reads individual values from the snapshot
  dynamic operator [](String key) => data()[key];

// TODO equal checks
}
