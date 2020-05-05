// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

class MethodChannelFirebasePlugin extends FirebasePluginPlatform {
  MethodChannelFirebasePlugin(FirebaseAppPlatform app, String methodChannelName)
      : super(app, methodChannelName);
}
