// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>

@interface FLTFirebaseFirestoreReader : FlutterStandardReader
- (id)readValueOfType:(UInt8)type;
@end