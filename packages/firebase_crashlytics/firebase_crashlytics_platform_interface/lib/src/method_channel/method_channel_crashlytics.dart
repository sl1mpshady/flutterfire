// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../platform_interface/platform_interface_crashlytics.dart';
import './utils/exception.dart';

/// The entry point for accessing a Crashlytics.
///
/// You can get an instance by calling [FirebaseCrashlytics.instance].
class MethodChannelFirebaseCrashlytics extends FirebaseCrashlyticsPlatform {
  /// Create an instance of [MethodChannelFirebaseCrashlytics].
  MethodChannelFirebaseCrashlytics({FirebaseApp app}) : super(appInstance: app);

  /// The [MethodChannel] used to communicate with the native plugin
  static MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_crashlytics',
  );

  @override
  Future<bool> checkForUnsentReports() {
    return channel.invokeMethod<bool>(
        'Crashlytics#checkForUnsentReports', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  void crash() {
    channel.invokeMethod<bool>('Crashlytics#crash', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> deleteUnsentReports() {
    return channel.invokeMethod<void>(
        'Crashlytics#deleteUnsentReports', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<bool> didCrashOnPreviousExecution() {
    return channel.invokeMethod<bool>(
        'Crashlytics#didCrashOnPreviousExecution', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> recordError({
    String exception,
    String context,
    String information,
    List<Map<String, String>> stackTraceElements,
  }) {
    return channel
        .invokeMethod<void>('Crashlytics#recordError', <String, dynamic>{
      'appName': app.name,
      'exception': exception,
      'context': context,
      'information': information,
      'stackTraceElements': stackTraceElements ?? [],
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> log(String message) {
    return channel.invokeMethod<void>('Crashlytics#log', <String, dynamic>{
      'appName': app.name,
      'message': message,
    });
  }

  @override
  Future<void> sendUnsentReports() {
    return channel
        .invokeMethod<void>('Crashlytics#sendUnsentReports', <String, dynamic>{
      'appName': app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) {
    return channel.invokeMethod<void>(
        'Crashlytics#setCrashlyticsCollectionEnabled', <String, dynamic>{
      'appName': app.name,
      'enabled': enabled,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> setUserIdentifier(String identifier) {
    return channel
        .invokeMethod<void>('Crashlytics#setUserIdentifier', <String, dynamic>{
      'appName': app.name,
      'identifier': identifier,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> setCustomKey(String key, String value) {
    return channel
        .invokeMethod<void>('Crashlytics#setCustomKey', <String, dynamic>{
      'appName': app.name,
      'key': key,
      'value': value,
    }).catchError(catchPlatformException);
  }
}
