// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import android.content.Context;
import androidx.annotation.NonNull;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.Executors;

/**
 * Flutter plugin implementation controlling the entrypoint for the Firebase SDK.
 *
 * <p>Instantiate this in an add to app scenario to gracefully handle activity and context changes.
 */
public class FirebaseCorePlugin
    implements FlutterPlugin, FirebasePlugin, MethodChannel.MethodCallHandler {
  private static final String CHANNEL_NAME = "plugins.flutter.io/firebase_core";

  private MethodChannel channel;
  private Context applicationContext;

  /**
   * Default Constructor.
   *
   * <p>Use this constructor in an add to app scenario to gracefully handle activity and context
   * changes.
   */
  public FirebaseCorePlugin() {}

  private FirebaseCorePlugin(Context applicationContext) {
    this.applicationContext = applicationContext;
    FirebasePluginRegistry.registerPlugin(CHANNEL_NAME, this);
  }

  /**
   * Registers a plugin with the v1 embedding api {@code io.flutter.plugin.common}.
   *
   * <p>Calling this will register the plugin with the passed registrar. However plugins initialized
   * this way won't react to changes in activity or context, unlike {@link FirebaseCorePlugin}.
   */
  public static void registerWith(PluginRegistry.Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(new FirebaseCorePlugin(registrar.context()));
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    applicationContext = null;
  }

  private Task<Map<String, Object>> firebaseAppToMap(FirebaseApp firebaseApp) {
    return Tasks.call(
        Executors.newSingleThreadExecutor(),
        () -> {
          Map<String, Object> appMap = new HashMap<>();
          Map<String, String> optionsMap = new HashMap<>();
          FirebaseOptions options = firebaseApp.getOptions();

          optionsMap.put("apiKey", options.getApiKey());
          optionsMap.put("appId", options.getApplicationId());
          optionsMap.put("messagingSenderId", options.getGcmSenderId());
          optionsMap.put("projectId", options.getProjectId());
          optionsMap.put("databaseURL", options.getDatabaseUrl());
          optionsMap.put("storageBucket", options.getStorageBucket());

          appMap.put("name", firebaseApp.getName());
          appMap.put("options", optionsMap);

          appMap.put(
              "isAutomaticDataCollectionEnabled", firebaseApp.isDataCollectionDefaultEnabled());
          appMap.put(
              "pluginConstants",
              Tasks.await(FirebasePluginRegistry.getPluginConstantsForFirebaseApp(firebaseApp)));

          return appMap;
        });
  }

  private Task<Map<String, Object>> initializeApp(Map<String, Object> arguments) {
    return Tasks.call(
        Executors.newSingleThreadExecutor(),
        () -> {
          String name = (String) Objects.requireNonNull(arguments.get("appName"));
          Map<String, String> optionsMap =
              (Map<String, String>) Objects.requireNonNull(arguments.get("options"));

          FirebaseOptions options =
              new FirebaseOptions.Builder()
                  .setApiKey(Objects.requireNonNull(optionsMap.get("apiKey")))
                  .setApplicationId(Objects.requireNonNull(optionsMap.get("appId")))
                  .setDatabaseUrl(optionsMap.get("databaseURL"))
                  .setGcmSenderId(optionsMap.get("messagingSenderId"))
                  .setProjectId(optionsMap.get("projectId"))
                  .setStorageBucket(optionsMap.get("storageBucket"))
                  .build();

          FirebaseApp firebaseApp = FirebaseApp.initializeApp(applicationContext, options, name);
          return Tasks.await(firebaseAppToMap(firebaseApp));
        });
  }

  private Task<List<Map<String, Object>>> initializeCore() {
    return Tasks.call(
        Executors.newSingleThreadExecutor(),
        () -> {
          List<FirebaseApp> firebaseApps = FirebaseApp.getApps(applicationContext);
          List<Map<String, Object>> firebaseAppsList = new ArrayList<>(firebaseApps.size());

          for (FirebaseApp firebaseApp : firebaseApps) {
            firebaseAppsList.add(Tasks.await(firebaseAppToMap(firebaseApp)));
          }

          return firebaseAppsList;
        });
  }

  private Task<Void> setAutomaticDataCollectionEnabled(Map<String, Object> arguments) {
    return Tasks.call(
        () -> {
          String appName = (String) Objects.requireNonNull(arguments.get("appName"));
          boolean enabled = (boolean) Objects.requireNonNull(arguments.get("enabled"));
          FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
          firebaseApp.setDataCollectionDefaultEnabled(enabled);
          return null;
        });
  }

  private Task<Void> setAutomaticResourceManagementEnabled(Map<String, Object> arguments) {
    return Tasks.call(
        () -> {
          String appName = (String) Objects.requireNonNull(arguments.get("appName"));
          boolean enabled = (boolean) Objects.requireNonNull(arguments.get("enabled"));
          FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
          firebaseApp.setAutomaticResourceManagementEnabled(enabled);
          return null;
        });
  }

  private Task<Void> deleteApp(Map<String, Object> arguments) {
    return Tasks.call(
        () -> {
          String appName = (String) Objects.requireNonNull(arguments.get("appName"));
          FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
          try {
            firebaseApp.delete();
          } catch (IllegalStateException appNotFoundException) {
            // Ignore app not found exceptions.
          }

          return null;
        });
  }

  @Override
  public void onMethodCall(MethodCall call, @NonNull final MethodChannel.Result result) {
    Task methodCallTask;

    switch (call.method) {
      case "FirebaseCore#initializeApp":
        methodCallTask = initializeApp(call.arguments());
        break;
      case "FirebaseCore#initializeCore":
        methodCallTask = initializeCore();
        break;
      case "FirebaseApp#setAutomaticDataCollectionEnabled":
        methodCallTask = setAutomaticDataCollectionEnabled(call.arguments());
        break;
      case "FirebaseApp#setAutomaticResourceManagementEnabled":
        methodCallTask = setAutomaticResourceManagementEnabled(call.arguments());
        break;
      case "FirebaseApp#delete":
        methodCallTask = deleteApp(call.arguments());
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
            result.error("firebase_core", exception != null ? exception.getMessage() : null, null);
          }
        });
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return null;
  }
}
