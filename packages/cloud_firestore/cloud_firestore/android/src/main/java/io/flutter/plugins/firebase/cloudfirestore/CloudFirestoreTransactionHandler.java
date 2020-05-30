package io.flutter.plugins.firebase.cloudfirestore;

import android.app.Activity;
import android.util.SparseArray;

import androidx.annotation.Nullable;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Transaction;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.MethodChannel;

class CloudFirestoreTransactionHandler {
  static final SparseArray<Transaction> transactions = new SparseArray<>();
  static final SparseArray<TaskCompletionSource<Map<String, Object>>> completionTasks =
      new SparseArray<>();
  private static final String TAG = "TransactionHandler";
  private MethodChannel channel;
  private Activity activity;
  private int transactionId;

  CloudFirestoreTransactionHandler(MethodChannel channel, Activity activity, int transactionId) {
    this.channel = channel;
    this.activity = activity;
    this.transactionId = transactionId;
  }

  static void dispose(int transactionId) {
    transactions.delete(transactionId);
  }

  // Gets a transaction document
  // Throws an exception if the handler does not exist
  static DocumentSnapshot getDocument(int transactionId, DocumentReference documentReference)
      throws Exception {
    Transaction transaction = transactions.get(transactionId);

    if (transaction == null) {
      throw new Exception(
          "Transaction.getDocument(): No transaction handler exists for ID: " + transactionId);
    }

    return transaction.get(documentReference);
  }

  Task<TransactionResult> create(FirebaseFirestore firestore, Long timeout) {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("transactionId", transactionId);
    arguments.put("appName", firestore.getApp().getName());

    return firestore.runTransaction(
        transaction -> {
          transactions.append(transactionId, transaction);

          final TaskCompletionSource<Map<String, Object>> completionSource =
              new TaskCompletionSource<>();
          final Task<Map<String, Object>> sourceTask = completionSource.getTask();

          activity.runOnUiThread(
              () -> {
                channel.invokeMethod(
                    "Transaction#attempt",
                    arguments,
                    new MethodChannel.Result() {
                      @Override
                      public void success(@Nullable Object result) {
                        // noinspection unchecked
                        completionSource.trySetResult((Map<String, Object>) result);
                      }

                      @Override
                      public void error(
                          String errorCode,
                          @Nullable String errorMessage,
                          @Nullable Object errorDetails) {
                        completionSource.trySetException(
                            new FirebaseFirestoreException(
                                "Transaction#attempt error: " + errorMessage,
                                FirebaseFirestoreException.Code.ABORTED));
                      }

                      @Override
                      public void notImplemented() {
                        completionSource.trySetException(
                            new FirebaseFirestoreException(
                                "Transaction#attempt: Not implemented",
                                FirebaseFirestoreException.Code.ABORTED));
                      }
                    });
              });

          Map<String, Object> response;

          try {
            response = Tasks.await(sourceTask, timeout, TimeUnit.MILLISECONDS);
            String responseType = (String) Objects.requireNonNull(response.get("type"));

            // Something went wrong in dart - finish this transaction
            if (responseType.equals("ERROR")) {
              return TransactionResult.complete();
            }
          } catch (Exception e) {
            return TransactionResult.fromException(e);
          }

          // noinspection unchecked
          List<Map<String, Object>> commands =
              (List<Map<String, Object>>) Objects.requireNonNull(response.get("commands"));

          for (Map<String, Object> command : commands) {
            String type = (String) Objects.requireNonNull(command.get("type"));
            String path = (String) Objects.requireNonNull(command.get("path"));
            DocumentReference documentReference = firestore.document(path);

            // noinspection unchecked
            Map<String, Object> data = (Map<String, Object>) command.get("data");

            switch (type) {
              case "DELETE":
                transaction.delete(documentReference);
                break;
              case "UPDATE":
                transaction.update(documentReference, data);
                break;
              case "SET":
                {
                  // noinspection unchecked
                  Map<String, Object> options =
                      (Map<String, Object>) Objects.requireNonNull(command.get("options"));
                  SetOptions setOptions = null;

                  if (options.get("merge") != null && (boolean) options.get("merge")) {
                    setOptions = SetOptions.merge();
                  } else if (options.get("mergeFields") != null) {
                    // noinspection unchecked
                    List<FieldPath> fieldPathList =
                        (List<FieldPath>) Objects.requireNonNull(options.get("mergeFields"));
                    setOptions = SetOptions.mergeFieldPaths(fieldPathList);
                  }

                  if (setOptions == null) {
                    transaction.set(documentReference, data);
                  } else {
                    transaction.set(documentReference, data, setOptions);
                  }
                }
                break;
            }
          }

          return TransactionResult.complete();
        });
  }
}
