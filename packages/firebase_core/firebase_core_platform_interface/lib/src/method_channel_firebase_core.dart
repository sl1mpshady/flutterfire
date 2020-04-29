// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import '../firebase_core_platform_interface.dart';

class MethodChannelFirebaseCore implements FirebaseCorePlatform {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  Future<FirebaseAppPlatform> apsdsdps(String name) async {
    final Map<String, dynamic> app =
        await channel.invokeMapMethod<String, dynamic>(
      'FirebaseApp#appNamed',
      name,
    );
    if (app == null) return null;
    return FirebaseAppPlatform(
        app['name'], FirebaseOptions.from(app['options']));
  }

  Future<void> configure(String name, FirebaseOptions options) {
    return channel.invokeMethod<void>(
      'FirebaseApp#configure',
      <String, dynamic>{'name': name, 'options': options.asMap},
    );
  }

  Future<List<FirebaseAppPlatform>> allApps() async {
    final List<dynamic> result = await channel.invokeListMethod<dynamic>(
      'FirebaseApp#allApps',
    );
    return result
        ?.map<FirebaseAppPlatform>(
          (dynamic app) => FirebaseAppPlatform(
            app['name'],
            FirebaseOptions.from(app['options']),
          ),
        )
        ?.toList();
  }
}
