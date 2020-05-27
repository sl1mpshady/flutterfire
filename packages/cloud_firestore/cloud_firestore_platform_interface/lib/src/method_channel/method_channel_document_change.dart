// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

/// A DocumentChange represents a change to the documents matching a query.
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
class MethodChannelDocumentChange extends DocumentChangePlatform {
  /// Create instance of [MethodChannelDocumentChange] using [data]
  MethodChannelDocumentChange(
      FirestorePlatform firestore, Map<String, dynamic> data)
      : super(DocumentChangeType.values.firstWhere((DocumentChangeType type) {
          return type.toString() == data['type'];
        }),
            data['oldIndex'],
            data['newIndex'],
            DocumentSnapshotPlatform(
              firestore,
              data['path'],
              <String, dynamic>{
                'data': Map<String, dynamic>.from(data['document']),
                'metadata': Map<String, dynamic>.from(data['metadata']),
              },
            ));
}
