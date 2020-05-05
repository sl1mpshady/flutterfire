// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// Throws a consistent cross-platform error message
FirebaseException noAppExists(String appName) {
  return FirebaseException(
      plugin: 'core',
      code: 'no-app',
      message:
          "No Firebase App '${appName}' has been created - call FirebaseCore.instance.initializeApp()");
}

FirebaseException noDefaultAppInitialization() {
  return FirebaseException(
      plugin: 'core',
      message:
          'The $defaultFirebaseAppName app cannot be initialized here. To initialize the default app, follow the installation instructions for the specific platform you are developing with.');
}

FirebaseException coreNotInitialized() {
  return FirebaseException(
      plugin: 'core',
      code: 'not-initialized',
      message:
          'Firebase has not been initialized for this application. Please view the getting started documentation (https://firebaseextended.github.io/flutterfire/docs/overview) to learn how to initialize Firebase for your platform.');
}

FirebaseException noDefaultAppDelete() {
  return FirebaseException(
      plugin: 'core',
      message: 'The default Firebase app instance cannot be deleted.');
}
