// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:drive/drive.dart' as drive;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'collection_reference_e2e.dart';
import 'instance_e2e.dart';
import 'query_e2e.dart';
import 'document_reference_e2e.dart';
import 'document_change_e2e.dart';
import 'field_value_e2e.dart';
import 'geo_point_e2e.dart';
import 'snapshot_metadata_e2e.dart';
import 'timestamp_e2e.dart';
import 'transaction_e2e.dart';
import 'write_batch_e2e.dart';

// Requires that an emulator is running locally
bool USE_EMULATOR = false;

void testsMain() {
  setUpAll(() async {
    await Firebase.initializeApp();

    if (USE_EMULATOR) {
      FirebaseFirestore.instance.settings = Settings(
          host: '10.0.2.2:8080', sslEnabled: false, persistenceEnabled: false);
    }
  });

  runInstanceTests();

  runCollectionReferenceTests();
  runDocumentChangeTests();
  runDocumentReferenceTests();
  runFieldValueTests();
  runGeoPointTests();
  runQueryTests();
  runSnapshotMetadataTests();
  runTimestampTests();
  runTransactionTests();
  runWriteBatchTests();
}

void main() => drive.main(testsMain);
