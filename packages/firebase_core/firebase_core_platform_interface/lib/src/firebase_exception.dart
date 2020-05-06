// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// A generic class which provides exceptions in a Firebase-friendly format
/// to users.
///
/// ```dart
/// try {
///   await FirebaseCore.instance.initializeApp();
/// } catch (e) {
///   print(e.toString());
/// }
/// ```
class FirebaseException implements Exception {
  FirebaseException(
      {@required this.plugin, @required this.message, this.code = 'unknown'});

  final String plugin;

  final String message;

  final String code;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseException) return false;
    return other.toString() == this.toString();
  }

  @override
  String toString() {
    return "[$plugin/$code] $message";
  }
}
