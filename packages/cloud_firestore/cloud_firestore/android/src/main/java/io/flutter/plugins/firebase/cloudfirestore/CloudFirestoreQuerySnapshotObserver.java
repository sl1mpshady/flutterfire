package io.flutter.plugins.firebase.cloudfirestore;

import androidx.annotation.Nullable;

import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.QuerySnapshot;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static io.flutter.plugins.firebase.cloudfirestore.CloudFirestorePlugin.parseQuerySnapshot;

class CloudFirestoreQuerySnapshotObserver implements EventListener<QuerySnapshot> {

  private MethodChannel channel;
  private int handle;

  CloudFirestoreQuerySnapshotObserver(MethodChannel channel, int handle) {
    this.channel = channel;
    this.handle = handle;
  }

  @Override
  public void onEvent(QuerySnapshot querySnapshot, @Nullable FirebaseFirestoreException exception) {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", handle);

    if (exception != null) {
      CloudFirestoreException firestoreException =
          new CloudFirestoreException(exception, exception.getCause());

      Map<String, Object> details = new HashMap<>();
      details.put("code", firestoreException.getCode());
      details.put("message", firestoreException.getCode());

      arguments.put("error", details);
      channel.invokeMethod("Firestore#error", arguments);
      return;
    }

    arguments.put("snapshot", parseQuerySnapshot(querySnapshot));

    channel.invokeMethod("Firestore#QuerySnapshot", arguments);
  }
}
