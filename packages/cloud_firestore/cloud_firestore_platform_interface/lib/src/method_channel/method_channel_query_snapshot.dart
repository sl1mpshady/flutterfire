// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';

import 'method_channel_document_change.dart';

/// Contains zero or more [DocumentSnapshotPlatform] objects.
class MethodChannelQuerySnapshot extends QuerySnapshotPlatform {
  /// Creates a [MethodChannelQuerySnapshot] from the given [data]
  MethodChannelQuerySnapshot(
      FirestorePlatform firestore, Map<dynamic, dynamic> data)
      : super(
            List<DocumentSnapshotPlatform>.generate(data['documents'].length,
                (int index) {
              return DocumentSnapshotPlatform(
                firestore,
                data['paths'][index],
                <String, dynamic>{
                  'data': Map<String, dynamic>.from(data['documents'][index]),
                  'metadata': <String, dynamic>{
                    'isFromCache': data['metadatas'][index]['isFromCache'],
                    'hasPendingWrites': data['metadatas'][index]
                        ['hasPendingWrites'],
                  },
                },
              );
            }),
            List<DocumentChangePlatform>.generate(
                data['documentChanges'].length, (int index) {
              return MethodChannelDocumentChange(
                firestore,
                Map<String, dynamic>.from(data['documentChanges'][index]),
              );
            }),
            SnapshotMetadataPlatform(
              data['metadata']['hasPendingWrites'],
              data['metadata']['isFromCache'],
            ));
}
