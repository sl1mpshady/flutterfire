// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePlugin.h>

#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Private/FLTFirebaseFirestoreWriter.h"

@implementation FLTFirebaseFirestoreWriter : FlutterStandardWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[NSDate class]]) {
    [self writeByte:FirestoreDataTypeDateTime];
    NSDate *date = value;
    NSTimeInterval time = date.timeIntervalSince1970;
    SInt64 ms = (SInt64)(time * 1000.0);
    [self writeBytes:&ms length:8];
  } else if ([value isKindOfClass:[FIRTimestamp class]]) {
    FIRTimestamp *timestamp = value;
    SInt64 seconds = timestamp.seconds;
    int nanoseconds = timestamp.nanoseconds;
    [self writeByte:FirestoreDataTypeTimestamp];
    [self writeBytes:(UInt8 *)&seconds length:8];
    [self writeBytes:(UInt8 *)&nanoseconds length:4];
  } else if ([value isKindOfClass:[FIRGeoPoint class]]) {
    FIRGeoPoint *geoPoint = value;
    Float64 latitude = geoPoint.latitude;
    Float64 longitude = geoPoint.longitude;
    [self writeByte:FirestoreDataTypeGeoPoint];
    [self writeAlignment:8];
    [self writeBytes:(UInt8 *)&latitude length:8];
    [self writeBytes:(UInt8 *)&longitude length:8];
  } else if ([value isKindOfClass:[FIRDocumentReference class]]) {
    FIRDocumentReference *document = value;
    NSString *documentPath = [document path];
    NSString *appName = [FLTFirebasePlugin firebaseAppNameFromIosName:document.firestore.app.name];
    [self writeByte:FirestoreDataTypeDocumentReference];
    [self writeUTF8:appName];
    [self writeUTF8:documentPath];
  } else if ([value isKindOfClass:[NSData class]]) {
    NSData *blob = value;
    [self writeByte:FirestoreDataTypeBlob];
    [self writeSize:(UInt32)blob.length];
    [self writeData:blob];
  } else {
    [super writeValue:value];
  }
}
@end