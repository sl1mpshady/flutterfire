// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'test_firestore_message_codec.dart';

typedef MethodCallCallback = dynamic Function(MethodCall methodCall);

const kCollectionId = "foo";
const kDocumentId = "bar";

const Map<String, dynamic> kMockSnapshotMetadata = <String, dynamic>{
  "hasPendingWrites": false,
  "isFromCache": false,
};

const Map<String, dynamic> kMockDocumentSnapshotData = <String, dynamic>{
  '1': 2
};

BinaryMessenger defaultBinaryMessenger =
    ServicesBinding.instance.defaultBinaryMessenger;

void initializeMethodChannel() {
  // Install the Codec that is able to decode FieldValues.
  MethodChannelFirestore.channel = MethodChannel(
    'plugins.flutter.io/cloud_firestore',
    StandardMethodCodec(TestFirestoreMessageCodec()),
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });
  MethodChannelFirestore.channel.setMockMethodCallHandler((call) async {
    switch (call.method) {
      case 'DocumentReference#setData':
        return true;

      case 'DocumentReference#get':
        if (call.arguments['path'] == 'foo/bar') {
          return <String, dynamic>{
            'path': 'foo/bar',
            'data': <String, dynamic>{'key1': 'val1'},
            'metadata': kMockSnapshotMetadata,
          };
        } else if (call.arguments['path'] == 'foo/notExists') {
          return <String, dynamic>{
            'path': 'foo/notExists',
            'data': null,
            'metadata': kMockSnapshotMetadata,
          };
        }
        throw PlatformException(code: 'UNKNOWN_PATH');
      case 'Firestore#runTransaction':
        return <String, dynamic>{'1': 3};
      case 'Transaction#get':
        if (call.arguments['path'] == 'foo/bar') {
          return <String, dynamic>{
            'path': 'foo/bar',
            'data': <String, dynamic>{'key1': 'val1'},
            'metadata': kMockSnapshotMetadata,
          };
        } else if (call.arguments['path'] == 'foo/notExists') {
          return <String, dynamic>{
            'path': 'foo/notExists',
            'data': null,
            'metadata': kMockSnapshotMetadata,
          };
        }
        throw PlatformException(code: 'UNKNOWN_PATH');
      case 'Transaction#set':
        return null;
      case 'Transaction#update':
        return null;
      case 'Transaction#create':
        return null;
      case 'Transaction#delete':
        return null;
      case 'WriteBatch#create':
        return 1;
      case 'Query#addSnapshotListener':
        // ignore: unawaited_futures
        Future<void>.delayed(Duration.zero).then<void>((_) {
          defaultBinaryMessenger.handlePlatformMessage(
            MethodChannelFirestore.channel.name,
            MethodChannelFirestore.channel.codec
                .encodeMethodCall(MethodCall('QuerySnapshot', <String, dynamic>{
              'appName': 'TestApp',
              'handle': 1,
              'paths': <String>["${call.arguments['path']}/0"],
              'documents': <dynamic>[kMockSnapshotMetadata],
              'metadatas': <Map<String, dynamic>>[kMockSnapshotMetadata],
              'metadata': kMockSnapshotMetadata,
              'documentChanges': <dynamic>[
                <String, dynamic>{
                  'oldIndex': -1,
                  'newIndex': 0,
                  'type': 'DocumentChangeType.added',
                  'document': kMockDocumentSnapshotData,
                  'metadata': kMockSnapshotMetadata,
                },
              ],
            })),
            (_) {},
          );
        });
    }

    return null;
  });
}

void handleMethodCall(MethodCallCallback methodCallCallback) =>
    MethodChannelFirestore.channel.setMockMethodCallHandler((call) async {
      expect(call.arguments["appName"],
          equals(FirestorePlatform.instance.app.name));
      expect(call.arguments["path"], equals("$kCollectionId/$kDocumentId"));
      return await methodCallCallback(call);
    });
