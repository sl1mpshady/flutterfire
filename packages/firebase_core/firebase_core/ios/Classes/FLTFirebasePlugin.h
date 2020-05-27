// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import <Flutter/Flutter.h>

// Firebase default app name.
NSString *const kFIRDefaultAppNameIOS = @"__FIRAPP_DEFAULT";
NSString *const kFIRDefaultAppNameDart = @"[DEFAULT]";

/**
 * Block that is capable of sending a success response to a method call operation.
 * Use this for returning success data to a Method call.
 */
typedef void (^FLTFirebaseMethodCallSuccessBlock)(id _Nullable result);

/**
 * Block that is capable of sending an error response to a method call operation.
 * Use this for returning error information to a Method call.
 */
typedef void(^FLTFirebaseMethodCallErrorBlock)
    (NSString *code, NSString *message, NSDictionary *_Nullable details, NSError _Nullable *error);

/**
 * A protocol that all FlutterFire plugins should implement.
 */
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

/**
 * An interface represent a returned result from a Flutter Method Call.
 */
@interface FLTFirebaseMethodCallResult : NSObject
+ (instancetype)createWithSuccess:(FLTFirebaseMethodCallSuccessBlock)successBlock andErrorBlock:(FLTFirebaseMethodCallErrorBlock)errorBlock;

/**
 * Submit a result indicating a successful method call.
 *
 * E.g.: `result.success(nil);`
 */
@property(readonly, nonatomic) FLTFirebaseMethodCallSuccessBlock success;

/**
 * Submit a result indicating a failed method call.
 *
 * E.g.: `result.error(@"code", @"message", nil);`
 */
@property(readonly, nonatomic) FLTFirebaseMethodCallErrorBlock error;

@end

@interface FLTFirebasePlugin : NSObject
/**
 * Creates a standardized instance of FlutterError using the values returned through FLTFirebaseMethodCallErrorBlock.
 *
 * @param code Error Code.
 * @param message Error Message.
 * @param details Optional dictionary of additional key/values to return to Dart.
 * @param error Optional NSError that this error relates to.
 *
 * @return FlutterError
 */
- (FlutterError *)createFlutterErrorFromCode:(NSString *)code message:(NSString *)message optionalDetails:(NSDictionary *_Nullable)details andOptionalNSError:(NSError *_Nullable)error;

/**
 * Converts the '[DEFAULT]' app name used in dart and other SDKs to the '__FIRAPP_DEFAULT' iOS equivalent.
 *
 * If name is not '[DEFAULT]' then just returns the same name that was passed in.
 *
 * @param appName The name of the Firebase App.
 *
 * @return NSString
 */
- (NSString *)firebaseAppNameFromDartName:(NSString *)appName;

/**
 * Retrieves a FIRApp instance based on the app name provided from Dart code.
 *
 * @param appName The name of the Firebase App.
 *
 * @return FIRApp - returns nil if Firebase app does not exist.
 */
- (FIRApp _Nullable *)firebaseAppNamed:(NSString *)appName;
@end