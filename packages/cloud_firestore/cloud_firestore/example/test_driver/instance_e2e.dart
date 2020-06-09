// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runInstanceTests() {
  group('$Firestore.instance', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    test('snapshotsInSync()', () async {
      DocumentReference documentReference =
          firestore.document('flutter-tests/insync');

      // Ensure deleted
      await documentReference.delete();

      StreamController controller = StreamController();
      StreamSubscription insync;
      StreamSubscription snapshots;

      int inSyncCount = 0;

      insync = firestore.snapshotsInSync().listen((_) {
        controller.add('insync=$inSyncCount');
        inSyncCount++;
      });

      snapshots = documentReference.snapshots().listen((ds) {
        controller.add('snapshot-exists=${ds.exists}');
      });

      // Allow the snapshots to trigger...
      await Future.delayed(Duration(seconds: 1));

      await documentReference.setData({'foo': 'bar'});

      await expectLater(
          controller.stream,
          emitsInOrder([
            'insync=0', // No other snapshots
            'snapshot-exists=false',
            'insync=1',
            'snapshot-exists=true',
            'insync=2',
          ]));

      await controller.close();
      await insync.cancel();
      await snapshots.cancel();
    });

    test('enableNetwork()', () async {
      // Write some data while online
      await firestore.enableNetwork();
      DocumentReference documentReference =
          firestore.document('flutter-tests/enable-network');
      await documentReference.setData({'foo': 'bar'});

      // Disable the network
      await firestore.disableNetwork();

      StreamController controller = StreamController();

      // Set some data while offline
      documentReference.setData({'foo': 'baz'}).then((_) async {
        // Only when back online will this trigger
        controller.add(true);
      });

      // Go back online
      await firestore.enableNetwork();

      await expectLater(controller.stream, emits(true));
      await controller.close();
    });

    test('disableNetwork()', () async {
      // Write some data while online
      await firestore.enableNetwork();
      DocumentReference documentReference =
          firestore.document('flutter-tests/disable-network');
      await documentReference.setData({'foo': 'bar'});

      // Disable the network
      await firestore.disableNetwork();

      // Get data from cache
      DocumentSnapshot documentSnapshot = await documentReference.get();
      expect(documentSnapshot.metadata.isFromCache, isTrue);
      expect(documentSnapshot.data()['foo'], equals('bar'));

      // Go back online once test complete
      await firestore.enableNetwork();
    });

    // TODO(ehesp): Not sure how to test this - kills the tests
    // test('terminate()', () async {
    //   await firestore.terminate();
    // });

    test('clearPersistence()', () async {
      await firestore.clearPersistence();
    });

    test('waitForPendingWrites()', () async {
      await firestore.waitForPendingWrites();
    });
  });
}