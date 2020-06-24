// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Defines the options for initializing an [OAuthCredential].
class OAuthCredentialOptions {
  const OAuthCredentialOptions({this.accessToken, this.idToken, this.rawNonce});

  /// The OAuth access token.
  final String accessToken;

  /// The OAuth ID token.
  final String idToken;

  /// The raw nonce associated with the ID token.
  final String rawNonce;
}
