// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Google auth provider.
class GoogleAuthProvider implements AuthProvider {
  final String providerId = 'google.com';

  // todo: are these props actually required? see:
  // https://firebase.google.com/docs/reference/js/firebase.auth.GoogleAuthProvider
  /// This corresponds to the sign-in method identifier.
  static String GOOGLE_SIGN_IN_METHOD;
  static String PROVIDER_ID;

  /// Google OAuth scope.
  AuthProvider addScope(String scope) {
    // todo implementation
  }

  /// Sets the OAuth custom parameters to pass in a Google OAuth
  /// request for popup and redirect sign-in operations.
  AuthProvider setCustomParameters(Object customOAuthParameters) {
    // todo implementation
    // valid parameters include auth_type, display, and locale.
    // check google documentation for detailed list.
    // reserved params will be ignored, i.e. client_id, redirect_uri, scope, response_type, and state
  }

  // todo: rename getCredential w/o 'get' prefix?

  static AuthCredential getCredential({
    @required String idToken,
    @required String accessToken,
  }) {
    return GoogleAuthCredential(idToken: idToken, accessToken: accessToken);
  }
}
