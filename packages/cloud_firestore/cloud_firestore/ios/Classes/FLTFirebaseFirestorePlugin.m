// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Public/FLTFirebaseFirestorePlugin.h"

NSString *const kFLTFirebaseFirestoreChannelName = @"plugins.flutter.io/cloud_firestore";

static FlutterError *getFlutterError(NSError *error) {
  if (error == nil) return nil;

  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", (long) error.code]
                             message:error.domain
                             details:error.localizedDescription];
}

static FIRFirestore *getFirestore(NSDictionary *arguments) {
  FIRApp *app = [FLTFirebasePlugin firebaseAppNamed:arguments[@"appName"]];
  // TODO settings lock
  return [FIRFirestore firestoreForApp:app];
}

static FIRDocumentReference *getDocumentReference(NSDictionary *arguments) {
  return [getFirestore(arguments) documentWithPath:arguments[@"path"]];
}

// TODO remove
// TODO remove
// TODO remove
// TODO remove
static NSArray *getDocumentValues(NSDictionary *document, NSArray *orderBy,
                                  BOOL isCollectionGroup) {
  NSMutableArray *values = [[NSMutableArray alloc] init];
  NSDictionary *documentData = document[@"data"];
  if (orderBy) {
    for (id item in orderBy) {
      NSArray *orderByParameters = item;
      NSObject *field = orderByParameters[0];

      if ([field isKindOfClass:[FIRFieldPath class]]) {
        if ([field isEqual:FIRFieldPath.documentID]) {
          // This is also checked by an assertion on the Dart side.
          [NSException
              raise:@"Invalid use of FieldValue.documentId"
             format:
                 @"You cannot order by the document id when using "
                 "{start/end}{At/After/Before}Document as the library will order by the document"
                 " id implicitly in order to to add other fields to the order clause."];
        } else {
          // Unsupported type.
        }
      } else if ([field isKindOfClass:[NSString class]]) {
        NSString *fieldName = orderByParameters[0];
        if ([fieldName rangeOfString:@"."].location != NSNotFound) {
          NSArray *fieldNameParts = [fieldName componentsSeparatedByString:@"."];
          NSDictionary *currentMap = [documentData objectForKey:[fieldNameParts objectAtIndex:0]];
          for (int i = 1; i < [fieldNameParts count] - 1; i++) {
            currentMap = [currentMap objectForKey:[fieldNameParts objectAtIndex:i]];
          }
          [values
              addObject:[currentMap objectForKey:[fieldNameParts
                  objectAtIndex:[fieldNameParts count] - 1]]];
        } else {
          [values addObject:[documentData objectForKey:fieldName]];
        }
      } else {
        // Invalid type.
      }
    }
  }
  if (isCollectionGroup) {
    NSString *path = document[@"path"];
    [values addObject:path];
  } else {
    NSString *documentId = document[@"id"];
    [values addObject:documentId];
  }
  return values;
}

static FIRQuery *getQuery(NSDictionary *arguments) {
  FIRQuery *query;
  NSDictionary *parameters = arguments[@"parameters"];
  NSArray *whereConditions = parameters[@"where"];
  BOOL isCollectionGroup = ((NSNumber *) arguments[@"isCollectionGroup"]).boolValue;

  if (isCollectionGroup) {
    query = [getFirestore(arguments) collectionGroupWithID:arguments[@"path"]];
  } else {
    query = [getFirestore(arguments) collectionWithPath:arguments[@"path"]];
  }

  // Filters
  for (id item in whereConditions) {
    NSArray *condition = item;
    FIRFieldPath *fieldPath = (FIRFieldPath *) condition[0];
    NSString *operator = condition[1];
    id value = condition[2];
    if ([operator isEqualToString:@"=="]) {
      query = [query queryWhereFieldPath:fieldPath isEqualTo:value];
    } else if ([operator isEqualToString:@"<"]) {
      query = [query queryWhereFieldPath:fieldPath isLessThan:value];
    } else if ([operator isEqualToString:@"<="]) {
      query = [query queryWhereFieldPath:fieldPath isLessThanOrEqualTo:value];
    } else if ([operator isEqualToString:@">"]) {
      query = [query queryWhereFieldPath:fieldPath isGreaterThan:value];
    } else if ([operator isEqualToString:@">="]) {
      query = [query queryWhereFieldPath:fieldPath isGreaterThanOrEqualTo:value];
    } else if ([operator isEqualToString:@"array-contains"]) {
      query = [query queryWhereFieldPath:fieldPath arrayContains:value];
    } else if ([operator isEqualToString:@"array-contains-any"]) {
      query = [query queryWhereFieldPath:fieldPath arrayContainsAny:value];
    } else if ([operator isEqualToString:@"in"]) {
      query = [query queryWhereFieldPath:fieldPath in:value];
    } else {
      NSLog(@"FLTFirebaseFirestore: An invalid query operator %@ was received but not handled.", operator);
    }
  }

  // Limit
  id limit = parameters[@"limit"];
  if (![limit isEqual:[NSNull null]]) {
    query = [query queryLimitedTo:((NSNumber *) limit).intValue];
  }

  // Limit To Last
  id limitToLast = parameters[@"limitToLast"];
  if (![limitToLast isEqual:[NSNull null]]) {
    query = [query queryLimitedTo:((NSNumber *) limitToLast).intValue];
  }

  // Ordering
  NSArray *orderBy = parameters[@"orderBy"];
  if ([orderBy isEqual:[NSNull null]]) {
    // We return early if no ordering set as cursor queries below require at least one orderBy set
    return query;
  }

  for (NSArray *orderByParameters in orderBy) {
    FIRFieldPath *fieldPath = (FIRFieldPath *) orderByParameters[0];
    NSNumber *descending = orderByParameters[1];
    query = [query queryOrderedByFieldPath:fieldPath descending:[descending boolValue]];
  }

  // Start At
  id startAt = parameters[@"startAt"];
  if (![startAt isEqual:[NSNull null]]) query = [query queryStartingAtValues:(NSArray *) startAt];
  // Start After
  id startAfter = parameters[@"startAfter"];
  if (![startAfter isEqual:[NSNull null]]) query = [query queryStartingAfterValues:(NSArray *) startAfter];
  // End At
  id endAt = parameters[@"endAt"];
  if (![endAt isEqual:[NSNull null]]) query = [query queryEndingAtValues:(NSArray *) endAt];
  // End Before
  id endBefore = parameters[@"endBefore"];
  if (![endBefore isEqual:[NSNull null]]) query = [query queryEndingBeforeValues:(NSArray *) endBefore];

  return query;
}

static FIRFirestoreSource getSource(NSDictionary *arguments) {
  NSString *source = arguments[@"source"];
  if ([@"server" isEqualToString:source]) {
    return FIRFirestoreSourceServer;
  }
  if ([@"cache" isEqualToString:source]) {
    return FIRFirestoreSourceCache;
  }
  return FIRFirestoreSourceDefault;
}

static NSDictionary *parseQuerySnapshot(FIRQuerySnapshot *snapshot) {
  NSMutableArray *paths = [NSMutableArray array];
  NSMutableArray *documents = [NSMutableArray array];
  NSMutableArray *metadatas = [NSMutableArray array];
  for (FIRDocumentSnapshot *document in snapshot.documents) {
    [paths addObject:document.reference.path];
    [documents addObject:document.data];
    [metadatas addObject:@{
        @"hasPendingWrites": @(document.metadata.hasPendingWrites),
        @"isFromCache": @(document.metadata.isFromCache),
    }];
  }
  NSMutableArray *documentChanges = [NSMutableArray array];
  for (FIRDocumentChange *documentChange in snapshot.documentChanges) {
    NSString *type;
    switch (documentChange.type) {
      case FIRDocumentChangeTypeAdded:type = @"DocumentChangeType.added";
        break;
      case FIRDocumentChangeTypeModified:type = @"DocumentChangeType.modified";
        break;
      case FIRDocumentChangeTypeRemoved:type = @"DocumentChangeType.removed";
        break;
    }

    NSNumber *oldIndex;
    NSNumber *newIndex;

    // Note the Firestore C++ SDK here returns a maxed UInt that is != NSUIntegerMax, so we make one ourselves so we can
    // convert to -1 for Dart.
    NSUInteger MAX_VAL = (NSUInteger) [@(-1) integerValue];
    if (documentChange.newIndex == NSNotFound || documentChange.newIndex == 4294967295
        || documentChange.newIndex == MAX_VAL) {
      newIndex = @([@(-1) doubleValue]);
    } else {
      newIndex = @([@(documentChange.newIndex) doubleValue]);
    }
    if (documentChange.oldIndex == NSNotFound || documentChange.oldIndex == 4294967295
        || documentChange.oldIndex == MAX_VAL) {
      oldIndex = @([@(-1) doubleValue]);
    } else {
      oldIndex = @([@(documentChange.oldIndex) doubleValue]);
    }

    [documentChanges addObject:@{
        @"type": type,
        @"document": documentChange.document.data,
        @"path": documentChange.document.reference.path,
        @"oldIndex": oldIndex,
        @"newIndex": newIndex,
        @"metadata": @{
            @"hasPendingWrites": @(documentChange.document.metadata.hasPendingWrites),
            @"isFromCache": @(documentChange.document.metadata.isFromCache),
        },
    }];
  }

  return @{
      @"paths": paths,
      @"documentChanges": documentChanges,
      @"documents": documents,
      @"metadatas": metadatas,
      @"metadata": @{
          @"hasPendingWrites": @(snapshot.metadata.hasPendingWrites),
          @"isFromCache": @(snapshot.metadata.isFromCache),
      }
  };
}

@interface FLTFirebaseFirestorePlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation FLTFirebaseFirestorePlugin {
  NSMutableDictionary<NSNumber *, id<FIRListenerRegistration>> *_listeners;
  int _nextListenerHandle;
  NSMutableDictionary *transactions;
  // TODO remove
  NSMutableDictionary *transactionResults;
  // TODO remove
  NSMutableDictionary<NSNumber *, FIRWriteBatch *> *_batches;
  int _nextBatchHandle;
}

// Returns a singleton instance of the Firebase Firestore plugin.
+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static FLTFirebaseFirestorePlugin *instance;

  dispatch_once(&onceToken, ^{
    instance = [[FLTFirebaseFirestorePlugin alloc] init];
    // Register with the Flutter Firebase plugin registry.
    [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:instance];
  });

  return instance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTFirebaseFirestoreReaderWriter *firestoreReaderWriter = [FLTFirebaseFirestoreReaderWriter new];
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kFLTFirebaseFirestoreChannelName
                                  binaryMessenger:[registrar messenger]
                                            codec:[FlutterStandardMethodCodec
                                                codecWithReaderWriter:firestoreReaderWriter]];
  FLTFirebaseFirestorePlugin *instance = [FLTFirebaseFirestorePlugin sharedInstance];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  // TODO remove listeners
  self.channel = nil;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _listeners = [NSMutableDictionary<NSNumber *, id<FIRListenerRegistration>> dictionary];
    // TODO Batches now client side
    _batches = [NSMutableDictionary<NSNumber *, FIRWriteBatch *> dictionary];
    _nextListenerHandle = 0;
    _nextBatchHandle = 0;
    transactions = [NSMutableDictionary<NSNumber *, FIRTransaction *> dictionary];
    transactionResults = [NSMutableDictionary<NSNumber *, id> dictionary];
  }

  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  __weak __typeof__(self) weakSelf = self;
  void (^defaultCompletionBlock)(NSError *) = ^(NSError *error) {
    result(getFlutterError(error));
  };
  if ([@"Firestore#runTransaction" isEqualToString:call.method]) {
    [getFirestore(call.arguments)
        runTransactionWithBlock:^id(FIRTransaction *transaction, NSError **pError) {
          NSNumber *transactionId = call.arguments[@"transactionId"];
          NSNumber *transactionTimeout = call.arguments[@"transactionTimeout"];

          self->transactions[transactionId] = transaction;

          dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

          [weakSelf.channel invokeMethod:@"DoTransaction"
                               arguments:call.arguments
                                  result:^(id doTransactionResult) {
                                    FLTFirebaseFirestorePlugin *currentSelf = weakSelf;
                                    currentSelf->transactionResults[transactionId] =
                                        doTransactionResult;
                                    dispatch_semaphore_signal(semaphore);
                                  }];

          dispatch_semaphore_wait(
              semaphore,
              dispatch_time(DISPATCH_TIME_NOW, [transactionTimeout integerValue] * 1000000));

          return self->transactionResults[transactionId];
        }
                     completion:^(id transactionResult, NSError *error) {
                       if (error != nil) {
                         result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long) error.code]
                                                    message:error.localizedDescription
                                                    details:nil]);
                       }
                       result(transactionResult);
                     }];
  } else if ([@"Transaction#get" isEqualToString:call.method]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSNumber *transactionId = call.arguments[@"transactionId"];
      FIRDocumentReference *document = getDocumentReference(call.arguments);
      FIRTransaction *transaction = self->transactions[transactionId];
      NSError *error = [[NSError alloc] init];

      FIRDocumentSnapshot *snapshot = [transaction getDocument:document error:&error];

      if (error != nil) {
        result([FlutterError errorWithCode:[NSString stringWithFormat:@"%tu", [error code]]
                                   message:[error localizedDescription]
                                   details:nil]);
      } else if (snapshot != nil) {
        result(@{
                   @"path": snapshot.reference.path,
                   @"data": snapshot.exists ? snapshot.data : [NSNull null],
                   @"metadata": @{
                @"hasPendingWrites": @(snapshot.metadata.hasPendingWrites),
                @"isFromCache": @(snapshot.metadata.isFromCache),
            },
               });
      } else {
        result(nil);
      }
    });
  } else if ([@"Transaction#update" isEqualToString:call.method]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSNumber *transactionId = call.arguments[@"transactionId"];
      FIRDocumentReference *document = getDocumentReference(call.arguments);
      FIRTransaction *transaction = self->transactions[transactionId];

      [transaction updateData:call.arguments[@"data"] forDocument:document];
      result(nil);
    });
  } else if ([@"Transaction#set" isEqualToString:call.method]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSNumber *transactionId = call.arguments[@"transactionId"];
      FIRDocumentReference *document = getDocumentReference(call.arguments);
      FIRTransaction *transaction = self->transactions[transactionId];

      [transaction setData:call.arguments[@"data"] forDocument:document];
      result(nil);
    });
  } else if ([@"Transaction#delete" isEqualToString:call.method]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSNumber *transactionId = call.arguments[@"transactionId"];
      FIRDocumentReference *document = getDocumentReference(call.arguments);
      FIRTransaction *transaction = self->transactions[transactionId];

      [transaction deleteDocument:document];
      result(nil);
    });
  } else if ([@"DocumentReference#setData" isEqualToString:call.method]) {
    NSDictionary *options = call.arguments[@"options"];
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    // TODO options is now always defined
    if (![options isEqual:[NSNull null]] &&
        [options[@"merge"] isEqual:[NSNumber numberWithBool:YES]]) {
      [document setData:call.arguments[@"data"] merge:YES completion:defaultCompletionBlock];
    } else if (![options isEqual:[NSNull null]] &&
        ![options[@"mergeFields"] isEqual:[NSNull null]]) {
      [document setData:call.arguments[@"data"]
            mergeFields:options[@"mergeFields"]
             completion:defaultCompletionBlock];
    } else {
      [document setData:call.arguments[@"data"] completion:defaultCompletionBlock];
    }
  } else if ([@"DocumentReference#updateData" isEqualToString:call.method]) {
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    [document updateData:call.arguments[@"data"] completion:defaultCompletionBlock];
  } else if ([@"DocumentReference#delete" isEqualToString:call.method]) {
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    [document deleteDocumentWithCompletion:defaultCompletionBlock];
  } else if ([@"DocumentReference#get" isEqualToString:call.method]) {
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    FIRFirestoreSource source = getSource(call.arguments);
    [document
        getDocumentWithSource:source
                   completion:^(FIRDocumentSnapshot *_Nullable snapshot, NSError *_Nullable error) {
                     if (snapshot == nil) {
                       result(getFlutterError(error));
                     } else {
                       result(@{
                                  @"path": snapshot.reference.path,
                                  @"data": snapshot.exists ? snapshot.data : [NSNull null],
                                  @"metadata": @{
                               @"hasPendingWrites": @(snapshot.metadata.hasPendingWrites),
                               @"isFromCache": @(snapshot.metadata.isFromCache),
                           },
                              });
                     }
                   }];
  } else if ([@"Query#addSnapshotListener" isEqualToString:call.method]) {
    __block NSNumber *handle = @(_nextListenerHandle++);
    FIRQuery *query;
    @try {
      query = getQuery(call.arguments);
    } @catch (NSException *exception) {
      result([FlutterError errorWithCode:@"invalid_query"
                                 message:[exception name]
                                 details:[exception reason]]);
    }
    NSNumber *includeMetadataChanges = call.arguments[@"includeMetadataChanges"];
    id<FIRListenerRegistration> listener = [query
        addSnapshotListenerWithIncludeMetadataChanges:includeMetadataChanges.boolValue
                                             listener:^(FIRQuerySnapshot *_Nullable snapshot,
                                                        NSError *_Nullable error) {
                                               if (snapshot == nil) {
                                                 // TODO should invokeMethod
                                                 result(getFlutterError(error));
                                                 return;
                                               }
                                               NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
                                               arguments[@"snapshot"] =
                                                   [parseQuerySnapshot(snapshot) mutableCopy];
                                               arguments[@"handle"] = handle;
                                               [weakSelf.channel invokeMethod:@"QuerySnapshot#event"
                                                                    arguments:arguments];
                                             }];
    _listeners[handle] = listener;
    result(handle);
  } else if ([@"DocumentReference#addSnapshotListener" isEqualToString:call.method]) {
    __block NSNumber *handle = @(_nextListenerHandle++);
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    NSNumber *includeMetadataChanges = call.arguments[@"includeMetadataChanges"];
    id<FIRListenerRegistration> listener = [document
        addSnapshotListenerWithIncludeMetadataChanges:includeMetadataChanges.boolValue
                                             listener:^(FIRDocumentSnapshot *snapshot,
                                                        NSError *_Nullable error) {
                                               if (snapshot == nil) {
                                                 // TODO should invokeMethod
                                                 result(getFlutterError(error));
                                                 return;
                                               }

                                               NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
                                               arguments[@"handle"] = handle;
                                               arguments[@"snapshot"] = @{
                                                   @"path": snapshot.reference.path,
                                                   @"data": snapshot.data,
                                                   @"metadata": @{
                                                       @"hasPendingWrites":
                                                       @(snapshot.metadata.hasPendingWrites),
                                                       @"isFromCache":
                                                       @(snapshot.metadata.isFromCache),
                                                   },
                                               };

                                               [weakSelf.channel
                                                   invokeMethod:@"DocumentSnapshot#event"
                                                      arguments:arguments];
                                             }];
    _listeners[handle] = listener;
    result(handle);
  } else if ([@"Query#getDocuments" isEqualToString:call.method]) {
    FIRQuery *query;
    FIRFirestoreSource source = getSource(call.arguments);
    @try {
      query = getQuery(call.arguments);
    } @catch (NSException *exception) {
      result([FlutterError errorWithCode:@"invalid_query"
                                 message:[exception name]
                                 details:[exception reason]]);
    }

    [query
        getDocumentsWithSource:source
                    completion:^(FIRQuerySnapshot *_Nullable snapshot, NSError *_Nullable error) {
                      if (snapshot == nil) {
                        result(getFlutterError(error));
                        return;
                      }
                      result(parseQuerySnapshot(snapshot));
                    }];
  } else if ([@"removeListener" isEqualToString:call.method]) {
    NSNumber *handle = call.arguments[@"handle"];
    [[_listeners objectForKey:handle] remove];
    [_listeners removeObjectForKey:handle];
    result(nil);
    // TODO gone!
  } else if ([@"WriteBatch#create" isEqualToString:call.method]) {
    __block NSNumber *handle = [NSNumber numberWithInt:_nextBatchHandle++];
    FIRWriteBatch *batch = [getFirestore(call.arguments) batch];
    _batches[handle] = batch;
    result(handle);
    // TODO gone!
  } else if ([@"WriteBatch#setData" isEqualToString:call.method]) {
    NSNumber *handle = call.arguments[@"handle"];
    NSDictionary *options = call.arguments[@"options"];
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    FIRWriteBatch *batch = [_batches objectForKey:handle];
    // TODO options always defined
    if (![options isEqual:[NSNull null]] &&
        [options[@"merge"] isEqual:[NSNumber numberWithBool:YES]]) {
      [batch setData:call.arguments[@"data"] forDocument:document merge:YES];
    } else {
      [batch setData:call.arguments[@"data"] forDocument:document];
    }
    result(nil);
    // TODO gone!
  } else if ([@"WriteBatch#updateData" isEqualToString:call.method]) {
    NSNumber *handle = call.arguments[@"handle"];
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    FIRWriteBatch *batch = [_batches objectForKey:handle];
    [batch updateData:call.arguments[@"data"] forDocument:document];
    result(nil);
    // TODO gone!
  } else if ([@"WriteBatch#delete" isEqualToString:call.method]) {
    NSNumber *handle = call.arguments[@"handle"];
    FIRDocumentReference *document = getDocumentReference(call.arguments);
    FIRWriteBatch *batch = [_batches objectForKey:handle];
    [batch deleteDocument:document];
    result(nil);
  } else if ([@"WriteBatch#commit" isEqualToString:call.method]) {
    NSNumber *handle = call.arguments[@"handle"];
    FIRWriteBatch *batch = [_batches objectForKey:handle];
    [batch commitWithCompletion:defaultCompletionBlock];
    [_batches removeObjectForKey:handle];
  } else if ([@"Firestore#enablePersistence" isEqualToString:call.method]) {
    bool enable = ((NSNumber *) call.arguments[@"enable"]).boolValue;
    FIRFirestoreSettings *settings = [[FIRFirestoreSettings alloc] init];
    settings.persistenceEnabled = enable;
    FIRFirestore *db = getFirestore(call.arguments);
    db.settings = settings;
    result(nil);
  } else if ([@"Firestore#settings" isEqualToString:call.method]) {
    FIRFirestoreSettings *settings = [[FIRFirestoreSettings alloc] init];
    if (![call.arguments[@"persistenceEnabled"] isEqual:[NSNull null]]) {
      settings.persistenceEnabled = ((NSNumber *) call.arguments[@"persistenceEnabled"]).boolValue;
    }
    if (![call.arguments[@"host"] isEqual:[NSNull null]]) {
      settings.host = (NSString *) call.arguments[@"host"];
    }
    if (![call.arguments[@"sslEnabled"] isEqual:[NSNull null]]) {
      settings.sslEnabled = ((NSNumber *) call.arguments[@"sslEnabled"]).boolValue;
    }
    if (![call.arguments[@"cacheSizeBytes"] isEqual:[NSNull null]]) {
      settings.cacheSizeBytes = ((NSNumber *) call.arguments[@"cacheSizeBytes"]).intValue;
    }
    FIRFirestore *db = getFirestore(call.arguments);
    db.settings = settings;
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}
- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *)firebase_app {
  return @{};
}
- (NSString *_Nonnull)firebaseLibraryName {
  return LIBRARY_NAME;
}
- (NSString *_Nonnull)firebaseLibraryVersion {
  return LIBRARY_VERSION;
}
- (NSString *_Nonnull)flutterChannelName {
  return kFLTFirebaseFirestoreChannelName;
}

@end
