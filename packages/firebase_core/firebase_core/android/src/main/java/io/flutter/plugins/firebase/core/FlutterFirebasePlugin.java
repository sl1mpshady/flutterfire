// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import androidx.annotation.Keep;
import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseApp;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Keep
public interface FlutterFirebasePlugin {
  // A shared ExecutorService used by all FlutterFire Plugins for their GMS Tasks.
  ExecutorService cachedThreadPool = Executors.newCachedThreadPool();

  /**
   * FlutterFire plugins implementing FlutterFirebasePlugin must provide this method to provide it's
   * constants that are initialized during FirebaseCore.initializeApp in Dart.
   *
   * @param firebaseApp The Firebase App that the plugin should return constants for.
   * @return A task returning the discovered constants for the plugin for the provided Firebase App.
   */
  Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp);
}
