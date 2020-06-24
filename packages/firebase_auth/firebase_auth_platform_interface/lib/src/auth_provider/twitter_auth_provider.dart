// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Twitter auth provider.
class TwitterAuthProvider implements AuthProvider {
  final String providerId = 'twitter.com';

  // todo: are these props actually needed, see:
  // https://firebase.google.com/docs/reference/js/firebase.auth.FacebookAuthProvider

  /// This corresponds to the sign-in method identifier.
  static String TWITTER_SIGN_IN_METHOD;
  static String PROVIDER_ID;

  /// Sets the OAuth custom parameters to pass in a Twitter OAuth
  /// request for popup and redirect sign-in operations.
  AuthProvider setCustomParameters(Object customOAuthParameters) {
    // todo implementation
    // valid parameters include auth_type, display, and locale.
    // check twitter documentation for detailed list.
    // reserved params will be ignored, i.e. client_id, redirect_uri, scope, response_type, and state
  }

  /// The auth provider credential.
  static AuthCredential getCredential({
    @required String token,
    @required String secret,
  }) {
    return TwitterAuthCredential(
      token: token,
      secret: secret,
    );
  }
}
