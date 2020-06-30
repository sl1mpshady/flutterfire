// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.cloudfirestore;

import android.app.Activity;
import android.util.SparseArray;
import androidx.annotation.NonNull;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.firestore.DocumentChange;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.MetadataChanges;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.QuerySnapshot;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Source;
import com.google.firebase.firestore.WriteBatch;
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
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.WeakHashMap;

public class CloudFirestorePlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final WeakHashMap<String, WeakReference<FirebaseFirestore>>
      firestoreInstanceCache = new WeakHashMap<>();
  private static final SparseArray<ListenerRegistration> listenerRegistrations =
      new SparseArray<>();

  private MethodChannel channel;
  private Activity activity;

  protected static FirebaseFirestore getCachedFirebaseFirestoreInstanceForKey(String key) {
    synchronized (firestoreInstanceCache) {
      WeakReference<FirebaseFirestore> existingInstance = firestoreInstanceCache.get(key);
      if (existingInstance != null) {
        return existingInstance.get();
      }

      return null;
    }
  }

  protected static void setCachedFirebaseFirestoreInstanceForKey(
      FirebaseFirestore firestore, String key) {
    synchronized (firestoreInstanceCache) {
      WeakReference<FirebaseFirestore> existingInstance = firestoreInstanceCache.get(key);
      if (existingInstance == null) {
        firestoreInstanceCache.put(key, new WeakReference<>(firestore));
      }
    }
  }

  private static void destroyCachedFirebaseFirestoreInstanceForKey(String key) {
    synchronized (firestoreInstanceCache) {
      WeakReference<FirebaseFirestore> existingInstance = firestoreInstanceCache.get(key);
      if (existingInstance != null) {
        existingInstance.clear();
        firestoreInstanceCache.remove(key);
      }
    }
  }

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
      // noinspection ConstantConditions
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
      Map<String, Object> metadata = new HashMap<>();
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
      change.put("data", documentChange.getDocument().getData());
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
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          return Tasks.await(firestore.disableNetwork());
        });
  }

  private Task<Void> enableNetwork(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          return Tasks.await(firestore.enableNetwork());
        });
  }

  private Task<Integer> addSnapshotsInSyncListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));

          Runnable snapshotsInSyncRunnable =
              () -> {
                Map<String, Integer> data = new HashMap<>();
                data.put("handle", handle);
                activity.runOnUiThread(
                    () -> channel.invokeMethod("Firestore#snapshotsInSync", data));
              };

          listenerRegistrations.put(
              handle, firestore.addSnapshotsInSyncListener(snapshotsInSyncRunnable));

          return handle;
        });
  }

  private Task<Object> createTransaction(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          int transactionId = (int) Objects.requireNonNull(arguments.get("transactionId"));

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
          DocumentReference documentReference = (DocumentReference) arguments.get("reference");
          DocumentSnapshot documentSnapshot =
              CloudFirestoreTransactionHandler.getDocument(
                  (int) Objects.requireNonNull(arguments.get("transactionId")), documentReference);

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
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          WriteBatch batch = firestore.batch();

          for (Map<String, Object> write : writes) {
            String type = (String) Objects.requireNonNull(write.get("type"));
            String path = (String) Objects.requireNonNull(write.get("path"));
            // noinspection unchecked
            Map<String, Object> data =
                (Map<String, Object>) Objects.requireNonNull(write.get("data"));

            DocumentReference documentReference = firestore.document(path);

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

  private Task<Void> queryAddSnapshotListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          CloudFirestoreQuerySnapshotObserver observer =
              new CloudFirestoreQuerySnapshotObserver(channel, handle);

          MetadataChanges metadataChanges =
              (Boolean) Objects.requireNonNull(arguments.get("includeMetadataChanges"))
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;

          Query query = (Query) arguments.get("query");

          if (query == null) {
            throw new IllegalArgumentException(
                "An error occurred while parsing query arguments, see native logs for more information. Please report this issue.");
          }

          listenerRegistrations.put(handle, query.addSnapshotListener(metadataChanges, observer));
          return null;
        });
  }

  private Task<Map<String, Object>> queryGetDocuments(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Source source = getSource(arguments);
          Query query = (Query) arguments.get("query");

          if (query == null) {
            throw new IllegalArgumentException(
                "An error occurred while parsing query arguments, see native logs for more information. Please report this issue.");
          }

          QuerySnapshot snapshot = Tasks.await(query.get(source));
          return parseQuerySnapshot(snapshot);
        });
  }

  private Task<Void> documentReferenceAddSnapshotListener(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          CloudFirestoreDocumentSnapshotObserver observer =
              new CloudFirestoreDocumentSnapshotObserver(channel, handle);

          MetadataChanges metadataChanges =
              (Boolean) Objects.requireNonNull(arguments.get("includeMetadataChanges"))
                  ? MetadataChanges.INCLUDE
                  : MetadataChanges.EXCLUDE;

          DocumentReference documentReference =
              (DocumentReference) Objects.requireNonNull(arguments.get("reference"));

          listenerRegistrations.put(
              handle, documentReference.addSnapshotListener(metadataChanges, observer));

          return null;
        });
  }

  private Task<Map<String, Object>> documentReferenceGetData(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Source source = getSource(arguments);
          DocumentReference documentReference =
              (DocumentReference) Objects.requireNonNull(arguments.get("reference"));

          DocumentSnapshot snapshot = Tasks.await(documentReference.get(source));
          return parseDocumentSnapshot(snapshot);
        });
  }

  private Task<Void> documentReferenceSetData(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          DocumentReference documentReference =
              (DocumentReference) Objects.requireNonNull(arguments.get("reference"));

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
          DocumentReference documentReference =
              (DocumentReference) Objects.requireNonNull(arguments.get("reference"));
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
          DocumentReference documentReference =
              (DocumentReference) Objects.requireNonNull(arguments.get("reference"));
          return Tasks.await(documentReference.delete());
        });
  }

  private Task<Void> clearPersistence(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          return Tasks.await(firestore.clearPersistence());
        });
  }

  private Task<Void> terminate(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String appName = (String) arguments.get("appName");
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          destroyCachedFirebaseFirestoreInstanceForKey(appName);
          return Tasks.await(firestore.terminate());
        });
  }

  private Task<Void> waitForPendingWrites(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFirestore firestore =
              (FirebaseFirestore) Objects.requireNonNull(arguments.get("firestore"));
          return Tasks.await(firestore.waitForPendingWrites());
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
      case "Query#get":
        methodCallTask = queryGetDocuments(call.arguments());
        break;
      case "DocumentReference#addSnapshotListener":
        methodCallTask = documentReferenceAddSnapshotListener(call.arguments());
        break;
      case "DocumentReference#get":
        methodCallTask = documentReferenceGetData(call.arguments());
        break;
      case "DocumentReference#set":
        methodCallTask = documentReferenceSetData(call.arguments());
        break;
      case "DocumentReference#update":
        methodCallTask = documentReferenceUpdateData(call.arguments());
        break;
      case "DocumentReference#delete":
        methodCallTask = documentReferenceDelete(call.arguments());
        break;
      case "Firestore#clearPersistence":
        methodCallTask = clearPersistence(call.arguments());
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

  private Source getSource(Map<String, Object> arguments) {
    String source = (String) Objects.requireNonNull(arguments.get("source"));

    switch (source) {
      case "server":
        return Source.SERVER;
      case "cache":
        return Source.CACHE;
      default:
        return Source.DEFAULT;
    }
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return null;
  }
}
