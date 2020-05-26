// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import <Flutter/Flutter.h>

@protocol FLTFirebasePlugin<NSObject>
/**
 * FlutterFire plugins implementing FLTFirebasePlugin must provide this method to provide it's
 * constants that are initialized during FirebaseCore.initializeApp in Dart.
 *
 * @param registrar A helper providing application context and methods for
 *     registering callbacks.
 */
 @required
- (NSDictionary *)pluginConstantsForFIRApp:(FIRApp *)firebaseApp;

/**
 * The Firebase library name of the plugin, used by
 * [FIRApp registerLibrary:firebaseLibraryName withVersion:] to
 * register this plugin with the Firebase backend.
 *
 * Usually this is provided by the 'LIBRARY_NAME' preprocessor definition
 * defined in the plugins .podspec file.
 */
 @required
- (NSString *)firebaseLibraryName;

/**
 * The Firebase library version of the plugin, used by
 * FIRApp registerLibrary:withVersion:firebaseLibraryVersion] to
 * register this plugin with the Firebase backend.
 *
 * Usually this is provided by the 'LIBRARY_VERSION' preprocessor definition
 * defined in the plugins .podspec file.
 */
 @required
- (NSString *)firebaseLibraryVersion;

/**
 * FlutterFire plugins implementing FLTFirebasePlugin must provide this method to provide
 * its main method channel name, used by FirebaseCore.initializeApp in Dart to identify
 * constants specific to a plugin.
 */
 @required
- (NSString *)flutterChannelName;
@end

// TODO(Salakar): Not currently used, will be used by future plugins.
@interface FLTFirebasePlugin : NSObject
@end