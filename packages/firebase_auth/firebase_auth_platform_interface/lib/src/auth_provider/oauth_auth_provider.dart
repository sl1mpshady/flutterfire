// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Generic OAuth provider.
class OAuthProvider implements AuthProvider {
  const OAuthProvider({@required this.providerId}) : assert(providerId != null);

  /// Provider OAuth scope.
  AuthProvider addScope(String scope) {
    // todo implementation
  }

  /// Sets the OAuth custom parameters to pass in an OAuth request
  /// for popup and redirect sign-in operations.
  AuthProvider setCustomParameters(Object customOAuthParameters) {
    // todo implementation
    // valid parameters include auth_type, display, and locale.
    // check Oauth 2.0 documentation for detailed list.
    // reserved params will be ignored, i.e. client_id, redirect_uri, scope, response_type, and state
  }

  // todo: rename getCredential w/o 'get' prefix?
  // latest sig (dynamic optionsOrIdToken , String accessToken?)
  // optionsOrIdToken may be String or OAuthCredentialOptions

  /// Creates an [OAuthCredential] for the OAuth 2 provider with the provided parameters.
  OAuthCredential getCredential({
    @required String idToken,
    String accessToken,
    String rawNonce,
  }) {
    return PlatformOAuthCredential(
        providerId: providerId,
        idToken: idToken,
        accessToken: accessToken,
        rawNonce: rawNonce);
  }
}
