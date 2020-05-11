// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTFirebaseCorePlugin.h"

#import <Firebase/Firebase.h>

static NSDictionary *getDictionaryFromFIROptions(FIROptions *options) {
  if (!options) {
    return nil;
  }
  return @{
    @"apiKey" : options.APIKey ?: [NSNull null],
    @"appId" : options.googleAppID ?: [NSNull null],
    @"messagingSenderId" : options.GCMSenderID ?: [NSNull null],
    @"projectId" : options.projectID ?: [NSNull null],
    @"iosBundleId" : options.bundleID ?: [NSNull null],
    //@"authDomain" : options.clientID ?: [NSNull null],
    @"trackingId" : options.trackingID ?: [NSNull null],
    @"androidClientId" : options.androidClientID ?: [NSNull null],
    @"databaseURL" : options.databaseURL ?: [NSNull null],
    @"storageBucket" : options.storageBucket ?: [NSNull null],
    @"deepLinkURLScheme" : options.deepLinkURLScheme ?: [NSNull null],
  };
}

static NSDictionary *getDictionaryFromFIRApp(FIRApp *app) {
  if (!app) {
    return nil;
  }
  return @{@"name" : app.name, @"options" : getDictionaryFromFIROptions(app.options)};
}

@implementation FLTFirebaseCorePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/firebase_core"
                                  binaryMessenger:[registrar messenger]];
  FLTFirebaseCorePlugin *instance = [[FLTFirebaseCorePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  SEL sel = NSSelectorFromString(@"registerLibrary:withVersion:");
  if ([FIRApp respondsToSelector:sel]) {
    [FIRApp performSelector:sel withObject:LIBRARY_NAME withObject:LIBRARY_VERSION];
  }
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"FirebaseApp#configure" isEqualToString:call.method]) {
    NSString *name = call.arguments[@"name"];
    NSDictionary *optionsDictionary = call.arguments[@"options"];

    FIROptions *options =
        [[FIROptions alloc] initWithGoogleAppID:optionsDictionary[@"appId"]
                                    GCMSenderID:optionsDictionary[@"messagingSenderId"]];
    if (![optionsDictionary[@"iosBundleId"] isEqual:[NSNull null]])
      options.bundleID = optionsDictionary[@"iosBundleId"];
    if (![optionsDictionary[@"apiKey"] isEqual:[NSNull null]])
      options.APIKey = optionsDictionary[@"apiKey"];
    //if (![optionsDictionary[@"clientId"] isEqual:[NSNull null]]) // TODO(ehesp): what is this?
      //options.clientID = optionsDictionary[@"androidClientId"];
    if (![optionsDictionary[@"trackingId"] isEqual:[NSNull null]])
      options.trackingID = optionsDictionary[@"trackingId"];
    if (![optionsDictionary[@"projectId"] isEqual:[NSNull null]])
      options.projectID = optionsDictionary[@"projectId"];
    if (![optionsDictionary[@"androidClientId"] isEqual:[NSNull null]])
      options.androidClientID = optionsDictionary[@"androidClientId"];
    if (![optionsDictionary[@"databaseURL"] isEqual:[NSNull null]])
      options.databaseURL = optionsDictionary[@"databaseURL"];
    if (![optionsDictionary[@"storageBucket"] isEqual:[NSNull null]])
      options.storageBucket = optionsDictionary[@"storageBucket"];
    if (![optionsDictionary[@"deepLinkURLScheme"] isEqual:[NSNull null]])
      options.deepLinkURLScheme = optionsDictionary[@"deepLinkURLScheme"];
    [FIRApp configureWithName:name options:options];
    result(nil);
  } else if ([@"FirebaseApp#allApps" isEqualToString:call.method]) {
    NSDictionary<NSString *, FIRApp *> *allApps = [FIRApp allApps];
    NSMutableArray *appsList = [NSMutableArray array];
    for (NSString *name in allApps) {
      FIRApp *app = allApps[name];
      [appsList addObject:getDictionaryFromFIRApp(app)];
    }
    result(appsList.count > 0 ? appsList : nil);
  } else if ([@"FirebaseApp#appNamed" isEqualToString:call.method]) {
    NSString *name = call.arguments;
    FIRApp *app = [FIRApp appNamed:name];
    result(getDictionaryFromFIRApp(app));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
