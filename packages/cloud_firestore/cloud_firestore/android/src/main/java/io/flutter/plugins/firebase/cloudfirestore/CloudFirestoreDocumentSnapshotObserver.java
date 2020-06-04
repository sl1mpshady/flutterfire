package io.flutter.plugins.firebase.cloudfirestore;

import static io.flutter.plugins.firebase.cloudfirestore.CloudFirestorePlugin.parseDocumentSnapshot;

import androidx.annotation.Nullable;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FirebaseFirestoreException;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

class CloudFirestoreDocumentSnapshotObserver implements EventListener<DocumentSnapshot> {
  private MethodChannel channel;
  private int handle;

  CloudFirestoreDocumentSnapshotObserver(MethodChannel channel, int handle) {
    this.channel = channel;
    this.handle = handle;
  }

  @Override
  public void onEvent(
      DocumentSnapshot documentSnapshot, @Nullable FirebaseFirestoreException exception) {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", handle);

    if (exception != null) {
      CloudFirestoreException firestoreException =
          new CloudFirestoreException(exception, exception.getCause());

      Map<String, Object> details = new HashMap<>();
      details.put("code", firestoreException.getCode());
      details.put("message", firestoreException.getMessage());

      arguments.put("error", details);
      channel.invokeMethod("DocumentSnapshot#error", arguments);
      return;
    }

    arguments.put("snapshot", parseDocumentSnapshot(documentSnapshot));

    channel.invokeMethod("DocumentSnapshot#event", arguments);
  }
}
