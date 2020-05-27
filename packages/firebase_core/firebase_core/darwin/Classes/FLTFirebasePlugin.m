// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTFirebasePlugin.h"

@interface FLTFirebaseMethodCallResult ()
@property(readwrite, nonatomic) FLTFirebaseMethodCallErrorBlock error;
@property(readwrite, nonatomic) FLTFirebaseMethodCallSuccessBlock success;
@end
@implementation FLTFirebaseMethodCallResult

+ (instancetype)createWithSuccess:(FLTFirebaseMethodCallSuccessBlock)successBlock andErrorBlock:(FLTFirebaseMethodCallErrorBlock)errorBlock {
  FLTFirebaseMethodCallResult *methodCallResult = [[FLTFirebaseMethodCallResult alloc] init];
  methodCallResult.error = errorBlock;
  methodCallResult.success = successBlock;
  return methodCallResult;
}

@end

@implementation FLTFirebasePlugin
- (FlutterError *)createFlutterErrorFromCode:(NSString *)code message:(NSString *)message optionalDetails:(NSDictionary *_Nullable)details andOptionalNSError:(NSError *_Nullable)error {
  NSMutableDictionary *detailsDict = [NSMutableDictionary dictionaryWithDictionary:details ?: @{}];
  if (error != nil) {
    detailsDict[@"nativeErrorCode"] = [@(error.code) stringValue];
    detailsDict[@"nativeErrorMessage"] = error.localizedDescription;
  }
  return [FlutterError errorWithCode:code message:message details:detailsDict];
}

- (NSString *)firebaseAppNameFromDartName:(NSString *)appName {
  NSString *appNameIOS = appName;
  if ([kFIRDefaultAppNameDart isEqualToString:appName]) {
    appNameIOS = kFIRDefaultAppNameIOS;
  }
  return appNameIOS;
}

- (_Nullable FIRApp *)firebaseAppNamed:(NSString *)appName {
  return [FIRApp appNamed:[self firebaseAppNameFromDartName:appName]];
}
@end