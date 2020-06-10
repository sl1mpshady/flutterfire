// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Private/FLTFirebaseFirestoreReader.h"
#import "Private/FLTFirebaseFirestoreWriter.h"

@implementation FLTFirebaseFirestoreReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[FLTFirebaseFirestoreWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[FLTFirebaseFirestoreReader alloc] initWithData:data];
}
@end

@implementation FLTFirebaseFirestoreUtils {
}
@end