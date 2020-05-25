// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase/firestore.dart' as web;

import 'package:cloud_firestore_web/src/utils/codec_utility.dart';

/// Builds [DocumentSnapshotPlatform] instance form web snapshot instance
DocumentSnapshotPlatform fromWebDocumentSnapshotToPlatformDocumentSnapshot(
    web.DocumentSnapshot webSnapshot, FirestorePlatform firestore) {
  return DocumentSnapshotPlatform(
    firestore,
    webSnapshot.ref.path,
    <String, dynamic>{
      'data': CodecUtility.decodeMapData(webSnapshot.data()),
      'metadata': webSnapshot.metadata,
    },
  );
}
