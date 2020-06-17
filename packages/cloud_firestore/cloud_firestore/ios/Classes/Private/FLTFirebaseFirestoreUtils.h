// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, FirestoreDataType) {
  FirestoreDataTypeDateTime = 128,
  FirestoreDataTypeGeoPoint = 129,
  FirestoreDataTypeDocumentReference = 130,
  FirestoreDataTypeBlob = 131,
  FirestoreDataTypeArrayUnion = 132,
  FirestoreDataTypeArrayRemove = 133,
  FirestoreDataTypeDelete = 134,
  FirestoreDataTypeServerTimestamp = 135,
  FirestoreDataTypeTimestamp = 136,
  FirestoreDataTypeIncrementDouble = 137,
  FirestoreDataTypeIncrementInteger = 138,
  FirestoreDataTypeDocumentId = 139,
  FirestoreDataTypeFieldPath = 140,
};

@interface FLTFirebaseFirestoreReaderWriter : FlutterStandardReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data;
- (FlutterStandardReader *)readerWithData:(NSData *)data;
@end

@interface FLTFirebaseFirestoreUtils : NSObject
@end