// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.cloudfirestore;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.SparseArray;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.Timestamp;
import com.google.firebase.firestore.Blob;
import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.DocumentChange;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.FirebaseFirestoreSettings;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.MetadataChanges;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.QuerySnapshot;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Source;
import com.google.firebase.firestore.Transaction;
import com.google.firebase.firestore.WriteBatch;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.common.StandardMethodCodec;

// TODO move to core
class FirebaseSharedPreferences {
  private static final String PREFERENCES_FILE = "io.flutter.plugins.firebase";
  private static FirebaseSharedPreferences sharedInstance = new FirebaseSharedPreferences();
  private SharedPreferences preferences;
  private Context applicationContext;

  public static FirebaseSharedPreferences getSharedInstance() {
    return sharedInstance;
  }

  public void setApplicationContext(Context context) {
    applicationContext = context;
  }

  public boolean contains(String key) {
    return getPreferences().contains(key);
  }

  // Boolean
  public void setBooleanValue(String key, boolean value) {
    getPreferences().edit().putBoolean(key, value).apply();
  }

  public boolean getBooleanValue(String key, boolean defaultValue) {
    return getPreferences().getBoolean(key, defaultValue);
  }

  // Int
  public void setIntValue(String key, int value) {
    getPreferences().edit().putInt(key, value).apply();
  }

  public int getIntValue(String key, int defaultValue) {
    return getPreferences().getInt(key, defaultValue);
  }

  // Long
  public void setLongValue(String key, long value) {
    getPreferences().edit().putLong(key, value).apply();
  }

  public long getLongValue(String key, long defaultValue) {
    return getPreferences().getLong(key, defaultValue);
  }

  // String
  public void setStringValue(String key, String value) {
    getPreferences().edit().putString(key, value).apply();
  }

  public String getStringValue(String key, String defaultValue) {
    return getPreferences().getString(key, defaultValue);
  }

  public void clearAll() {
    getPreferences().edit().clear().apply();
  }

  private SharedPreferences getPreferences() {
    if (preferences == null) {
      preferences = applicationContext.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE);
    }
    return preferences;
  }
}

public class CloudFirestorePlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final String TAG = "CloudFirestorePlugin";

  private static HashMap<String, Boolean> settingsLock = new HashMap<>();
  private final SparseArray<EventObserver> observers = new SparseArray<>();
  private final SparseArray<DocumentObserver> documentObservers = new SparseArray<>();
  private final SparseArray<ListenerRegistration> listenerRegistrations = new SparseArray<>();
  private final SparseArray<WriteBatch> batches = new SparseArray<>();
  private final SparseArray<Transaction> transactions = new SparseArray<>();
  private final SparseArray<TaskCompletionSource> completionTasks = new SparseArray<>();
  private MethodChannel channel;
  private Activity activity;
  // Handles are ints used as indexes into the sparse array of active observers
  private int nextListenerHandle = 0;
  private int nextBatchHandle = 0;

  @SuppressWarnings("unused")
  public static void registerWith(PluginRegistry.Registrar registrar) {
    CloudFirestorePlugin instance = new CloudFirestorePlugin();
    instance.activity = registrar.activity();
    instance.initInstance(registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    attachToActivity(activityPluginBinding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachToActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    attachToActivity(activityPluginBinding);
  }

  @Override
  public void onDetachedFromActivity() {
    detachToActivity();
  }

  private void attachToActivity(ActivityPluginBinding activityPluginBinding) {
    this.activity = activityPluginBinding.getActivity();
  }

  private void detachToActivity() {
    this.activity = null;
  }

  private Task<Void> writeBatchCommit(Map<String, Object> arguments) {
    return Tasks.call(
        () -> {
          //          String appName = (String) Objects.requireNonNull(arguments.get(KEY_APP_NAME));
          //          FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
          //          try {
          //            firebaseApp.delete();
          //          } catch (IllegalStateException appNotFoundException) {
          //            // Ignore app not found exceptions.
          //          }

          return null;
        });
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    Task methodCallTask;

    switch (call.method) {
      case "Firestore#runTransaction":
        break;
      case "WriteBatch#commit":
        methodCallTask = writeBatchCommit(call.arguments());
    }

    switch (call.method) {
      case "Firestore#runTransaction":
        //      {
        //        final TaskCompletionSource<Map<String, Object>> transactionTCS =
        //                new TaskCompletionSource<>();
        //        final Task<Map<String, Object>> transactionTCSTask = transactionTCS.getTask();
        //
        //        final Map<String, Object> arguments = call.arguments();
        //        getFirestore(arguments)
        //                .runTransaction(
        //                        transaction -> {
        //                          // Store transaction.
        //                          int transactionId = (Integer) arguments.get("transactionId");
        //                          transactions.append(transactionId, transaction);
        //                          completionTasks.append(transactionId, transactionTCS);
        //
        //                          // Start operations on Dart side.
        //                          activity.runOnUiThread(
        //                                  new Runnable() {
        //                                    @Override
        //                                    public void run() {
        //                                      channel.invokeMethod(
        //                                              "DoTransaction",
        //                                              arguments,
        //                                              new Result() {
        //                                                @SuppressWarnings("unchecked")
        //                                                @Override
        //                                                public void success(Object
        // doTransactionResult) {
        //                                                  transactionTCS.trySetResult(
        //                                                          (Map<String, Object>)
        // doTransactionResult);
        //                                                }
        //
        //                                                @Override
        //                                                public void error(
        //                                                        String errorCode, String
        // errorMessage, Object errorDetails) {
        //                                                  transactionTCS.trySetException(
        //                                                          new Exception("DoTransaction
        // failed: " + errorMessage));
        //                                                }
        //
        //                                                @Override
        //                                                public void notImplemented() {
        //                                                  transactionTCS.trySetException(
        //                                                          new Exception("DoTransaction not
        // implemented"));
        //                                                }
        //                                              });
        //                                    }
        //                                  });
        //
        //                          // Wait till transaction is complete.
        //                          try {
        //                            String timeoutKey = "transactionTimeout";
        //                            long timeout = ((Number)
        // arguments.get(timeoutKey)).longValue();
        //                            final Map<String, Object> transactionResult =
        //                                    Tasks.await(transactionTCSTask, timeout,
        // TimeUnit.MILLISECONDS);
        //
        //                            // Once transaction completes return the result to the Dart
        // side.
        //                            return new TransactionResult(transactionResult);
        //                          } catch (Exception e) {
        //                            Log.e(TAG, e.getMessage(), e);
        //                            return new TransactionResult(e);
        //                          }
        //                        })
        //                .addOnCompleteListener(
        //                        task -> {
        //                          if (!task.isSuccessful()) {
        //                            result.error(
        //                                    "Error performing transaction",
        // task.getException().getMessage(), null);
        //                            return;
        //                          }
        //
        //                          TransactionResult transactionResult = task.getResult();
        //                          if (transactionResult.exception == null) {
        //                            result.success(transactionResult.result);
        //                          } else {
        //                            result.error(
        //                                    "Error performing transaction",
        //                                    transactionResult.exception.getMessage(),
        //                                    null);
        //                          }
        //                        });
        //        break;
        //      }
        //      case "Transaction#get":
        //      {
        //        final Map<String, Object> arguments = call.arguments();
        //        final Transaction transaction = getTransaction(arguments);
        //        new AsyncTask<Void, Void, Void>() {
        //          @Override
        //          protected Void doInBackground(Void... voids) {
        //            try {
        //              DocumentSnapshot documentSnapshot =
        //                      transaction.get(getDocumentReference(arguments));
        //              final Map<String, Object> snapshotMap = new HashMap<>();
        //              snapshotMap.put("path", documentSnapshot.getReference().getPath());
        //              if (documentSnapshot.exists()) {
        //                snapshotMap.put("data", documentSnapshot.getData());
        //              } else {
        //                snapshotMap.put("data", null);
        //              }
        //              Map<String, Object> metadata = new HashMap<>();
        //              metadata.put("hasPendingWrites",
        // documentSnapshot.getMetadata().hasPendingWrites());
        //              metadata.put("isFromCache", documentSnapshot.getMetadata().isFromCache());
        //              snapshotMap.put("metadata", metadata);
        //              activity.runOnUiThread(() -> result.success(snapshotMap));
        //            } catch (final Exception e) {
        //              activity.runOnUiThread(
        //                      () -> result.error("Error performing Transaction#get",
        // e.getMessage(), null));
        //            }
        //            return null;
        //          }
        //        }.execute();
        //        break;
        //      }
        //      case "Transaction#update":
        //      {
        //        final Map<String, Object> arguments = call.arguments();
        //        final Transaction transaction = getTransaction(arguments);
        //        new AsyncTask<Void, Void, Void>() {
        //          @SuppressWarnings("unchecked")
        //          @Override
        //          protected Void doInBackground(Void... voids) {
        //            Map<String, Object> data = (Map<String, Object>) arguments.get("data");
        //            try {
        //              transaction.update(getDocumentReference(arguments), data);
        //              activity.runOnUiThread(() -> result.success(null));
        //            } catch (final Exception e) {
        //              activity.runOnUiThread(
        //                      new Runnable() {
        //                        @Override
        //                        public void run() {
        //                          result.error("Error performing Transaction#update",
        // e.getMessage(), null);
        //                        }
        //                      });
        //            }
        //            return null;
        //          }
        //        }.execute();
        //        break;
        //      }
        //      case "Transaction#set":
        //      {
        //        final Map<String, Object> arguments = call.arguments();
        //        final Transaction transaction = getTransaction(arguments);
        //        new AsyncTask<Void, Void, Void>() {
        //          @SuppressWarnings("unchecked")
        //          @Override
        //          protected Void doInBackground(Void... voids) {
        //            Map<String, Object> data = (Map<String, Object>) arguments.get("data");
        //            try {
        //              transaction.set(getDocumentReference(arguments), data);
        //              activity.runOnUiThread(
        //                      new Runnable() {
        //                        @Override
        //                        public void run() {
        //                          result.success(null);
        //                        }
        //                      });
        //            } catch (final Exception e) {
        //              activity.runOnUiThread(
        //                      new Runnable() {
        //                        @Override
        //                        public void run() {
        //                          result.error("Error performing Transaction#set", e.getMessage(),
        // null);
        //                        }
        //                      });
        //            }
        //            return null;
        //          }
        //        }.execute();
        //        break;
        //      }
        //      case "Transaction#delete":
        //      {
        //        final Map<String, Object> arguments = call.arguments();
        //        final Transaction transaction = getTransaction(arguments);
        //        new AsyncTask<Void, Void, Void>() {
        //          @Override
        //          protected Void doInBackground(Void... voids) {
        //            try {
        //              transaction.delete(getDocumentReference(arguments));
        //              activity.runOnUiThread(
        //                      new Runnable() {
        //                        @Override
        //                        public void run() {
        //                          result.success(null);
        //                        }
        //                      });
        //            } catch (final Exception e) {
        //              activity.runOnUiThread(
        //                      new Runnable() {
        //                        @Override
        //                        public void run() {
        //                          result.error("Error performing Transaction#delete",
        // e.getMessage(), null);
        //                        }
        //                      });
        //            }
        //            return null;
        //          }
        //        }.execute();
        //        break;
        //      }
      case "WriteBatch#commit":
        {
          Map<String, Object> arguments = call.arguments();
          List<Object> writes = (List<Object>) arguments.get("writes");
          FirebaseFirestore firestore = getFirestore(arguments);
          WriteBatch batch = firestore.batch();

          for (Object writeMap : writes) {
            Map<String, Object> write = (Map) writeMap;
            String type = (String) write.get("type");
            String path = (String) write.get("path");
            Map<String, Object> data = (Map<String, Object>) write.get("data");

            DocumentReference documentReference = getDocumentReference(firestore, path);

            switch (type) {
              case "DELETE":
                batch = batch.delete(documentReference);
                break;
              case "UPDATE":
                batch = batch.update(documentReference, data);
                break;
              case "SET":
                Map<String, Object> options = (Map) write.get("options");

                if (options != null
                    && options.get("merge") != null
                    && (boolean) options.get("merge")) {
                  batch = batch.set(documentReference, data, SetOptions.merge());
                } else if (options != null && options.get("mergeFields") != null) {
                  List<FieldPath> fieldPathList = (List<FieldPath>) options.get("mergeFields");
                  batch =
                      batch.set(documentReference, data, SetOptions.mergeFieldPaths(fieldPathList));
                } else {
                  batch = batch.set(documentReference, data);
                }

                break;
            }
          }

          batch
              .commit()
              .addOnSuccessListener(ignored -> result.success(null))
              .addOnFailureListener(
                  e -> result.error("Error performing commit", e.getMessage(), null));
          break;
        }
      case "Query#addSnapshotListener":
        {
          Map<String, Object> arguments = call.arguments();
          int handle = nextListenerHandle++;
          EventObserver observer = new EventObserver(handle);
          observers.put(handle, observer);
          MetadataChanges metadataChanges =
              (Boolean) arguments.get("includeMetadataChanges")
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;
          listenerRegistrations.put(
              handle, getQuery(arguments).addSnapshotListener(metadataChanges, observer));
          result.success(handle);
          break;
        }
      case "DocumentReference#addSnapshotListener":
        {
          Map<String, Object> arguments = call.arguments();
          int handle = nextListenerHandle++;
          DocumentObserver observer = new DocumentObserver(handle);
          documentObservers.put(handle, observer);
          MetadataChanges metadataChanges =
              (Boolean) arguments.get("includeMetadataChanges")
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;
          listenerRegistrations.put(
              handle,
              getDocumentReference(arguments).addSnapshotListener(metadataChanges, observer));
          result.success(handle);
          break;
        }
      case "removeListener":
        {
          Map<String, Object> arguments = call.arguments();
          int handle = (Integer) arguments.get("handle");
          listenerRegistrations.get(handle).remove();
          listenerRegistrations.remove(handle);
          observers.remove(handle);
          result.success(null);
          break;
        }
      case "Query#getDocuments":
        {
          Map<String, Object> arguments = call.arguments();
          Query query = getQuery(arguments);
          Source source = getSource(arguments);
          Task<QuerySnapshot> task = query.get(source);
          task.addOnSuccessListener(
                  querySnapshot -> result.success(parseQuerySnapshot(querySnapshot)))
              .addOnFailureListener(
                  e -> result.error("Error performing getDocuments", e.getMessage(), null));
          break;
        }
      case "DocumentReference#setData":
        {
          Map<String, Object> arguments = call.arguments();
          DocumentReference documentReference = getDocumentReference(arguments);
          @SuppressWarnings("unchecked")
          Map<String, Object> options = (Map<String, Object>) arguments.get("options");
          @SuppressWarnings("unchecked")
          Map<String, Object> data = (Map<String, Object>) arguments.get("data");
          Task<Void> task;
          if (options != null && options.get("merge") != null && (boolean) options.get("merge")) {
            task = documentReference.set(data, SetOptions.merge());
          } else if (options != null && options.get("mergeFields") != null) {
            List<FieldPath> fieldPathList = (List<FieldPath>) options.get("mergeFields");
            task = documentReference.set(data, SetOptions.mergeFieldPaths(fieldPathList));
          } else {
            task = documentReference.set(data);
          }
          addDefaultListeners("setData", task, result);
          break;
        }
      case "DocumentReference#updateData":
        {
          Map<String, Object> arguments = call.arguments();
          DocumentReference documentReference = getDocumentReference(arguments);
          @SuppressWarnings("unchecked")
          Map<String, Object> data = (Map<String, Object>) arguments.get("data");
          Task<Void> task = documentReference.update(data);
          addDefaultListeners("updateData", task, result);
          break;
        }
      case "DocumentReference#get":
        {
          Map<String, Object> arguments = call.arguments();
          DocumentReference documentReference = getDocumentReference(arguments);
          Source source = getSource(arguments);
          Task<DocumentSnapshot> task = documentReference.get(source);
          task.addOnSuccessListener(
                  documentSnapshot -> {
                    Map<String, Object> snapshotMap = new HashMap<>();
                    Map<String, Object> metadata = new HashMap<>();
                    metadata.put(
                        "hasPendingWrites", documentSnapshot.getMetadata().hasPendingWrites());
                    metadata.put("isFromCache", documentSnapshot.getMetadata().isFromCache());
                    snapshotMap.put("metadata", metadata);
                    snapshotMap.put("path", documentSnapshot.getReference().getPath());
                    if (documentSnapshot.exists()) {
                      snapshotMap.put("data", documentSnapshot.getData());
                    } else {
                      snapshotMap.put("data", null);
                    }
                    result.success(snapshotMap);
                  })
              .addOnFailureListener(
                  e -> result.error("Error performing get", e.getMessage(), null));
          break;
        }
      case "DocumentReference#delete":
        {
          Map<String, Object> arguments = call.arguments();
          DocumentReference documentReference = getDocumentReference(arguments);
          Task<Void> task = documentReference.delete();
          addDefaultListeners("delete", task, result);
          break;
        }
      case "Firestore#enablePersistence":
        {
          Map<String, Object> arguments = call.arguments();
          boolean enable = (boolean) arguments.get("enable");
          FirebaseFirestoreSettings.Builder builder = new FirebaseFirestoreSettings.Builder();
          builder.setPersistenceEnabled(enable);
          FirebaseFirestoreSettings settings = builder.build();
          getFirestore(arguments).setFirestoreSettings(settings);
          result.success(null);
          break;
        }
      case "Firestore#settings":
        {
          final Map<String, Object> arguments = call.arguments();
          String appName = (String) arguments.get("appName");
          Map<String, Object> settings = (Map<String, Object>) arguments.get("settings");

          FirebaseSharedPreferences preferences = FirebaseSharedPreferences.getSharedInstance();
          preferences.setApplicationContext(activity.getApplicationContext());

          if (settings.get("persistenceEnabled") != null) {
            preferences.setBooleanValue(
                "firebase_firestore_persistence_" + appName,
                (boolean) settings.get("persistenceEnabled"));
          }

          if (settings.get("host") != null) {
            preferences.setStringValue(
                "firebase_firestore_host_" + appName, (String) settings.get("host"));
          }

          if (settings.get("sslEnabled") != null) {
            preferences.setBooleanValue(
                "firebase_firestore_ssl_" + appName, (boolean) settings.get("sslEnabled"));
          }

          if (settings.get("cacheSizeBytes") != null) {
            Object value = settings.get("cacheSizeBytes");
            Long cacheSizeBytes = null;

            if (value instanceof Long) {
              cacheSizeBytes = (Long) value;
            } else if (value instanceof Integer) {
              cacheSizeBytes = Long.valueOf((Integer) value);
            }

            if (cacheSizeBytes != null) {
              preferences.setLongValue("firebase_firestore_cache_size_" + appName, cacheSizeBytes);
            }
          }

          result.success(null);
          break;
        }
      default:
        {
          result.notImplemented();
          break;
        }
    }
  }

  private void initInstance(BinaryMessenger messenger) {
    channel =
        new MethodChannel(
            messenger,
            "plugins.flutter.io/cloud_firestore",
            new StandardMethodCodec(FirestoreMessageCodec.INSTANCE));
    channel.setMethodCallHandler(this);
  }

  private FirebaseFirestore getFirestore(Map<String, Object> arguments) {
    String appName = (String) arguments.get("app");
    FirebaseFirestore instance = FirebaseFirestore.getInstance(FirebaseApp.getInstance(appName));
    setFirestoreSettings(instance, appName);
    return instance;
  }

  private void setFirestoreSettings(FirebaseFirestore firebaseFirestore, String appName) {
    // Ensure not already been set
    if (settingsLock.containsKey(appName)) return;

    FirebaseSharedPreferences preferences = FirebaseSharedPreferences.getSharedInstance();
    preferences.setApplicationContext(activity.getApplicationContext());
    FirebaseFirestoreSettings.Builder firestoreSettings = new FirebaseFirestoreSettings.Builder();

    long cacheSizeBytes =
        preferences.getLongValue(
            "firebase_firestore_cache_size_" + appName,
            firebaseFirestore.getFirestoreSettings().getCacheSizeBytes());

    String host =
        preferences.getStringValue(
            "firebase_firestore_host_" + appName,
            firebaseFirestore.getFirestoreSettings().getHost());

    boolean persistence =
        preferences.getBooleanValue(
            "firebase_firestore_persistence_" + appName,
            firebaseFirestore.getFirestoreSettings().isPersistenceEnabled());

    boolean ssl =
        preferences.getBooleanValue(
            "firebase_firestore_ssl_" + appName,
            firebaseFirestore.getFirestoreSettings().isSslEnabled());

    if (cacheSizeBytes == -1) {
      firestoreSettings.setCacheSizeBytes(FirebaseFirestoreSettings.CACHE_SIZE_UNLIMITED);
    } else {
      firestoreSettings.setCacheSizeBytes(cacheSizeBytes);
    }

    firestoreSettings.setHost(host);
    firestoreSettings.setPersistenceEnabled(persistence);
    firestoreSettings.setSslEnabled(ssl);

    firebaseFirestore.setFirestoreSettings(firestoreSettings.build());
    settingsLock.put(appName, true);
  }

  private Query getReference(Map<String, Object> arguments) {
    if ((boolean) arguments.get("isCollectionGroup")) return getCollectionGroupReference(arguments);
    else return getCollectionReference(arguments);
  }

  private Query getCollectionGroupReference(Map<String, Object> arguments) {
    String path = (String) arguments.get("path");
    return getFirestore(arguments).collectionGroup(path);
  }

  private CollectionReference getCollectionReference(Map<String, Object> arguments) {
    String path = (String) arguments.get("path");
    return getFirestore(arguments).collection(path);
  }

  private DocumentReference getDocumentReference(Map<String, Object> arguments) {
    String path = (String) arguments.get("path");
    return getFirestore(arguments).document(path);
  }

  private DocumentReference getDocumentReference(FirebaseFirestore firestore, String path) {
    return firestore.document(path);
  }

  private Source getSource(Map<String, Object> arguments) {
    String source = (String) arguments.get("source");
    switch (source) {
      case "server":
        return Source.SERVER;
      case "cache":
        return Source.CACHE;
      default:
        return Source.DEFAULT;
    }
  }

  private Map<String, Object> parseQuerySnapshot(QuerySnapshot querySnapshot) {
    if (querySnapshot == null) return new HashMap<>();
    Map<String, Object> data = new HashMap<>();
    List<String> paths = new ArrayList<>();
    List<Map<String, Object>> documents = new ArrayList<>();
    List<Map<String, Object>> metadatas = new ArrayList<>();
    for (DocumentSnapshot document : querySnapshot.getDocuments()) {
      paths.add(document.getReference().getPath());
      documents.add(document.getData());
      Map<String, Object> metadata = new HashMap<String, Object>();
      metadata.put("hasPendingWrites", document.getMetadata().hasPendingWrites());
      metadata.put("isFromCache", document.getMetadata().isFromCache());
      metadatas.add(metadata);
    }
    data.put("paths", paths);
    data.put("documents", documents);
    data.put("metadatas", metadatas);

    List<Map<String, Object>> documentChanges = new ArrayList<>();
    for (DocumentChange documentChange : querySnapshot.getDocumentChanges()) {
      Map<String, Object> change = new HashMap<>();
      String type = null;
      switch (documentChange.getType()) {
        case ADDED:
          type = "DocumentChangeType.added";
          break;
        case MODIFIED:
          type = "DocumentChangeType.modified";
          break;
        case REMOVED:
          type = "DocumentChangeType.removed";
          break;
      }
      change.put("type", type);
      change.put("oldIndex", documentChange.getOldIndex());
      change.put("newIndex", documentChange.getNewIndex());
      change.put("document", documentChange.getDocument().getData());
      change.put("path", documentChange.getDocument().getReference().getPath());
      Map<String, Object> metadata = new HashMap<>();
      metadata.put(
          "hasPendingWrites", documentChange.getDocument().getMetadata().hasPendingWrites());
      metadata.put("isFromCache", documentChange.getDocument().getMetadata().isFromCache());
      change.put("metadata", metadata);
      documentChanges.add(change);
    }
    data.put("documentChanges", documentChanges);

    Map<String, Object> metadata = new HashMap<>();
    metadata.put("hasPendingWrites", querySnapshot.getMetadata().hasPendingWrites());
    metadata.put("isFromCache", querySnapshot.getMetadata().isFromCache());
    data.put("metadata", metadata);

    return data;
  }

  private Transaction getTransaction(Map<String, Object> arguments) {
    return transactions.get((Integer) arguments.get("transactionId"));
  }

  private Query getQuery(Map<String, Object> arguments) {
    Query query = getReference(arguments);
    @SuppressWarnings("unchecked")
    Map<String, Object> parameters = (Map<String, Object>) arguments.get("parameters");
    if (parameters == null) return query;

    // "where" filters
    @SuppressWarnings("unchecked")
    List<List<Object>> filters = (List<List<Object>>) parameters.get("where");
    for (List<Object> condition : filters) {
      FieldPath fieldPath = (FieldPath) condition.get(0);
      String operator = (String) condition.get(1);
      Object value = condition.get(2);

      if ("==".equals(operator)) {
        query = query.whereEqualTo(fieldPath, value);
      } else if ("<".equals(operator)) {
        query = query.whereLessThan(fieldPath, value);
      } else if ("<=".equals(operator)) {
        query = query.whereLessThanOrEqualTo(fieldPath, value);
      } else if (">".equals(operator)) {
        query = query.whereGreaterThan(fieldPath, value);
      } else if (">=".equals(operator)) {
        query = query.whereGreaterThanOrEqualTo(fieldPath, value);
      } else if ("array-contains".equals(operator)) {
        query = query.whereArrayContains(fieldPath, value);
      } else if ("array-contains-any".equals(operator)) {
        List<Object> values = (List<Object>) value;
        query = query.whereArrayContainsAny(fieldPath, values);
      } else if ("in".equals(operator)) {
        List<Object> values = (List<Object>) value;
        query = query.whereIn(fieldPath, values);
      } else {
        // Invalid operator.
      }
    }

    // "limit" filters
    @SuppressWarnings("unchecked")
    Number limit = (Number) parameters.get("limit");
    if (limit != null) query = query.limit(limit.longValue());

    @SuppressWarnings("unchecked")
    Number limitToLast = (Number) parameters.get("limitToLast");
    if (limitToLast != null) query = query.limitToLast(limitToLast.longValue());

    // "orderBy" filters
    @SuppressWarnings("unchecked")
    List<List<Object>> orderBy = (List<List<Object>>) parameters.get("orderBy");
    if (orderBy == null) return query;

    for (List<Object> order : orderBy) {
      FieldPath fieldPath = (FieldPath) order.get(0);
      boolean descending = (boolean) order.get(1);

      Query.Direction direction =
          descending ? Query.Direction.DESCENDING : Query.Direction.ASCENDING;

      query = query.orderBy(fieldPath, direction);
    }

    // cursor queries
    @SuppressWarnings("unchecked")
    List<Object> startAt = (List<Object>) parameters.get("startAt");
    if (startAt != null) query = query.startAt(startAt.toArray());

    @SuppressWarnings("unchecked")
    List<Object> startAfter = (List<Object>) parameters.get("startAfter");
    if (startAfter != null) query = query.startAfter(startAfter.toArray());

    @SuppressWarnings("unchecked")
    List<Object> endAt = (List<Object>) parameters.get("endAt");
    if (endAt != null) query = query.endAt(endAt.toArray());

    @SuppressWarnings("unchecked")
    List<Object> endBefore = (List<Object>) parameters.get("endBefore");
    if (endBefore != null) query = query.endBefore(endBefore.toArray());

    return query;
  }

  private void addDefaultListeners(final String description, Task<Void> task, final Result result) {
    task.addOnSuccessListener(ignored -> result.success(null));
    task.addOnFailureListener(
        e -> result.error("Error performing " + description, e.getMessage(), null));
  }

  private static final class TransactionResult {
    final @Nullable Map<String, Object> result;
    final @Nullable Exception exception;

    TransactionResult(@NonNull Exception exception) {
      this.exception = exception;
      this.result = null;
    }

    TransactionResult(@Nullable Map<String, Object> result) {
      this.result = result;
      this.exception = null;
    }
  }

  private class DocumentObserver implements EventListener<DocumentSnapshot> {
    private int handle;

    DocumentObserver(int handle) {
      this.handle = handle;
    }

    @Override
    public void onEvent(DocumentSnapshot documentSnapshot, FirebaseFirestoreException e) {
      if (e != null) {
        // TODO: send error
        System.out.println(e);
        return;
      }
      Map<String, Object> arguments = new HashMap<>();
      Map<String, Object> metadata = new HashMap<>();
      arguments.put("handle", handle);
      metadata.put("hasPendingWrites", documentSnapshot.getMetadata().hasPendingWrites());
      metadata.put("isFromCache", documentSnapshot.getMetadata().isFromCache());
      arguments.put("metadata", metadata);
      if (documentSnapshot.exists()) {
        arguments.put("data", documentSnapshot.getData());
        arguments.put("path", documentSnapshot.getReference().getPath());
      } else {
        arguments.put("data", null);
        arguments.put("path", documentSnapshot.getReference().getPath());
      }
      channel.invokeMethod("DocumentSnapshot", arguments);
    }
  }

  private class EventObserver implements EventListener<QuerySnapshot> {
    private int handle;

    EventObserver(int handle) {
      this.handle = handle;
    }

    @Override
    public void onEvent(QuerySnapshot querySnapshot, FirebaseFirestoreException e) {
      if (e != null) {
        // TODO: send error
        System.out.println(e);
        return;
      }

      Map<String, Object> arguments = parseQuerySnapshot(querySnapshot);
      arguments.put("handle", handle);

      channel.invokeMethod("QuerySnapshot", arguments);
    }
  }
}

final class FirestoreMessageCodec extends StandardMessageCodec {
  public static final FirestoreMessageCodec INSTANCE = new FirestoreMessageCodec();
  private static final Charset UTF8 = Charset.forName("UTF8");
  private static final byte DATE_TIME = (byte) 128;
  private static final byte GEO_POINT = (byte) 129;
  private static final byte DOCUMENT_REFERENCE = (byte) 130;
  private static final byte BLOB = (byte) 131;
  private static final byte ARRAY_UNION = (byte) 132;
  private static final byte ARRAY_REMOVE = (byte) 133;
  private static final byte DELETE = (byte) 134;
  private static final byte SERVER_TIMESTAMP = (byte) 135;
  private static final byte TIMESTAMP = (byte) 136;
  private static final byte INCREMENT_DOUBLE = (byte) 137;
  private static final byte INCREMENT_INTEGER = (byte) 138;
  private static final byte DOCUMENT_ID = (byte) 139;
  private static final byte FIELD_PATH = (byte) 140;

  @Override
  protected void writeValue(ByteArrayOutputStream stream, Object value) {
    if (value instanceof Date) {
      stream.write(DATE_TIME);
      writeLong(stream, ((Date) value).getTime());
    } else if (value instanceof Timestamp) {
      stream.write(TIMESTAMP);
      writeLong(stream, ((Timestamp) value).getSeconds());
      writeInt(stream, ((Timestamp) value).getNanoseconds());
    } else if (value instanceof GeoPoint) {
      stream.write(GEO_POINT);
      writeAlignment(stream, 8);
      writeDouble(stream, ((GeoPoint) value).getLatitude());
      writeDouble(stream, ((GeoPoint) value).getLongitude());
    } else if (value instanceof DocumentReference) {
      stream.write(DOCUMENT_REFERENCE);
      writeBytes(
          stream, ((DocumentReference) value).getFirestore().getApp().getName().getBytes(UTF8));
      writeBytes(stream, ((DocumentReference) value).getPath().getBytes(UTF8));
    } else if (value instanceof Blob) {
      stream.write(BLOB);
      writeBytes(stream, ((Blob) value).toBytes());
    } else {
      super.writeValue(stream, value);
    }
  }

  @Override
  protected Object readValueOfType(byte type, ByteBuffer buffer) {
    switch (type) {
      case DATE_TIME:
        return new Date(buffer.getLong());
      case TIMESTAMP:
        return new Timestamp(buffer.getLong(), buffer.getInt());
      case GEO_POINT:
        readAlignment(buffer, 8);
        return new GeoPoint(buffer.getDouble(), buffer.getDouble());
      case DOCUMENT_REFERENCE:
        final byte[] appNameBytes = readBytes(buffer);
        String appName = new String(appNameBytes, UTF8);
        final FirebaseFirestore firestore =
            FirebaseFirestore.getInstance(FirebaseApp.getInstance(appName));
        final byte[] pathBytes = readBytes(buffer);
        final String path = new String(pathBytes, UTF8);
        return firestore.document(path);
      case BLOB:
        final byte[] bytes = readBytes(buffer);
        return Blob.fromBytes(bytes);
      case ARRAY_UNION:
        return FieldValue.arrayUnion(toArray(readValue(buffer)));
      case ARRAY_REMOVE:
        return FieldValue.arrayRemove(toArray(readValue(buffer)));
      case DELETE:
        return FieldValue.delete();
      case SERVER_TIMESTAMP:
        return FieldValue.serverTimestamp();
      case INCREMENT_INTEGER:
        final Number integerIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(integerIncrementValue.intValue());
      case INCREMENT_DOUBLE:
        final Number doubleIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(doubleIncrementValue.doubleValue());
      case DOCUMENT_ID:
        return FieldPath.documentId();
      case FIELD_PATH:
        final int size = readSize(buffer);
        final List<Object> list = new ArrayList<>(size);
        for (int i = 0; i < size; i++) {
          list.add(readValue(buffer));
        }
        return FieldPath.of((String[]) list.toArray(new String[0]));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  private Object[] toArray(Object source) {
    if (source instanceof List) {
      return ((List) source).toArray();
    }

    if (source == null) {
      return new Object[0];
    }

    String sourceType = source.getClass().getCanonicalName();
    String message = "java.util.List was expected, unable to convert '%s' to an object array";
    throw new IllegalArgumentException(String.format(message, sourceType));
  }
}
