// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;

import java.util.HashMap;
import java.util.Map;

public class FirebasePluginRegistry {
  private static final Map<String, FirebasePlugin> registeredPlugins = new HashMap<>();

  static void registerPlugin(String channelName, FirebasePlugin firebasePlugin) {
    registeredPlugins.put(channelName, firebasePlugin);
  }

  static Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return Tasks.call(
        () -> {
          Map<String, Object> pluginConstants = new HashMap<>(registeredPlugins.size());

          for (Map.Entry<String, FirebasePlugin> entry : registeredPlugins.entrySet()) {
            String channelName = entry.getKey();
            FirebasePlugin plugin = entry.getValue();
            pluginConstants.put(
                channelName, Tasks.await(plugin.getPluginConstantsForFirebaseApp(firebaseApp)));
          }

          return pluginConstants;
        });
  }
}
