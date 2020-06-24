// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Interface representing ID token result obtained from [getIdTokenResult].
/// It contains the ID token JWT string and other helper properties for getting
/// different data associated with the token as well as all the decoded payload
/// claims.
class IdTokenResult {
  const IdTokenResult({
    @required this.authTime,
    @required this.claims,
    @required this.expirationTime,
    @required this.issuedAtTime,
    @required this.token,
    this.signInProvider,
    this.signInSecondFactor,
  });

  /// The authentication time formatted as UTC string. This is the time the user
  /// authenticated (signed in) and not the time the token was refreshed.
  final String authTime;

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  final Map<String, dynamic> claims;

  /// The ID token expiration time formatted as a UTC string.
  final String expirationTime;

  /// The ID token issued at time formatted as a UTC string.
  final String issuedAtTime;

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc.). Note, this does not map to provider IDs.
  final String signInProvider;

  /// The type of second factor associated with this session, provided the user
  /// was multi-factor authenticated (for example, phone, etc.).
  final String signInSecondFactor;

  /// The [FirebaseAuth] ID token JWT string.
  final String token;
}
