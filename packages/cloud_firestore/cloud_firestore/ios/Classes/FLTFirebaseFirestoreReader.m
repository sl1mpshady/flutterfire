// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePlugin.h>

#import "Private/FLTFirebaseFirestoreReader.h"
#import "Private/FLTFirebaseFirestoreUtils.h"

@implementation FLTFirebaseFirestoreReader
- (id)readValueOfType:(UInt8)type {
  switch (type) {
    case FirestoreDataTypeDateTime: {
      SInt64 value;
      [self readBytes:&value length:8];
      return [NSDate dateWithTimeIntervalSince1970:(value / 1000.0)];
    }
    case FirestoreDataTypeTimestamp: {
      SInt64 seconds;
      int nanoseconds;
      [self readBytes:&seconds length:8];
      [self readBytes:&nanoseconds length:4];
      return [[FIRTimestamp alloc] initWithSeconds:seconds nanoseconds:nanoseconds];
    }
    case FirestoreDataTypeGeoPoint: {
      Float64 latitude;
      Float64 longitude;
      [self readAlignment:8];
      [self readBytes:&latitude length:8];
      [self readBytes:&longitude length:8];
      return [[FIRGeoPoint alloc] initWithLatitude:latitude longitude:longitude];
    }
    case FirestoreDataTypeDocumentReference: {
      NSString *appNameDart = [self readUTF8];
      NSString *appNameIos = [FLTFirebasePlugin firebaseAppNameFromDartName:appNameDart];
      FIRFirestore *firestore = [FIRFirestore firestoreForApp:[FIRApp appNamed:appNameIos]];
      NSString *documentPath = [self readUTF8];
      return [firestore documentWithPath:documentPath];
    }
    case FirestoreDataTypeFieldPath: {
      UInt32 length = [self readSize];
      NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];
      for (UInt32 i = 0; i < length; i++) {
        id value = [self readValue];
        [array addObject:(value == nil ? [NSNull null] : value)];
      }
      return [[FIRFieldPath alloc] initWithFields:array];
    }
    case FirestoreDataTypeBlob:
      return [self readData:[self readSize]];
    case FirestoreDataTypeArrayUnion:
      return [FIRFieldValue fieldValueForArrayUnion:[self readValue]];
    case FirestoreDataTypeArrayRemove:
      return [FIRFieldValue fieldValueForArrayRemove:[self readValue]];
    case FirestoreDataTypeDelete:
      return [FIRFieldValue fieldValueForDelete];
    case FirestoreDataTypeServerTimestamp:
      return [FIRFieldValue fieldValueForServerTimestamp];
    case FirestoreDataTypeIncrementDouble:
      return
          [FIRFieldValue fieldValueForDoubleIncrement:((NSNumber *)[self readValue]).doubleValue];
    case FirestoreDataTypeIncrementInteger:
      return [FIRFieldValue fieldValueForIntegerIncrement:((NSNumber *)[self readValue]).intValue];
    case FirestoreDataTypeDocumentId:
      return [FIRFieldPath documentID];
    default:
      return [super readValueOfType:type];
  }
}
@end