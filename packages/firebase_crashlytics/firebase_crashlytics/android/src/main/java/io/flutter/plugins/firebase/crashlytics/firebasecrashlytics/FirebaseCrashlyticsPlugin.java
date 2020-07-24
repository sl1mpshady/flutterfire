// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.crashlytics.firebasecrashlytics;

import android.content.Context;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.crashlytics.FirebaseCrashlytics;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;

/** FirebaseCrashlyticsPlugin */
public class FirebaseCrashlyticsPlugin
    implements FlutterFirebasePlugin, FlutterPlugin, MethodCallHandler {
  public static final String TAG = "CrashlyticsPlugin";
  private MethodChannel channel;

  private static MethodChannel setup(BinaryMessenger binaryMessenger, Context context) {
    final MethodChannel channel =
        new MethodChannel(binaryMessenger, "plugins.flutter.io/firebase_crashlytics");
    channel.setMethodCallHandler(new FirebaseCrashlyticsPlugin());
    return channel;
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    setup(registrar.messenger(), registrar.context());
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    BinaryMessenger binaryMessenger = binding.getBinaryMessenger();
    channel = setup(binaryMessenger, binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
  }

  FirebaseCrashlytics getCrashlytics(Map<String, Object> arguments) {
    return FirebaseCrashlytics.getInstance();
  }

  private Task<Boolean> checkForUnsentReports(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool, () -> Tasks.await(getCrashlytics(arguments).checkForUnsentReports()));
  }

  private void crash(final Map<String, Object> arguments) {
    new Handler()
        .postDelayed(
            () -> {
              throw new RuntimeException("FirebaseCrashlytics: Crash Test");
            },
            50);
  }

  private Task<Void> deleteUnsentReports(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          getCrashlytics(arguments).deleteUnsentReports();
          return null;
        });
  }

  private Task<Boolean> didCrashOnPreviousExecution(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool, () -> getCrashlytics(arguments).didCrashOnPreviousExecution());
  }

  private Task<Void> recordError(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseCrashlytics crashlytics = getCrashlytics(arguments);

          final String dartExceptionMessage =
              (String) Objects.requireNonNull(arguments.get("exception"));
          final String context = (String) arguments.get("context");
          final String information = (String) Objects.requireNonNull(arguments.get("information"));
          final Exception exception = new Exception(dartExceptionMessage);
          final List<StackTraceElement> elements = new ArrayList<>();

          @SuppressWarnings("unchecked")
          final List<Map<String, String>> errorElements =
              (List<Map<String, String>>)
                  Objects.requireNonNull(arguments.get("stackTraceElements"));

          for (Map<String, String> errorElement : errorElements) {
            final StackTraceElement stackTraceElement = generateStackTraceElement(errorElement);
            if (stackTraceElement != null) {
              elements.add(stackTraceElement);
            }
          }

          exception.setStackTrace(elements.toArray(new StackTraceElement[0]));

          crashlytics.setCustomKey("exception", dartExceptionMessage);

          // Set a "reason" (to match iOS) to show where the exception was thrown.
          if (context != null) {
            crashlytics.setCustomKey("reason", "thrown " + context);
          }

          // Log information.
          if (!information.isEmpty()) {
            crashlytics.log(information);
          }

          crashlytics.recordException(exception);
          return null;
        });
  }

  private Task<Void> log(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String message = (String) Objects.requireNonNull(arguments.get("message"));
          getCrashlytics(arguments).log(message);
          return null;
        });
  }

  private Task<Void> sendUnsentReports(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          getCrashlytics(arguments).sendUnsentReports();
          return null;
        });
  }

  private Task<Void> setCrashlyticsCollectionEnabled(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Boolean enabled = (Boolean) Objects.requireNonNull(arguments.get("enabled"));
          getCrashlytics(arguments).setCrashlyticsCollectionEnabled(enabled);
          return null;
        });
  }

  private Task<Void> setUserIdentifier(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String identifier = (String) Objects.requireNonNull(arguments.get("identifier"));
          getCrashlytics(arguments).setUserId(identifier);
          return null;
        });
  }

  private Task<Void> setCustomKey(final Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String key = (String) Objects.requireNonNull(arguments.get("key"));
          String value = (String) Objects.requireNonNull(arguments.get("value"));

          getCrashlytics(arguments).setCustomKey(key, value);
          return null;
        });
  }

  @Override
  public void onMethodCall(MethodCall call, @NonNull final MethodChannel.Result result) {
    Task<?> methodCallTask;

    switch (call.method) {
      case "Crashlytics#checkForUnsentReports":
        methodCallTask = checkForUnsentReports(call.arguments());
        break;
      case "Crashlytics#crash":
        crash(call.arguments());
        return;
      case "Crashlytics#deleteUnsentReports":
        methodCallTask = deleteUnsentReports(call.arguments());
        break;
      case "Crashlytics#didCrashOnPreviousExecution":
        methodCallTask = didCrashOnPreviousExecution(call.arguments());
        break;
      case "Crashlytics#recordError":
        methodCallTask = recordError(call.arguments());
        break;
      case "Crashlytics#log":
        methodCallTask = log(call.arguments());
        break;
      case "Crashlytics#sendUnsentReports":
        methodCallTask = sendUnsentReports(call.arguments());
        break;
      case "Crashlytics#setCrashlyticsCollectionEnabled":
        methodCallTask = setCrashlyticsCollectionEnabled(call.arguments());
        break;
      case "Crashlytics#setUserIdentifier":
        methodCallTask = setUserIdentifier(call.arguments());
        break;
      case "Crashlytics#setCustomKey":
        methodCallTask = setCustomKey(call.arguments());
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
            String message = exception != null ? exception.getMessage() : "An unknown error occurred";
            result.error("firebase_crashlytics", message, null);
          }
        });
  }

  /**
   * Extract StackTraceElement from Dart stack trace element.
   *
   * @param errorElement Map representing the parts of a Dart error.
   * @return Stack trace element to be used as part of an Exception stack trace.
   */
  private StackTraceElement generateStackTraceElement(Map<String, String> errorElement) {
    try {
      String fileName = errorElement.get("file");
      String lineNumber = errorElement.get("line");
      String className = errorElement.get("class");
      String methodName = errorElement.get("method");

      return new StackTraceElement(
          className == null ? "" : className, methodName, fileName, Integer.parseInt(lineNumber));
    } catch (Exception e) {
      Log.e(TAG, "Unable to generate stack trace element from Dart error.");
      return null;
    }
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return null;
  }

  @Override
  public Task<Void> didReinitializeFirebaseCore() {
    return null;
  }
}
