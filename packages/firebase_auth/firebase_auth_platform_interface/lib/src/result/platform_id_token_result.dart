// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The result of calling [FirebaseAuthPlatform.getIdToken].
class PlatformIdTokenResult {
  const PlatformIdTokenResult({
    @required this.token,
    @required this.expirationTimestamp,
    @required this.authTimestamp,
    @required this.issuedAtTimestamp,
    @required this.claims,
    this.signInProvider,
  });

  /// The Firebase Auth ID token JWT string.
  final String token;

  /// The time when the ID token expires.
  final int expirationTimestamp;

  /// The time the user authenticated (signed in).
  ///
  /// Note that this is not the time the token was refreshed.
  final int authTimestamp;

  /// The time when ID token was issued.
  final int issuedAtTimestamp;

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  final Map<dynamic, dynamic> claims;

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  final String signInProvider;
}
