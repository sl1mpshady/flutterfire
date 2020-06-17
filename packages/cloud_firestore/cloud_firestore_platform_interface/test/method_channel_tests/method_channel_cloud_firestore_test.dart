// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// import 'dart:async';
import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
// import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_transaction.dart';
// import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';
//import '../utils/test_firestore_message_codec.dart';

void main() {
  initializeMethodChannel();
  MethodChannelFirestore firestore;
  FirebaseApp secondaryApp;
  bool mockPlatformExceptionThrown = false;
  final List<MethodCall> log = <MethodCall>[];
  int mockHandleId = 0;
  BinaryMessenger defaultBinaryMessenger =
      ServicesBinding.instance.defaultBinaryMessenger;

  setUpAll(() async {
    secondaryApp = await Firebase.initializeApp(
      name: 'testApp',
      options: const FirebaseOptions(
        appId: '1:1234567890:ios:42424242424242',
        apiKey: '123',
        projectId: '123',
        messagingSenderId: '1234567890',
      ),
    );
    await Firebase.initializeApp(
      name: 'testApp2',
      options: const FirebaseOptions(
        appId: '1:1234567890:ios:42424242424242',
        apiKey: '123',
        projectId: '123',
        messagingSenderId: '1234567890',
      ),
    );

    firestore = MethodChannelFirestore();

    handleMethodCall((MethodCall call) {
      log.add(call);
      switch (call.method) {
        // case 'Firestore#snapshotsInSync':
        //   return Future.delayed(Duration.zero);
        // case 'QuerySnapshot#event':
        //   return Future.delayed(Duration.zero);
        // case 'QuerySnapshot#error':
        //   return Future.delayed(Duration.zero);
        // case 'DocumentSnapshot#event':
        //   return Future.delayed(Duration.zero);
        // case 'DocumentSnapshot#error':
        //   return Future.delayed(Duration.zero);
        // case 'Transaction#attempt':
        //   return Future.delayed(Duration.zero);
        // case 'Firestore#addSnapshotsInSyncListener':
        //   Future<void>.delayed(Duration.zero);

        //   break;
        case 'Firestore#addSnapshotsInSyncListener':
        case 'Firestore#removeListener':
        case 'Firestore#waitForPendingWrites':
        case 'Firestore#terminate':
        case 'Firestore#settings':
        case 'Transaction#create':
        case 'Firestore#enableNetwork':
        case 'Firestore#disableNetwork':
        case 'Firestore#clearPersistence':
          if (mockPlatformExceptionThrown) {
            throw PlatformException(code: 'UNKNOWN');
          }
          return Future.delayed(Duration.zero);
        default:
          return null;
      }
    });
  });

  setUp(() {
    mockPlatformExceptionThrown = false;
    log.clear();
  });

  group("$MethodChannelFirestore", () {
    group('constructor', () {
      test('should create an instance with no args', () {
        MethodChannelFirestore test = MethodChannelFirestore();
        expect(test.app, equals(Firebase.app()));
      });

      test('create an instance with default app', () {
        MethodChannelFirestore test =
            MethodChannelFirestore(app: Firebase.app());
        expect(test.app, equals(Firebase.app()));
      });
      test('create an instance with a secondary app', () {
        MethodChannelFirestore test = MethodChannelFirestore(app: secondaryApp);
        expect(test.app, equals(secondaryApp));
      });

      test('allow multiple instances', () {
        MethodChannelFirestore test1 = MethodChannelFirestore();
        MethodChannelFirestore test2 =
            MethodChannelFirestore(app: secondaryApp);
        expect(test1.app, equals(Firebase.app()));
        expect(test2.app, equals(secondaryApp));
      });
    });

    test('nextMethodChannelHandleId', () {
      final handleId = MethodChannelFirestore.nextMethodChannelHandleId;

      expect(MethodChannelFirestore.nextMethodChannelHandleId, handleId + 1);
    });

    test('queryObservers', () {
      expect(MethodChannelFirestore.queryObservers,
          isInstanceOf<Map<int, StreamController<QuerySnapshotPlatform>>>());
    });

    test('documentObservers', () {
      expect(MethodChannelFirestore.documentObservers,
          isInstanceOf<Map<int, StreamController<DocumentSnapshotPlatform>>>());
    });
    test('snapshotInSyncObservers', () {
      expect(MethodChannelFirestore.snapshotInSyncObservers,
          isInstanceOf<Map<int, StreamController<void>>>());
    });

    group('delegateFor()', () {
      test('returns a [FirestorePlatform] with no arguments', () {
        expect(firestore.delegateFor(), equals(FirestorePlatform.instance));
      });
      test('returns a [FirestorePlatform] with arguments', () {
        expect(firestore.delegateFor(app: secondaryApp),
            FirestorePlatform.instanceFor(app: secondaryApp));
      });
    });

    test('batch()', () {
      expect(firestore.batch(), isInstanceOf<WriteBatchPlatform>());
    });

    group('clearPersistence()', () {
      test('invoke Firestore#clearPersistence with correct args', () {
        expect(firestore.clearPersistence(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#clearPersistence',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;
        expect(() => firestore.clearPersistence(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    test('collection()', () {
      final collection = firestore.collection('foo/bar');

      expect(collection, isInstanceOf<CollectionReferencePlatform>());
      expect(collection.path, equals('foo/bar'));
      expect(collection.firestore, equals(firestore));
    });

    test('collectionGroup()', () {
      final collectionGroup = firestore.collectionGroup('foo/bar');

      expect(collectionGroup, isInstanceOf<QueryPlatform>());
      expect(collectionGroup.isCollectionGroupQuery, isTrue);
      expect(collectionGroup.firestore, equals(firestore));
    });

    group('disableNetwork()', () {
      test('invoke Firestore#disableNetwork with correct args', () {
        expect(firestore.disableNetwork(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#disableNetwork',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore.disableNetwork(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    test('doc()', () {
      final doc = firestore.doc('foo/bar');

      expect(doc, isInstanceOf<DocumentReferencePlatform>());
      expect(doc.path, equals('foo/bar'));
      expect(doc.firestore, equals(firestore));
    });

    group('enableNetwork()', () {
      test('invoke Firestore#enableNetwork with correct args', () {
        expect(firestore.enableNetwork(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#enableNetwork',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore.enableNetwork(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    group('snapshotsInSync()', () {
      // TODO (helenaford): write test
      int handle;
      setUp(() {
        handle = mockHandleId;
      });
      // test('returns a [Stream]', () {
      //   final stream = firestore.snapshotsInSync();

      //   expect(stream, isInstanceOf<Stream<void>>());
      //   mockHandleId++;
      // });

      // test('onListen and onCancel invokes native methods with correct args',
      //     () async {
      //   final Stream<void> stream = firestore.snapshotsInSync();
      //   final StreamSubscription<QuerySnapshotPlatform> subscription =
      //       await stream.listen((event) {});

      //   await subscription.cancel();
      //   await Future<void>.delayed(Duration.zero);
      //   mockHandleId++;

      //   expect(
      //     log,
      //     equals(<Matcher>[
      //       isMethodCall(
      //         'Query#addSnapshotListener',
      //         arguments: <String, dynamic>{
      //           'handle': handle,
      //           'appName': '[DEFAULT]',
      //         },
      //       ),
      //       isMethodCall(
      //         'Firestore#removeListener',
      //         arguments: <String, dynamic>{'handle': handle},
      //       ),
      //     ]),
      //   );
      // });
    });

    test('runTransaction()', () {
      // TODO (helenaford): write test
      // expect(firestore.runTransaction(), 1);
    });

    group('settings()', () {
      Settings settings = Settings();

      test('invoke Firestore#settings with correct args', () {
        expect(firestore.settings(settings), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#settings',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'settings': settings.asMap,
              },
            ),
          ]),
        );
      });
      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore.settings(settings),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    group('terminate()', () {
      test('invoke Firestore#terminate with correct args', () {
        expect(firestore.terminate(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#terminate',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore.terminate(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    group('waitForPendingWrites()', () {
      test('invoke Firestore#waitForPendingWrites with correct args', () {
        expect(firestore.waitForPendingWrites(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#waitForPendingWrites',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore.waitForPendingWrites(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });
  });
}
