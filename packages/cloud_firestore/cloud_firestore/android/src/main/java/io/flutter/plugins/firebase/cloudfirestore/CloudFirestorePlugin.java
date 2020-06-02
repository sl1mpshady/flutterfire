// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.cloudfirestore;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import android.util.SparseArray;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.firestore.CollectionReference;
import com.google.firebase.firestore.DocumentChange;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.FirebaseFirestoreSettings;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.MetadataChanges;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.QuerySnapshot;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Source;
import com.google.firebase.firestore.WriteBatch;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;

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

public class CloudFirestorePlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final String TAG = "CloudFirestorePlugin";
  private static final HashMap<String, Boolean> settingsLock = new HashMap<>();

  private static final String SETTINGS_CLEAR_PERSISTENCE = "firebase_firestore_clear_persistence_";
  private static final String SETTINGS_CACHE_SIZE = "firebase_firestore_cache_size_";
  private static final String SETTINGS_HOST = "firebase_firestore_host_";
  private static final String SETTINGS_PERSISTENCE = "firebase_firestore_persistence_";
  private static final String SETTINGS_SSL = "firebase_firestore_ssl_";

  private final SparseArray<ListenerRegistration> listenerRegistrations = new SparseArray<>();
  private MethodChannel channel;
  private Activity activity;
  // Handles are ints used as indexes into the sparse array of active observers
  private int nextListenerHandle = 0;

  @SuppressWarnings("unused")
  public static void registerWith(PluginRegistry.Registrar registrar) {
    CloudFirestorePlugin instance = new CloudFirestorePlugin();
    instance.activity = registrar.activity();
    instance.initInstance(registrar.messenger());
  }

  // Converts a native DocumentSnapshot into a Map
  static Map<String, Object> parseDocumentSnapshot(@NonNull DocumentSnapshot documentSnapshot) {
    Map<String, Object> snapshotMap = new HashMap<>();
    Map<String, Object> metadata = new HashMap<>();

    metadata.put("hasPendingWrites", documentSnapshot.getMetadata().hasPendingWrites());
    metadata.put("isFromCache", documentSnapshot.getMetadata().isFromCache());
    snapshotMap.put("metadata", metadata);

    snapshotMap.put("path", documentSnapshot.getReference().getPath());

    if (documentSnapshot.getData() == null) {
      snapshotMap.put("data", null);
    } else {
      snapshotMap.put("data", documentSnapshot.getData());
    }

    return snapshotMap;
  }

  // Converts a native QuerySnapshot into a Map
  static Map<String, Object> parseQuerySnapshot(QuerySnapshot querySnapshot) {
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

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    removeEventListeners();
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
    attachToActivity(activityPluginBinding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachToActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding activityPluginBinding) {
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

  // Ensure any Firestore listeners are removed when the app
  // is detached from the FlutterEngine
  private void removeEventListeners() {
    for (int i = 0; i < listenerRegistrations.size(); i++) {
      int key = listenerRegistrations.keyAt(i);
      listenerRegistrations.get(key).remove();
    }
    listenerRegistrations.clear();
  }

  private Task<Void> disableNetwork(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firebaseFirestore = Tasks.await(getFirestore(arguments));
          return Tasks.await(firebaseFirestore.disableNetwork());
        });
  }

  private Task<Void> enableNetwork(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firebaseFirestore = Tasks.await(getFirestore(arguments));
          return Tasks.await(firebaseFirestore.enableNetwork());
        });
  }

  private Task<Integer> addSnapshotsInSyncListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = nextListenerHandle++;
          FirebaseFirestore firebaseFirestore = Tasks.await(getFirestore(arguments));

          Runnable snapshotsInSyncRunnable =
              () -> {
                Map<String, Integer> data = new HashMap<>();
                data.put("handle", handle);
                activity.runOnUiThread(
                    () -> channel.invokeMethod("Firestore#snapshotsInSync", data));
              };

          listenerRegistrations.put(
              handle, firebaseFirestore.addSnapshotsInSyncListener(snapshotsInSyncRunnable));

          return handle;
        });
  }

  private Task<Object> createTransaction(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firestore = Tasks.await(getFirestore(arguments));
          int transactionId = (int) arguments.get("transactionId");

          Object value = arguments.get("timeout");
          Long timeout;

          if (value instanceof Long) {
            timeout = (Long) value;
          } else if (value instanceof Integer) {
            timeout = Long.valueOf((Integer) value);
          } else {
            timeout = 5000L;
          }

          TransactionResult transactionResult =
              Tasks.await(
                  new CloudFirestoreTransactionHandler(channel, activity, transactionId)
                      .create(firestore, timeout));

          CloudFirestoreTransactionHandler.dispose(transactionId);

          if (transactionResult.exception != null) {
            throw transactionResult.exception;
          } else {
            return null;
          }
        });
  }

  private Task<Map<String, Object>> transactionGetDocumentData(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));
          DocumentSnapshot documentSnapshot =
              CloudFirestoreTransactionHandler.getDocument(
                  (int) arguments.get("transactionId"), documentReference);

          return parseDocumentSnapshot(documentSnapshot);
        });
  }

  private Task<Void> writeBatchCommit(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          // noinspection unchecked
          List<Map<String, Object>> writes =
              (List<Map<String, Object>>) Objects.requireNonNull(arguments.get("writes"));
          FirebaseFirestore firestore = Tasks.await(getFirestore(arguments));
          WriteBatch batch = firestore.batch();

          for (Map<String, Object> write : writes) {
            String type = (String) Objects.requireNonNull(write.get("type"));
            String path = (String) Objects.requireNonNull(write.get("path"));
            // noinspection unchecked
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
                // noinspection unchecked
                Map<String, Object> options =
                    (Map<String, Object>) Objects.requireNonNull(write.get("options"));

                if (options.get("merge") != null && (boolean) options.get("merge")) {
                  batch = batch.set(documentReference, data, SetOptions.merge());
                } else if (options.get("mergeFields") != null) {
                  // noinspection unchecked
                  List<FieldPath> fieldPathList =
                      (List<FieldPath>) Objects.requireNonNull(options.get("mergeFields"));
                  batch =
                      batch.set(documentReference, data, SetOptions.mergeFieldPaths(fieldPathList));
                } else {
                  batch = batch.set(documentReference, data);
                }
                break;
            }
          }

          return Tasks.await(batch.commit());
        });
  }

  private Task<Integer> queryAddSnapshotListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = nextListenerHandle++;
          CloudFirestoreQuerySnapshotObserver observer =
              new CloudFirestoreQuerySnapshotObserver(channel, handle);

          MetadataChanges metadataChanges =
              (Boolean) Objects.requireNonNull(arguments.get("includeMetadataChanges"))
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;

          Query query = Tasks.await(getQuery(arguments));

          listenerRegistrations.put(handle, query.addSnapshotListener(metadataChanges, observer));

          return handle;
        });
  }

  private Task<Map<String, Object>> queryGetDocuments(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Query query = Tasks.await(getQuery(arguments));
          Source source = getSource(arguments);

          QuerySnapshot snapshot = Tasks.await(query.get(source));
          return parseQuerySnapshot(snapshot);
        });
  }

  private Task<Integer> documentReferenceAddSnapshotListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = nextListenerHandle++;
          CloudFirestoreDocumentSnapshotObserver observer =
              new CloudFirestoreDocumentSnapshotObserver(channel, handle);

          MetadataChanges metadataChanges =
              (Boolean) Objects.requireNonNull(arguments.get("includeMetadataChanges"))
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;

          DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));

          listenerRegistrations.put(
              handle, documentReference.addSnapshotListener(metadataChanges, observer));

          return handle;
        });
  }

  private Task<Map<String, Object>> documentReferenceGetData(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));
          Source source = getSource(arguments);

          DocumentSnapshot snapshot = Tasks.await(documentReference.get(source));
          return parseDocumentSnapshot(snapshot);
        });
  }

  private Task<Void> documentReferenceSetData(Map<String, Object> arguments) {

    return Tasks.call(
        cachedThreadPool,
        () -> {
          final DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));

          // noinspection unchecked
          Map<String, Object> data =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("data"));
          // noinspection unchecked
          Map<String, Object> options =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("options"));

          Task<Void> setTask;

          if (options.get("merge") != null && (boolean) options.get("merge")) {
            setTask = documentReference.set(data, SetOptions.merge());
          } else if (options.get("mergeFields") != null) {
            // noinspection unchecked
            List<FieldPath> fieldPathList =
                (List<FieldPath>) Objects.requireNonNull(options.get("mergeFields"));
            setTask = documentReference.set(data, SetOptions.mergeFieldPaths(fieldPathList));
          } else {
            setTask = documentReference.set(data);
          }

          return Tasks.await(setTask);
        });
  }

  private Task<Void> documentReferenceUpdateData(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));
          // noinspection unchecked
          Map<String, Object> data =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("data"));

          return Tasks.await(documentReference.update(data));
        });
  }

  private Task<Void> documentReferenceDelete(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          DocumentReference documentReference = Tasks.await(getDocumentReference(arguments));
          return Tasks.await(documentReference.delete());
        });
  }

  // Settings are required to be set before any other usage of Firestore. Rather than
  // directly setting them here (in-case the user has already performed an action), the
  // settings are set within shared-preferences & read when an instance of FirebaseFirestore
  // is read.
  private Task<Void> firestorePersistSettings(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String appName = (String) arguments.get("appName");
          // noinspection unchecked
          Map<String, Object> settings =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("settings"));

          FirebaseSharedPreferences preferences = FirebaseSharedPreferences.getSharedInstance();
          preferences.setApplicationContext(activity.getApplicationContext());

          if (settings.get("persistenceEnabled") != null) {
            preferences.setBooleanValue(
                SETTINGS_CLEAR_PERSISTENCE + appName, (boolean) settings.get("persistenceEnabled"));
          }

          if (settings.get("host") != null) {
            preferences.setStringValue(SETTINGS_HOST + appName, (String) settings.get("host"));
          }

          if (settings.get("sslEnabled") != null) {
            preferences.setBooleanValue(
                SETTINGS_SSL + appName, (boolean) settings.get("sslEnabled"));
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
              preferences.setLongValue(SETTINGS_CACHE_SIZE + appName, cacheSizeBytes);
            }
          }

          return null;
        });
  }

  private Task<Void> clearPersistence(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String appName = (String) arguments.get("appName");
          FirebaseSharedPreferences preferences = FirebaseSharedPreferences.getSharedInstance();
          preferences.setApplicationContext(activity.getApplicationContext());

          preferences.setBooleanValue(SETTINGS_PERSISTENCE + appName, true);
          return null;
        });
  }

  private Task<Void> terminate(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firebaseFirestore = Tasks.await(getFirestore(arguments));
          return Tasks.await(firebaseFirestore.terminate());
        });
  }

  private Task<Void> waitForPendingWrites(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firebaseFirestore = Tasks.await(getFirestore(arguments));
          return Tasks.await(firebaseFirestore.waitForPendingWrites());
        });
  }

  @Override
  public void onMethodCall(MethodCall call, @NonNull final MethodChannel.Result result) {
    Task<?> methodCallTask;

    switch (call.method) {
      case "Firestore#removeListener":
        int handle = Objects.requireNonNull(call.argument("handle"));
        listenerRegistrations.get(handle).remove();
        listenerRegistrations.remove(handle);
        result.success(null);
        return;
      case "Firestore#disableNetwork":
        methodCallTask = disableNetwork(call.arguments());
        break;
      case "Firestore#enableNetwork":
        methodCallTask = enableNetwork(call.arguments());
        break;
      case "Firestore#addSnapshotsInSyncListener":
        methodCallTask = addSnapshotsInSyncListener(call.arguments());
        break;
      case "Transaction#create":
        methodCallTask = createTransaction(call.arguments());
        break;
      case "Transaction#get":
        methodCallTask = transactionGetDocumentData(call.arguments());
        break;
      case "WriteBatch#commit":
        methodCallTask = writeBatchCommit(call.arguments());
        break;
      case "Query#addSnapshotListener":
        methodCallTask = queryAddSnapshotListener(call.arguments());
        break;
      case "Query#getDocuments":
        methodCallTask = queryGetDocuments(call.arguments());
        break;
      case "DocumentReference#addSnapshotListener":
        methodCallTask = documentReferenceAddSnapshotListener(call.arguments());
        break;
      case "DocumentReference#get":
        methodCallTask = documentReferenceGetData(call.arguments());
        break;
      case "DocumentReference#setData":
        methodCallTask = documentReferenceSetData(call.arguments());
        break;
      case "DocumentReference#updateData":
        methodCallTask = documentReferenceUpdateData(call.arguments());
        break;
      case "DocumentReference#delete":
        methodCallTask = documentReferenceDelete(call.arguments());
        break;
      case "Firestore#clearPersistence":
        methodCallTask = clearPersistence(call.arguments());
        break;
      case "Firestore#settings":
        methodCallTask = firestorePersistSettings(call.arguments());
        break;
      case "Firestore#terminate":
        methodCallTask = terminate(call.arguments());
        break;
      case "Firestore#waitForPendingWrites":
        methodCallTask = waitForPendingWrites(call.arguments());
        break;
      default:
        result.notImplemented();
        return;
    }

    methodCallTask.addOnCompleteListener(
        task -> {
          if (task.isSuccessful()) {
            result.success(task.getResult());
          } else {
            Exception exception = task.getException();
            result.error(
                "cloud_firestore",
                exception != null ? exception.getMessage() : null,
                getExceptionDetails(exception));
          }
        });
  }

  private void initInstance(BinaryMessenger messenger) {
    channel =
        new MethodChannel(
            messenger,
            "plugins.flutter.io/cloud_firestore",
            new StandardMethodCodec(CloudFirestoreMessageCodec.INSTANCE));

    channel.setMethodCallHandler(this);
  }

  private Map<String, String> getExceptionDetails(Exception exception) {
    Map<String, String> details = new HashMap<>();

    if (exception == null) {
      return details;
    }

    CloudFirestoreException firestoreException = null;

    if (exception instanceof FirebaseFirestoreException) {
      firestoreException =
          new CloudFirestoreException((FirebaseFirestoreException) exception, exception.getCause());
    } else if (exception.getCause() != null
        && exception.getCause() instanceof FirebaseFirestoreException) {
      firestoreException =
          new CloudFirestoreException(
              (FirebaseFirestoreException) exception.getCause(),
              exception.getCause().getCause() != null
                  ? exception.getCause().getCause()
                  : exception.getCause());
    }

    if (firestoreException != null) {
      details.put("code", firestoreException.getCode());
      details.put("message", firestoreException.getMessage());
    }

    return details;
  }

  private Task<FirebaseFirestore> getFirestore(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          synchronized (settingsLock) {
            String appName = (String) Objects.requireNonNull(arguments.get("appName"));
            FirebaseFirestore instance =
                FirebaseFirestore.getInstance(FirebaseApp.getInstance(appName));
            Tasks.await(setFirestoreSettings(instance, appName));
            return instance;
          }
        });
  }

  private Task<Void> setFirestoreSettings(FirebaseFirestore firebaseFirestore, String appName) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          // Ensure not already been set
          if (settingsLock.containsKey(appName)) return null;

          FirebaseSharedPreferences preferences = FirebaseSharedPreferences.getSharedInstance();
          preferences.setApplicationContext(activity.getApplicationContext());
          FirebaseFirestoreSettings.Builder firestoreSettings =
              new FirebaseFirestoreSettings.Builder();

          boolean clearPersistence =
              preferences.getBooleanValue(SETTINGS_CLEAR_PERSISTENCE + appName, false);

          if (clearPersistence) {
            Tasks.await(firebaseFirestore.clearPersistence());
            preferences.setBooleanValue(SETTINGS_CLEAR_PERSISTENCE + appName, false);
          }

          long cacheSizeBytes =
              preferences.getLongValue(
                  SETTINGS_CACHE_SIZE + appName,
                  firebaseFirestore.getFirestoreSettings().getCacheSizeBytes());

          String host =
              preferences.getStringValue(
                  SETTINGS_HOST + appName, firebaseFirestore.getFirestoreSettings().getHost());

          boolean persistence =
              preferences.getBooleanValue(
                  SETTINGS_PERSISTENCE + appName,
                  firebaseFirestore.getFirestoreSettings().isPersistenceEnabled());

          boolean ssl =
              preferences.getBooleanValue(
                  SETTINGS_SSL + appName, firebaseFirestore.getFirestoreSettings().isSslEnabled());

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

          return null;
        });
  }

  private Task<Query> getReference(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          if ((boolean) arguments.get("isCollectionGroup"))
            return Tasks.await(getCollectionGroupReference(arguments));
          else return Tasks.await(getCollectionReference(arguments));
        });
  }

  private Task<Query> getCollectionGroupReference(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String path = (String) Objects.requireNonNull(arguments.get("path"));
          return Tasks.await(getFirestore(arguments)).collectionGroup(path);
        });
  }

  private Task<CollectionReference> getCollectionReference(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String path = (String) Objects.requireNonNull(arguments.get("path"));
          return Tasks.await(getFirestore(arguments)).collection(path);
        });
  }

  private Task<DocumentReference> getDocumentReference(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String path = (String) Objects.requireNonNull(arguments.get("path"));
          return Tasks.await(getFirestore(arguments)).document(path);
        });
  }

  private DocumentReference getDocumentReference(FirebaseFirestore firestore, String path) {
    return firestore.document(path);
  }

  private Source getSource(Map<String, Object> arguments) {
    String source = (String) arguments.get("source");

    if (source == null) {
      return Source.DEFAULT;
    }

    switch (source) {
      case "server":
        return Source.SERVER;
      case "cache":
        return Source.CACHE;
      default:
        return Source.DEFAULT;
    }
  }

  private Task<Query> getQuery(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Query query = Tasks.await(getReference(arguments));
          @SuppressWarnings("unchecked")
          Map<String, Object> parameters = (Map<String, Object>) arguments.get("parameters");
          if (parameters == null) return query;

          // "where" filters
          @SuppressWarnings("unchecked")
          List<List<Object>> filters =
              (List<List<Object>>) Objects.requireNonNull(parameters.get("where"));
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
              Log.w(
                  TAG, "An invalid query operator " + operator + " was received but not handled.");
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
        });
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return null;
  }
}
