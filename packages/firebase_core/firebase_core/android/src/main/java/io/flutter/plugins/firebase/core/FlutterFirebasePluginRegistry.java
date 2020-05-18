// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import androidx.annotation.Keep;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;

import java.util.HashMap;
import java.util.Map;
import java.util.WeakHashMap;

import static io.flutter.plugins.firebase.core.FlutterFirebasePlugin.cachedThreadPool;

@Keep
public class FlutterFirebasePluginRegistry {

  private static final Map<String, FlutterFirebasePlugin> registeredPlugins = new WeakHashMap<>();

  /**
   * Register a Flutter Firebase plugin with the Firebase plugin registry.
   *
   * @param channelName The MethodChannel name for the plugin to be registered, for example:
   *     `plugins.flutter.io/firebase_core`
   * @param flutterFirebasePlugin A FlutterPlugin that implements FlutterFirebasePlugin.
   */
  public static void registerPlugin(
      String channelName, FlutterFirebasePlugin flutterFirebasePlugin) {
    registeredPlugins.put(channelName, flutterFirebasePlugin);
  }

  /**
   * Each FlutterFire plugin implementing FlutterFirebasePlugin provides this method to allowing
   * it's constants to be initialized during FirebaseCore.initializeApp in Dart. Here we call this
   * method on each of the registered plugins and gather their constants for use in Dart.
   *
   * @param firebaseApp The Firebase App that the plugin should return constants for.
   * @return A task returning the discovered constants for each plugin (using channelName as the Map
   *     key) for the provided Firebase App.
   */
  static Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Map<String, Object> pluginConstants = new HashMap<>(registeredPlugins.size());

          for (Map.Entry<String, FlutterFirebasePlugin> entry : registeredPlugins.entrySet()) {
            String channelName = entry.getKey();
            FlutterFirebasePlugin plugin = entry.getValue();
            pluginConstants.put(
                channelName, Tasks.await(plugin.getPluginConstantsForFirebaseApp(firebaseApp)));
          }

          return pluginConstants;
        });
  }
}