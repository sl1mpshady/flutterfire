// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.firebase.core;

import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseApp;
import java.util.Map;

public interface FirebasePlugin {
  Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp);
}
