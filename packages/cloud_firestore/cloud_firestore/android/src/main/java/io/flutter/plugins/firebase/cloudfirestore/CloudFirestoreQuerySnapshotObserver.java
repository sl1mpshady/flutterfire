package io.flutter.plugins.firebase.cloudfirestore;

import androidx.annotation.NonNull;
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
  public void onEvent(
      @NonNull QuerySnapshot querySnapshot, @Nullable FirebaseFirestoreException e) {
    if (e != null) {
      // TODO: send error
      System.out.println(e);
      return;
    }

    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", handle);
    arguments.put("snapshot", parseQuerySnapshot(querySnapshot));

    channel.invokeMethod("QuerySnapshot", arguments);
  }
}
