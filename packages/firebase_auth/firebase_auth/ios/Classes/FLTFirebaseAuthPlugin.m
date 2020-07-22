// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <TargetConditionals.h>

#import <firebase_core/FLTFirebasePluginRegistry.h>
#import "Firebase/Firebase.h"

#import "Public/FLTFirebaseAuthPlugin.h"

NSString *const kFLTFirebaseAuthChannelName = @"plugins.flutter.io/firebase_auth";

@interface FLTFirebaseAuthPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation FLTFirebaseAuthPlugin {
  // Auth state change handlers keyed by Firebase app name.
  NSMutableDictionary<NSString *, FIRAuthStateDidChangeListenerHandle> *_authChangeListeners;
  // ID token change handlers keyed by Firebase app name.
  NSMutableDictionary<NSString *, FIRIDTokenDidChangeListenerHandle> *_idTokenChangeListeners;
  // TODO(WIP) use me for reading stored credentials (already being stored)
  NSMutableDictionary<NSNumber *, FIRAuthCredential *> *_credentials;
}

#pragma mark - FlutterPlugin

// Returns a singleton instance of the Firebase Auth plugin.
+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static FLTFirebaseAuthPlugin *instance;

  dispatch_once(&onceToken, ^{
    instance = [[FLTFirebaseAuthPlugin alloc] init];
    // Register with the Flutter Firebase plugin registry.
    [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:instance];
  });

  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _authChangeListeners =
        [NSMutableDictionary<NSString *, FIRAuthStateDidChangeListenerHandle> dictionary];
    _idTokenChangeListeners =
        [NSMutableDictionary<NSString *, FIRIDTokenDidChangeListenerHandle> dictionary];
    _credentials = [NSMutableDictionary<NSNumber *, FIRAuthCredential *> dictionary];
  }
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kFLTFirebaseAuthChannelName
                                  binaryMessenger:[registrar messenger]];
  FLTFirebaseAuthPlugin *instance = [FLTFirebaseAuthPlugin sharedInstance];
  instance.channel = channel;

  [registrar addMethodCallDelegate:instance channel:channel];

#if TARGET_OS_OSX
  // TODO(Salakar): Publish does not exist on MacOS version of FlutterPluginRegistrar.
  // TODO(Salakar): addApplicationDelegate does not exist on MacOS version of
  // FlutterPluginRegistrar. (https://github.com/flutter/flutter/issues/41471)
#else
  [registrar publish:instance];
  [registrar addApplicationDelegate:instance];
#endif
}

- (void)cleanupWithCompletion:(void (^)(void))completion {
  // Cleanup auth state change listeners.
  @synchronized(self->_authChangeListeners) {
    for (NSString *appName in [FIRApp allApps]) {
      FIRApp *app = [FIRApp appNamed:appName];
      if (_authChangeListeners[appName] != nil) {
        [[FIRAuth authWithApp:app] removeAuthStateDidChangeListener:_authChangeListeners[appName]];
      }
    }
    [_authChangeListeners removeAllObjects];
  }

  // Cleanup id token change listeners.
  @synchronized(self->_idTokenChangeListeners) {
    for (NSString *appName in [FIRApp allApps]) {
      FIRApp *app = [FIRApp appNamed:appName];
      if (_idTokenChangeListeners[appName] != nil) {
        [[FIRAuth authWithApp:app] removeIDTokenDidChangeListener:_idTokenChangeListeners[appName]];
      }
    }
    [_idTokenChangeListeners removeAllObjects];
  }

  // Cleanup credentials.
  [_credentials removeAllObjects];

  if (completion != nil) completion();
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [self cleanupWithCompletion:nil];
  self.channel = nil;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
  FLTFirebaseMethodCallErrorBlock errorBlock =
      ^(NSString *_Nullable code, NSString *_Nullable message, NSDictionary *_Nullable details,
        NSError *_Nullable error) {
        if (code == nil) {
          NSDictionary *errorDetails = [self getNSDictionaryFromNSError:error];
          code = errorDetails[@"code"];
          message = errorDetails[@"messsage"];
          details = errorDetails;
        }

        if ([@"unknown" isEqualToString:code]) {
          NSLog(@"FLTFirebaseAuth: An error occurred while calling method %@, errorOrNil => %@",
                call.method, [error userInfo]);
        }

        flutterResult([FLTFirebasePlugin createFlutterErrorFromCode:code
                                                            message:message
                                                    optionalDetails:details
                                                 andOptionalNSError:error]);
      };

  FLTFirebaseMethodCallSuccessBlock successBlock = ^(id _Nullable result) {
    if ([result isKindOfClass:[FIRAuthDataResult class]]) {
      flutterResult([self getNSDictionaryFromAuthResult:result]);
    } else if ([result isKindOfClass:[FIRUser class]]) {
      flutterResult([self getNSDictionaryFromUser:result]);
    } else {
      flutterResult(result);
    }
  };

  FLTFirebaseMethodCallResult *methodCallResult =
      [FLTFirebaseMethodCallResult createWithSuccess:successBlock andErrorBlock:errorBlock];

  if ([@"Auth#registerChangeListeners" isEqualToString:call.method]) {
    [self registerChangeListeners:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#applyActionCode" isEqualToString:call.method]) {
    [self applyActionCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#checkActionCode" isEqualToString:call.method]) {
    [self checkActionCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#confirmPasswordReset" isEqualToString:call.method]) {
    [self confirmPasswordReset:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#createUserWithEmailAndPassword" isEqualToString:call.method]) {
    [self createUserWithEmailAndPassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#fetchSignInMethodsForEmail" isEqualToString:call.method]) {
    [self fetchSignInMethodsForEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#sendPasswordResetEmail" isEqualToString:call.method]) {
    [self sendPasswordResetEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#sendSignInLinkToEmail" isEqualToString:call.method]) {
    [self sendSignInLinkToEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithCredential" isEqualToString:call.method]) {
    [self signInWithCredential:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#setLanguageCode" isEqualToString:call.method]) {
    [self setLanguageCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#setSettings" isEqualToString:call.method]) {
    [self setSettings:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInAnonymously" isEqualToString:call.method]) {
    [self signInAnonymously:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithCustomToken" isEqualToString:call.method]) {
    [self signInWithCustomToken:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithEmailAndPassword" isEqualToString:call.method]) {
    [self signInWithEmailAndPassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithEmailLink" isEqualToString:call.method]) {
    [self signInWithEmailLink:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signOut" isEqualToString:call.method]) {
    [self signOut:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#verifyPasswordResetCode" isEqualToString:call.method]) {
    [self verifyPasswordResetCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#verifyPhoneNumber" isEqualToString:call.method]) {
    [self verifyPhoneNumber:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#delete" isEqualToString:call.method]) {
    [self userDelete:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#getIdToken" isEqualToString:call.method]) {
    [self userGetIdToken:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#linkWithCredential" isEqualToString:call.method]) {
    [self userLinkWithCredential:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#reauthenticateUserWithCredential" isEqualToString:call.method]) {
    [self userReauthenticateUserWithCredential:call.arguments
                          withMethodCallResult:methodCallResult];
  } else if ([@"User#reload" isEqualToString:call.method]) {
    [self userReload:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#sendEmailVerification" isEqualToString:call.method]) {
    [self userSendEmailVerification:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#unlink" isEqualToString:call.method]) {
    [self userUnlink:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updateEmail" isEqualToString:call.method]) {
    [self userUpdateEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updatePassword" isEqualToString:call.method]) {
    [self userUpdatePassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updatePhoneNumber" isEqualToString:call.method]) {
    [self userUpdatePhoneNumber:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updateProfile" isEqualToString:call.method]) {
    [self userUpdateProfile:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#verifyBeforeUpdateEmail" isEqualToString:call.method]) {
    [self userVerifyBeforeUpdateEmail:call.arguments withMethodCallResult:methodCallResult];
  } else {
    methodCallResult.success(FlutterMethodNotImplemented);
  }
}

#pragma mark - AppDelegate

#if TARGET_OS_IPHONE
- (bool)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)notification
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  if ([[FIRAuth auth] canHandleNotification:notification]) {
    completionHandler(UIBackgroundFetchResultNoData);
    return YES;
  }
  return NO;
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [[FIRAuth auth] setAPNSToken:deviceToken type:FIRAuthAPNSTokenTypeProd];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
  return [[FIRAuth auth] canHandleURL:url];
}
#endif

#pragma mark - FLTFirebasePlugin

- (void)didReinitializeFirebaseCore:(void (^_Nonnull)(void))completion {
  [self cleanupWithCompletion:completion];
}

- (NSString *_Nonnull)firebaseLibraryName {
  return LIBRARY_NAME;
}

- (NSString *_Nonnull)firebaseLibraryVersion {
  return LIBRARY_VERSION;
}

- (NSString *_Nonnull)flutterChannelName {
  return kFLTFirebaseAuthChannelName;
}

- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *_Nonnull)firebaseApp {
  FIRAuth *auth = [FIRAuth authWithApp:firebaseApp];
  return @{
    @"APP_LANGUAGE_CODE" : [auth languageCode] ?: [NSNull null],
    @"APP_CURRENT_USER" : [auth currentUser] ? [self getNSDictionaryFromUser:[auth currentUser]]
                                             : [NSNull null],
  };
}

#pragma mark - Firebase Auth API

- (void)applyActionCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth applyActionCode:arguments[@"code"]
             completion:^(NSError *_Nullable error) {
               if (error != nil) {
                 result.error(nil, nil, nil, error);
               } else {
                 result.success(nil);
               }
             }];
}

- (void)checkActionCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  // TODO fix action code issues.
  //  [auth checkActionCode:arguments[@"code"] completion:^(FIRActionCodeInfo * _Nullable info,
  //  NSError * _Nullable error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      NSMutableDictionary *actionCodeResultDict = [NSMutableDictionary dictionary];
  //      // TODO build action code dictionary, but;
  //      //   1) Dart and Android `operation` ints are currently wrong and also missing cases.
  //      //   2) Web should use `unknown` operation as operation not supported on firebase-dart.
  //      result.success(actionCodeResultDict);
  //    }
  //  }];
}

- (void)confirmPasswordReset:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth confirmPasswordResetWithCode:arguments[@"code"]
                         newPassword:arguments[@"newPassword"]
                          completion:^(NSError *_Nullable error) {
                            if (error != nil) {
                              result.error(nil, nil, nil, error);
                            } else {
                              result.success(nil);
                            }
                          }];
}

- (void)createUserWithEmailAndPassword:(id)arguments
                  withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth createUserWithEmail:arguments[@"email"]
                   password:arguments[@"passwprd"]
                 completion:^(FIRAuthDataResult *authResult, NSError *error) {
                   if (error != nil) {
                     result.error(nil, nil, nil, error);
                   } else {
                     result.success(authResult);
                   }
                 }];
}

- (void)fetchSignInMethodsForEmail:(id)arguments
              withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth fetchSignInMethodsForEmail:arguments[@"email"]
                        completion:^(NSArray<NSString *> *_Nullable providers,
                                     NSError *_Nullable error) {
                          if (error != nil) {
                            result.error(nil, nil, nil, error);
                          } else {
                            result.success(@{
                              @"providers" : providers,
                            });
                          }
                        }];
}

- (void)sendPasswordResetEmail:(id)arguments
          withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO implement me (actionCodeSettings parser needed - set to nil for now)
  //  [auth sendPasswordResetWithEmail:arguments[@"email"] actionCodeSettings:nil
  //  completion:^(NSError * _Nullable error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(nil);
  //    }
  //  }];
}

- (void)sendSignInLinkToEmail:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO implement me (actionCodeSettings parser needed - set to nil for now)
  //  [auth sendSignInLinkToEmail:arguments[@"email"] actionCodeSettings:nil completion:^(NSError *
  //  _Nullable error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(nil);
  //    }
  //  }];
}

- (void)signInWithCredential:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO implement me
  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(authResult);
  //    }
  //  }];
}

- (void)setLanguageCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO implement me
  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(authResult);
  //    }
  //  }];
}

- (void)setSettings:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO implement me
  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(authResult);
  //    }
  //  }];
}

- (void)signInWithCustomToken:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  [auth signInWithCustomToken:arguments[@"token"]
                   completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
                     if (error != nil) {
                       result.error(nil, nil, nil, error);
                     } else {
                       result.success(authResult);
                     }
                   }];
}

- (void)signInWithEmailAndPassword:(id)arguments
              withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInWithEmail:arguments[@"email"]
               password:arguments[@"password"]
             completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
               if (error != nil) {
                 result.error(nil, nil, nil, error);
               } else {
                 result.success(authResult);
               }
             }];
}

- (void)signInWithEmailLink:(id)arguments
       withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInWithEmail:arguments[@"email"]
                   link:arguments[@"emailLink"]
             completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
               if (error != nil) {
                 result.error(nil, nil, nil, error);
               } else {
                 result.success(authResult);
               }
             }];
}

- (void)signOut:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  if (auth.currentUser == nil) {
    result.success(nil);
    return;
  }

  NSError *signOutErrorPtr;
  BOOL signoutSucessful = [auth signOut:&signOutErrorPtr];

  if (!signoutSucessful) {
    result.error(nil, nil, nil, signOutErrorPtr);
  } else {
    result.success(nil);
  }
}

- (void)verifyPasswordResetCode:(id)arguments
           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO !!!
  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(authResult);
    }
  }];
}

- (void)userDelete:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser deleteWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)userGetIdToken:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  //  FIRUser *currentUser = auth.currentUser;
  //  if (currentUser == nil) {
  //    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
  //    return;
  //  }

  // TODO implement, handle forceRefresh/tokenOnly

  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(nil);
  //    }
  //  }];
}

- (void)userLinkWithCredential:(id)arguments
          withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  //  FIRUser *currentUser = auth.currentUser;
  //  if (currentUser == nil) {
  //    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
  //    return;
  //  }

  // TODO implement + getCredential helper

  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(nil);
  //    }
  //  }];
}

- (void)userReauthenticateUserWithCredential:(id)arguments
                        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  //  FIRUser *currentUser = auth.currentUser;
  //  if (currentUser == nil) {
  //    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
  //    return;
  //  }

  // TODO implement + getCredential helper

  //  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(nil);
  //    }
  //  }];
}

- (void)userReload:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser reloadWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(auth.currentUser);
    }
  }];
}

- (void)userSendEmailVerification:(id)arguments
             withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)userUnlink:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser unlinkFromProvider:arguments[@"providerId"]
                       completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                         if (error != nil) {
                           result.error(nil, nil, nil, error);
                         } else {
                           // Note: On other SDKs `unlinkFromProvider` returns an AuthResult
                           // instance, whereas the iOS SDK currently does not, so we manualy
                           // construct a Dart representation of one here.
                           result.success(@{
                             @"additionalUserInfo" : [NSNull null],
                             @"authCredential" : [NSNull null],
                             @"user" : user ? [self getNSDictionaryFromUser:user] : [NSNull null],
                           });
                         }
                       }];
}

- (void)userUpdateEmail:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser updateEmail:arguments[@"newEmail"]
                completion:^(NSError *_Nullable error) {
                  if (error != nil) {
                    result.error(nil, nil, nil, error);
                  } else {
                    [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                      if (reloadError != nil) {
                        result.error(nil, nil, nil, reloadError);
                      } else {
                        result.success(auth.currentUser);
                      }
                    }];
                  }
                }];
}

- (void)userUpdatePassword:(id)arguments
      withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  [currentUser updatePassword:arguments[@"newPassword"]
                   completion:^(NSError *_Nullable error) {
                     if (error != nil) {
                       result.error(nil, nil, nil, error);
                     } else {
                       [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                         if (reloadError != nil) {
                           result.error(nil, nil, nil, reloadError);
                         } else {
                           result.success(auth.currentUser);
                         }
                       }];
                     }
                   }];
}

- (void)userUpdatePhoneNumber:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO get phone credential and replace nil
  // TODO ios only, exclude mac

  //  FIRUser *currentUser = auth.currentUser;
  //  if (currentUser == nil) {
  //    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
  //    return;
  //  }
  //  [currentUser updatePhoneNumberCredential:nil completion:^(NSError * _Nullable error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
  //        if (reloadError !=nil) {
  //          result.error(nil, nil, nil, reloadError);
  //        } else {
  //          result.success(nil);
  //        }
  //      }];
  //    }
  //  }];
}

- (void)userUpdateProfile:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
    return;
  }

  NSDictionary *profileUpdates = arguments[@"profile"];
  FIRUserProfileChangeRequest *changeRequest = [currentUser profileChangeRequest];

  if (profileUpdates[@"displayName"]) {
    changeRequest.displayName = profileUpdates[@"displayName"];
  }

  if (profileUpdates[@"photoURL"]) {
    changeRequest.photoURL = [NSURL URLWithString:profileUpdates[@"photoURL"]];
  }

  [changeRequest commitChangesWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
        if (reloadError != nil) {
          result.error(nil, nil, nil, reloadError);
        } else {
          result.success(auth.currentUser);
        }
      }];
    }
  }];
}

- (void)userVerifyBeforeUpdateEmail:(id)arguments
               withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  // TODO does it exist on iOS?
  // sendEmailVerificationBeforeUpdatingEmail on ref docs but not showing in release notes or on
  // class

  //  FIRUser *currentUser = auth.currentUser;
  //  if (currentUser == nil) {
  //    result.error(@"no-current-user", @"No user currently signed in.", nil, nil);
  //    return;
  //  }

  // TODO actionCodeSettings

  //  [auth sendEmailVerificationBeforeUpdatingEmail:^(FIRAuthDataResult *authResult, NSError
  //  *error) {
  //    if (error != nil) {
  //      result.error(nil, nil, nil, error);
  //    } else {
  //      result.success(authResult);
  //    }
  //  }];
}

- (void)registerChangeListeners:(id)arguments
           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  __weak __typeof__(self) weakSelf = self;

  id authStateChangeListener = ^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
    [weakSelf.channel
        invokeMethod:@"Auth#authStateChanges"
           arguments:@{@"user" : user ? [weakSelf getNSDictionaryFromUser:user] : [NSNull null]}];
  };

  @synchronized(self->_authChangeListeners) {
    if (_authChangeListeners[auth.app.name] == nil) {
      _authChangeListeners[auth.app.name] =
          [[FIRAuth auth] addAuthStateDidChangeListener:authStateChangeListener];
    }
  }

  id idTokenChangeListener = ^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
    [weakSelf.channel
        invokeMethod:@"Auth#idTokenChanges"
           arguments:@{@"user" : user ? [weakSelf getNSDictionaryFromUser:user] : [NSNull null]}];
  };

  @synchronized(self->_idTokenChangeListeners) {
    if (_idTokenChangeListeners[auth.app.name] == nil) {
      _idTokenChangeListeners[auth.app.name] =
          [[FIRAuth auth] addIDTokenDidChangeListener:idTokenChangeListener];
    }
  }

  result.success(nil);
}

- (void)signInAnonymously:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(authResult);
    }
  }];
}

- (void)verifyPhoneNumber:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
#if TARGET_OS_OSX
  // Not supported on MacOS.
  result.success(nil);
#else
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  // TODO iOS implementation
#endif
}

#pragma mark - Utilities

- (NSDictionary *)getNSDictionaryFromNSError:(NSError *)error {
  NSString *code = @"unknown";
  NSString *message = @"An unknown error has occurred.";

  if (error == nil) {
    return @{
      @"code" : code,
      @"message" : message,
      @"additionalData" : @{},
    };
  }

  // code
  if ([error userInfo][FIRAuthErrorUserInfoNameKey] != nil) {
    // See [FIRAuthErrorCodeString] for list of codes.
    // Codes are in the format "ERROR_SOME_NAME", converting below to the format required in Dart.
    // ERROR_SOME_NAME -> SOME_NAME
    NSString *firebaseErrorCode = [error userInfo][FIRAuthErrorUserInfoNameKey];
    code = [firebaseErrorCode stringByReplacingOccurrencesOfString:@"ERROR_" withString:@""];
    // SOME_NAME -> SOME-NAME
    code = [firebaseErrorCode stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    // SOME-NAME -> some-name
    code = [firebaseErrorCode lowercaseString];
  }

  // message
  if ([error userInfo][NSLocalizedDescriptionKey] != nil) {
    message = [error userInfo][NSLocalizedDescriptionKey];
  }

  NSMutableDictionary *additionalData = [NSMutableDictionary dictionary];
  // additionalData.email
  if ([error userInfo][FIRAuthErrorUserInfoEmailKey] != nil) {
    additionalData[@"email"] = [error userInfo][FIRAuthErrorUserInfoEmailKey];
  }
  // additionalData.authCredential
  if ([error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey] != nil) {
    FIRAuthCredential *authCredential = [error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey];
    additionalData[@"authCredential"] = [self getNSDictionaryFromAuthCredential:authCredential];
  }

  return @{
    @"code" : code,
    @"message" : message,
    @"additionalData" : additionalData,
  };
}

- (FIRAuth *_Nullable)getFIRAuthFromArguments:(NSDictionary *)args {
  NSString *appNameDart = [args objectForKey:@"appName"];
  FIRApp *app = [FLTFirebasePlugin firebaseAppNamed:appNameDart];
  return [FIRAuth authWithApp:app];
}

- (NSDictionary *)getNSDictionaryFromAuthResult:(FIRAuthDataResult *)authResult {
  return @{
    @"additionalUserInfo" :
        [self getNSDictionaryFromAdditionalUserInfo:authResult.additionalUserInfo],
    @"authCredential" : [self getNSDictionaryFromAuthCredential:authResult.credential],
    @"user" : [self getNSDictionaryFromUser:authResult.user],
  };
}

- (id)getNSDictionaryFromAdditionalUserInfo:(FIRAdditionalUserInfo *)additionalUserInfo {
  if (additionalUserInfo == nil) {
    return [NSNull null];
  }

  return @{
    @"isNewUser" : [NSNumber numberWithBool:additionalUserInfo.newUser],
    @"profile" : additionalUserInfo.profile ?: [NSNull null],
    @"providerId" : additionalUserInfo.providerID,
    @"username" : additionalUserInfo.username ?: [NSNull null],
  };
}

- (id)getNSDictionaryFromAuthCredential:(FIRAuthCredential *)authCredential {
  if (authCredential == nil) {
    return [NSNull null];
  }

  // We temporarily store the non-serializable credential so the
  // Dart API can consume these at a later time.
  NSNumber *authCredentialHash = [NSNumber numberWithUnsignedInteger:[authCredential hash]];
  _credentials[authCredentialHash] = authCredential;

  return @{
    @"providerId" : authCredential.provider,
    // Note: "signInMethod" does not exist on iOS SDK, so using provider instead.
    @"signInMethod" : authCredential.provider,
    @"token" : authCredentialHash,
  };
}

- (NSDictionary *)getNSDictionaryFromUserInfo:(id<FIRUserInfo>)userInfo {
  NSString *photoURL = nil;
  if (userInfo.photoURL != nil) {
    photoURL = userInfo.photoURL.absoluteString;
    if ([photoURL length] == 0) photoURL = nil;
  }
  return @{
    @"providerId" : userInfo.providerID,
    @"displayName" : userInfo.displayName ?: [NSNull null],
    @"uid" : userInfo.uid ?: [NSNull null],
    @"photoURL" : photoURL ?: [NSNull null],
    @"email" : userInfo.email ?: [NSNull null],
    @"phoneNumber" : userInfo.phoneNumber ?: [NSNull null],
  };
}

- (NSMutableDictionary *)getNSDictionaryFromUser:(FIRUser *)user {
  // FIRUser inherits from FIRUserInfo, so we can re-use `getNSDictionaryFromUserInfo` method.
  NSMutableDictionary *userData = [[self getNSDictionaryFromUserInfo:user] mutableCopy];

  // creationTimestamp as milliseconds
  long creationDate = [user.metadata.creationDate timeIntervalSince1970] * 1000;
  userData[@"creationTime"] = [NSNumber numberWithLong:creationDate];

  // lastSignInTimestamp as milliseconds
  long lastSignInDate = [user.metadata.lastSignInDate timeIntervalSince1970] * 1000;
  userData[@"lastSignInTime"] = [NSNumber numberWithLong:lastSignInDate];

  // providerData
  NSMutableArray<NSDictionary<NSString *, NSString *> *> *providerData =
      [NSMutableArray arrayWithCapacity:user.providerData.count];
  for (id<FIRUserInfo> userInfo in user.providerData) {
    [providerData addObject:[self getNSDictionaryFromUserInfo:userInfo]];
  }
  userData[@"providerData"] = providerData;

  userData[@"isAnonymous"] = [NSNumber numberWithBool:user.isAnonymous];
  userData[@"isEmailVerified"] = [NSNumber numberWithBool:user.isEmailVerified];

  return userData;
}

@end

// OLD CODE
/*

 - (id)mapVerifyPhoneError:(NSError *)error {
   NSString *errorCode = @"verifyPhoneNumberError";

   if (error.code == FIRAuthErrorCodeCaptchaCheckFailed) {
     errorCode = @"captchaCheckFailed";
   } else if (error.code == FIRAuthErrorCodeQuotaExceeded) {
     errorCode = @"quotaExceeded";
   } else if (error.code == FIRAuthErrorCodeInvalidPhoneNumber) {
     errorCode = @"invalidPhoneNumber";
   } else if (error.code == FIRAuthErrorCodeMissingPhoneNumber) {
     errorCode = @"missingPhoneNumber";
   }
   return @{@"code" : errorCode, @"message" : error.localizedDescription};
 }

 - (FIRAuthCredential *)getCredential:(NSDictionary *)arguments {
   NSString *provider = arguments[@"provider"];
   NSDictionary *data = arguments[@"data"];
   FIRAuthCredential *credential;
   if ([FIREmailAuthProviderID isEqualToString:provider]) {
     NSString *email = data[@"email"];
     if ([data objectForKey:@"password"]) {
       NSString *password = data[@"password"];
       credential = [FIREmailAuthProvider credentialWithEmail:email password:password];
     } else {
       NSString *link = data[@"link"];
       credential = [FIREmailAuthProvider credentialWithEmail:email link:link];
     }
   } else if ([FIRGoogleAuthProviderID isEqualToString:provider]) {
     NSString *idToken = data[@"idToken"];
     NSString *accessToken = data[@"accessToken"];
     credential = [FIRGoogleAuthProvider credentialWithIDToken:idToken accessToken:accessToken];
   } else if ([FIRFacebookAuthProviderID isEqualToString:provider]) {
     NSString *accessToken = data[@"accessToken"];
     credential = [FIRFacebookAuthProvider credentialWithAccessToken:accessToken];
   } else if ([FIRTwitterAuthProviderID isEqualToString:provider]) {
     NSString *authToken = data[@"authToken"];
     NSString *authTokenSecret = data[@"authTokenSecret"];
     credential = [FIRTwitterAuthProvider credentialWithToken:authToken secret:authTokenSecret];
   } else if ([FIRGitHubAuthProviderID isEqualToString:provider]) {
     NSString *token = data[@"token"];
     credential = [FIRGitHubAuthProvider credentialWithToken:token];
   }
 #if TARGET_OS_IPHONE
   else if ([FIRPhoneAuthProviderID isEqualToString:provider]) {
     NSString *verificationId = data[@"verificationId"];
     NSString *smsCode = data[@"smsCode"];
     credential = [[FIRPhoneAuthProvider providerWithAuth:[self getAuth:arguments]]
         credentialWithVerificationID:verificationId
                     verificationCode:smsCode];
   }
 #endif
   else if ([provider length] != 0 && data[@"idToken"] != (id)[NSNull null] &&
            (data[@"accessToken"] != (id)[NSNull null] | data[@"rawNonce"] != (id)[NSNull null])) {
     NSString *idToken = data[@"idToken"];
     NSString *accessToken = data[@"accessToken"];
     NSString *rawNonce = data[@"rawNonce"];

     if (accessToken != (id)[NSNull null] && rawNonce != (id)[NSNull null] &&
         [accessToken length] != 0 && [rawNonce length] != 0) {
       credential = [FIROAuthProvider credentialWithProviderID:provider
                                                       IDToken:idToken
                                                      rawNonce:rawNonce
                                                   accessToken:accessToken];
     } else if (accessToken != (id)[NSNull null] && [accessToken length] != 0) {
       credential = [FIROAuthProvider credentialWithProviderID:provider
                                                       IDToken:idToken
                                                   accessToken:accessToken];
     } else if (rawNonce != (id)[NSNull null] && [rawNonce length] != 0) {
       credential = [FIROAuthProvider credentialWithProviderID:provider
                                                       IDToken:idToken
                                                      rawNonce:rawNonce];
     } else {
       NSLog(@"To use OAuthProvider you need to provide at least one of the following 'accessToken'
 "
             @"or 'rawNonce'.");
     }

   } else {
     NSLog(@"Support for an auth provider with identifier '%@' is not implemented.", provider);
   }
   return credential;
 }

 // TODO(jackson): We should use the renamed versions of the following methods
 // when they are available in the Firebase SDK that this plugin is dependent on.
 // * fetchSignInMethodsForEmail:completion:
 // * reauthenticateAndRetrieveDataWithCredential:completion:
 // * linkAndRetrieveDataWithCredential:completion:
 // * signInAndRetrieveDataWithCredential:completion:
 // See discussion at https://github.com/FirebaseExtended/flutterfire/pull/1487
 #pragma clang diagnostic push
 #pragma clang diagnostic ignored "-Wdeprecated-declarations"
 - (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
   if ([@"currentUser" isEqualToString:call.method]) {
     id __block listener = [[self getAuth:call.arguments]
         addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
           [self sendResult:result forUser:user error:nil];
           [auth removeAuthStateDidChangeListener:listener];
         }];
   } else if ([@"signInAnonymously" isEqualToString:call.method]) {
     [[self getAuth:call.arguments]
         signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
           [self sendResult:result forAuthDataResult:authResult error:error];
         }];
   } else if ([@"signInWithCredential" isEqualToString:call.method]) {
     [[self getAuth:call.arguments]
         signInAndRetrieveDataWithCredential:[self getCredential:call.arguments]
                                  completion:^(FIRAuthDataResult *authResult, NSError *error) {
                                    [self sendResult:result
                                        forAuthDataResult:authResult
                                                    error:error];
                                  }];
   } else if ([@"createUserWithEmailAndPassword" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     NSString *password = call.arguments[@"password"];
     [[self getAuth:call.arguments]
         createUserWithEmail:email
                    password:password
                  completion:^(FIRAuthDataResult *authResult, NSError *error) {
                    [self sendResult:result forAuthDataResult:authResult error:error];
                  }];
   } else if ([@"fetchSignInMethodsForEmail" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     [[self getAuth:call.arguments]
         fetchProvidersForEmail:email
                     completion:^(NSArray<NSString *> *providers, NSError *error) {
                       // For unrecognized emails, the Auth iOS SDK should return an
                       // empty `NSArray` here, but instead returns `nil`, so we coalesce
                       // with an empty `NSArray`.
                       // https://github.com/firebase/firebase-ios-sdk/issues/3655
                       [self sendResult:result forObject:providers ?: @[] error:error];
                     }];
   } else if ([@"sendEmailVerification" isEqualToString:call.method]) {
     [[self getAuth:call.arguments].currentUser
         sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
           [self sendResult:result forObject:nil error:error];
         }];
   } else if ([@"reload" isEqualToString:call.method]) {
     [[self getAuth:call.arguments].currentUser reloadWithCompletion:^(NSError *_Nullable error) {
       [self sendResult:result forObject:nil error:error];
     }];
   } else if ([@"delete" isEqualToString:call.method]) {
     [[self getAuth:call.arguments].currentUser deleteWithCompletion:^(NSError *_Nullable error) {
       [self sendResult:result forObject:nil error:error];
     }];
   } else if ([@"sendPasswordResetEmail" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     [[self getAuth:call.arguments] sendPasswordResetWithEmail:email
                                                    completion:^(NSError *error) {
                                                      [self sendResult:result
                                                             forObject:nil
                                                                 error:error];
                                                    }];
   } else if ([@"sendLinkToEmail" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     FIRActionCodeSettings *actionCodeSettings = [FIRActionCodeSettings new];
     actionCodeSettings.URL = [NSURL URLWithString:call.arguments[@"url"]];
     actionCodeSettings.handleCodeInApp = call.arguments[@"handleCodeInApp"];
     [actionCodeSettings setIOSBundleID:call.arguments[@"iOSBundleID"]];
     [actionCodeSettings setAndroidPackageName:call.arguments[@"androidPackageName"]
                         installIfNotAvailable:call.arguments[@"androidInstallIfNotAvailable"]
                                minimumVersion:call.arguments[@"androidMinimumVersion"]];
     [[self getAuth:call.arguments] sendSignInLinkToEmail:email
                                       actionCodeSettings:actionCodeSettings
                                               completion:^(NSError *_Nullable error) {
                                                 [self sendResult:result forObject:nil error:error];
                                               }];
   } else if ([@"isSignInWithEmailLink" isEqualToString:call.method]) {
     NSString *link = call.arguments[@"link"];
     BOOL status = [[self getAuth:call.arguments] isSignInWithEmailLink:link];
     [self sendResult:result forObject:[NSNumber numberWithBool:status] error:nil];
   } else if ([@"signInWithEmailAndLink" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     NSString *link = call.arguments[@"link"];
     [[self getAuth:call.arguments]
         signInWithEmail:email
                    link:link
              completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
                [self sendResult:result forAuthDataResult:authResult error:error];
              }];
   } else if ([@"signInWithEmailAndPassword" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     NSString *password = call.arguments[@"password"];
     [[self getAuth:call.arguments]
         signInWithEmail:email
                password:password
              completion:^(FIRAuthDataResult *authResult, NSError *error) {
                [self sendResult:result forAuthDataResult:authResult error:error];
              }];
   } else if ([@"signOut" isEqualToString:call.method]) {
     NSError *signOutError;
     BOOL status = [[self getAuth:call.arguments] signOut:&signOutError];
     if (!status) {
       NSLog(@"Error signing out: %@", signOutError);
       [self sendResult:result forObject:nil error:signOutError];
     } else {
       [self sendResult:result forObject:nil error:nil];
     }
   } else if ([@"getIdToken" isEqualToString:call.method]) {
     NSDictionary *args = call.arguments;
     BOOL refresh = [[args objectForKey:@"refresh"] boolValue];
     [[self getAuth:call.arguments].currentUser
         getIDTokenResultForcingRefresh:refresh
                             completion:^(FIRAuthTokenResult *_Nullable tokenResult,
                                          NSError *_Nullable error) {
                               NSMutableDictionary *tokenData = nil;
                               if (tokenResult != nil) {
                                 long expirationTimestamp =
                                     [tokenResult.expirationDate timeIntervalSince1970];
                                 long authTimestamp = [tokenResult.authDate timeIntervalSince1970];
                                 long issuedAtTimestamp =
                                     [tokenResult.issuedAtDate timeIntervalSince1970];

                                 tokenData = [[NSMutableDictionary alloc] initWithDictionary:@{
                                   @"token" : tokenResult.token,
                                   @"expirationTimestamp" :
                                       [NSNumber numberWithLong:expirationTimestamp],
                                   @"authTimestamp" : [NSNumber numberWithLong:authTimestamp],
                                   @"issuedAtTimestamp" :
                                       [NSNumber numberWithLong:issuedAtTimestamp],
                                   @"claims" : tokenResult.claims,
                                 }];

                                 if (tokenResult.signInProvider != nil) {
                                   tokenData[@"signInProvider"] = tokenResult.signInProvider;
                                 }
                               }

                               [self sendResult:result forObject:tokenData error:error];
                             }];
   } else if ([@"reauthenticateWithCredential" isEqualToString:call.method]) {
     [[self getAuth:call.arguments].currentUser
         reauthenticateAndRetrieveDataWithCredential:[self getCredential:call.arguments]
                                          completion:^(FIRAuthDataResult *authResult,
                                                       NSError *error) {
                                            [self sendResult:result
                                                forAuthDataResult:authResult
                                                            error:error];
                                          }];
   } else if ([@"linkWithCredential" isEqualToString:call.method]) {
     [[self getAuth:call.arguments].currentUser
         linkAndRetrieveDataWithCredential:[self getCredential:call.arguments]
                                completion:^(FIRAuthDataResult *authResult, NSError *error) {
                                  [self sendResult:result forAuthDataResult:authResult error:error];
                                }];
   } else if ([@"unlinkFromProvider" isEqualToString:call.method]) {
     NSString *provider = call.arguments[@"provider"];
     [[self getAuth:call.arguments].currentUser
         unlinkFromProvider:provider
                 completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                   [self sendResult:result forUser:user error:error];
                 }];
   } else if ([@"updateEmail" isEqualToString:call.method]) {
     NSString *email = call.arguments[@"email"];
     [[self getAuth:call.arguments].currentUser updateEmail:email
                                                 completion:^(NSError *error) {
                                                   [self sendResult:result
                                                          forObject:nil
                                                              error:error];
                                                 }];
   }
 #if TARGET_OS_IPHONE
   else if ([@"updatePhoneNumberCredential" isEqualToString:call.method]) {
     FIRPhoneAuthCredential *credential =
         (FIRPhoneAuthCredential *)[self getCredential:call.arguments];
     [[self getAuth:call.arguments].currentUser
         updatePhoneNumberCredential:credential
                          completion:^(NSError *_Nullable error) {
                            [self sendResult:result forObject:nil error:error];
                          }];
   }
 #endif
   else if ([@"updatePassword" isEqualToString:call.method]) {
     NSString *password = call.arguments[@"password"];
     [[self getAuth:call.arguments].currentUser updatePassword:password
                                                    completion:^(NSError *error) {
                                                      [self sendResult:result
                                                             forObject:nil
                                                                 error:error];
                                                    }];
   } else if ([@"updateProfile" isEqualToString:call.method]) {
     FIRUserProfileChangeRequest *changeRequest =
         [[self getAuth:call.arguments].currentUser profileChangeRequest];
     if (call.arguments[@"displayName"]) {
       changeRequest.displayName = call.arguments[@"displayName"];
     }
     if (call.arguments[@"photoUrl"]) {
       changeRequest.photoURL = [NSURL URLWithString:call.arguments[@"photoUrl"]];
     }
     [changeRequest commitChangesWithCompletion:^(NSError *error) {
       [self sendResult:result forObject:nil error:error];
     }];
   } else if ([@"signInWithCustomToken" isEqualToString:call.method]) {
     NSString *token = call.arguments[@"token"];
     [[self getAuth:call.arguments]
         signInWithCustomToken:token
                    completion:^(FIRAuthDataResult *authResult, NSError *error) {
                      [self sendResult:result forAuthDataResult:authResult error:error];
                    }];

   } else if ([@"startListeningAuthState" isEqualToString:call.method]) {
     NSNumber *identifier = [NSNumber numberWithInteger:nextHandle++];

     FIRAuthStateDidChangeListenerHandle listener = [[self getAuth:call.arguments]
         addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
           NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
           response[@"id"] = identifier;
           if (user) {
             response[@"user"] = [self dictionaryFromUser:user];
           }
           [self.channel invokeMethod:@"onAuthStateChanged" arguments:response];
         }];
     [self.authStateChangeListeners setObject:listener forKey:identifier];
     result(identifier);
   } else if ([@"stopListeningAuthState" isEqualToString:call.method]) {
     NSNumber *identifier =
         [NSNumber numberWithInteger:[call.arguments[@"id"] unsignedIntegerValue]];

     FIRAuthStateDidChangeListenerHandle listener = self.authStateChangeListeners[identifier];
     if (listener) {
       [[self getAuth:call.arguments]
           removeAuthStateDidChangeListener:self.authStateChangeListeners];
       [self.authStateChangeListeners removeObjectForKey:identifier];
       result(nil);
     } else {
       result([FlutterError
           errorWithCode:@"ERROR_LISTENER_NOT_FOUND"
                 message:[NSString stringWithFormat:@"Listener with identifier '%d' not found.",
                                                    identifier.intValue]
                 details:nil]);
     }
   }
 #if TARGET_OS_IPHONE
   else if ([@"verifyPhoneNumber" isEqualToString:call.method]) {
     NSString *phoneNumber = call.arguments[@"phoneNumber"];
     NSNumber *handle = call.arguments[@"handle"];
     [[FIRPhoneAuthProvider providerWithAuth:[self getAuth:call.arguments]]
         verifyPhoneNumber:phoneNumber
                UIDelegate:nil
                completion:^(NSString *verificationID, NSError *error) {
                  if (error) {
                    [self.channel invokeMethod:@"phoneVerificationFailed"
                                     arguments:@{
                                       @"exception" : [self mapVerifyPhoneError:error],
                                       @"handle" : handle
                                     }];
                  } else {
                    [self.channel
                        invokeMethod:@"phoneCodeSent"
                           arguments:@{@"verificationId" : verificationID, @"handle" : handle}];
                  }
                }];
     result(nil);
   } else if ([@"signInWithPhoneNumber" isEqualToString:call.method]) {
     NSString *verificationId = call.arguments[@"verificationId"];
     NSString *smsCode = call.arguments[@"smsCode"];

     FIRPhoneAuthCredential *credential = [[FIRPhoneAuthProvider
         providerWithAuth:[self getAuth:call.arguments]] credentialWithVerificationID:verificationId
                                                                     verificationCode:smsCode];
     [[self getAuth:call.arguments]
         signInAndRetrieveDataWithCredential:credential
                                  completion:^(FIRAuthDataResult *authResult,
                                               NSError *_Nullable error) {
                                    [self sendResult:result
                                        forAuthDataResult:authResult
                                                    error:error];
                                  }];
   }
 #endif
   else if ([@"setLanguageCode" isEqualToString:call.method]) {
     NSString *language = call.arguments[@"language"];
     [[self getAuth:call.arguments] setLanguageCode:language];
     [self sendResult:result forObject:nil error:nil];
   } else if ([@"confirmPasswordReset" isEqualToString:call.method]) {
     NSString *oobCode = call.arguments[@"oobCode"];
     NSString *newPassword = call.arguments[@"newPassword"];

     [[self getAuth:call.arguments] confirmPasswordResetWithCode:oobCode
                                                     newPassword:newPassword
                                                      completion:^(NSError *_Nullable error) {
                                                        [self sendResult:result
                                                               forObject:nil
                                                                   error:error];
                                                      }];

   } else {
     result(FlutterMethodNotImplemented);
   }
 }


*/
