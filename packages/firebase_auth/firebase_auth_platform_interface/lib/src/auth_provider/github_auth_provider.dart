// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Github auth provider.
class GithubAuthProvider implements AuthProvider {
  final String providerId = 'github.com';

  // todo: are these props actually required? see:
  // https://firebase.google.com/docs/reference/js/firebase.auth.GithubAuthProvider
  /// This corresponds to the sign-in method identifier.
  static String GITHUB_SIGN_IN_METHOD;
  static String PROVIDER_ID;

  /// Github OAuth scope.
  AuthProvider addScope(String scope) {
    // todo implementation
  }

  /// Sets the OAuth custom parameters to pass in a Github OAuth
  /// request for popup and redirect sign-in operations.
  AuthProvider setCustomParameters(Object customOAuthParameters) {
    // todo implementation
    // valid parameters include auth_type, display, and locale.
    // check github documentation for detailed list.
    // reserved params will be ignored, i.e. client_id, redirect_uri, scope, response_type, and state
  }

  // todo: rename getCredential w/o 'get' prefix?

  static AuthCredential getCredential({String token}) {
    return GithubAuthCredential(token: token);
  }
}
