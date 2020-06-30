// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Interface representing ID token result obtained from [getIdTokenResult].
/// It contains the ID token JWT string and other helper properties for getting
/// different data associated with the token as well as all the decoded payload
/// claims.
///
/// Note that these claims are not to be trusted as they are parsed client side.
/// Only server side verification can guarantee the integrity of the token
/// claims.
class IdTokenResult {
  @protected
  IdTokenResult(this._data);

  final Map<String, dynamic> _data;

  /// The authentication time formatted as UTC string. This is the time the user
  /// authenticated (signed in) and not the time the token was refreshed.
  DateTime get authTime =>
      DateTime.fromMillisecondsSinceEpoch(_data['authTimestamp']);

  Map<String, dynamic> get claims => _data['claims'] == null
      ? null
      : Map<String, dynamic>.from(_data['claims']);

  /// The time when the ID token expires.
  DateTime get expirationTime =>
      DateTime.fromMillisecondsSinceEpoch(_data['expirationTimestamp']);

  /// The time when ID token was issued.
  DateTime get issuedAtTime =>
      DateTime.fromMillisecondsSinceEpoch(_data['issuedAtTimestamp']);

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  String get signInProvider => _data['signInProvider'];

  /// The type of second factor associated with this session, provided the user
  /// was multi-factor authenticated (for example, phone, etc.).
  String get signInSecondFactor => _data['signInSecondFactor'];

  /// The Firebase Auth ID token JWT string.
  String get token => _data['token'];

  @override
  String toString() {
    return '$IdTokenResult(${_data.toString()})';
  }
}