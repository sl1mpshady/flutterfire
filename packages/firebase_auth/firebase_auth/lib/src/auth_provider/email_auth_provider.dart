// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// Email and Password auth provider implementation.
class EmailAuthProvider implements AuthProvider {
  final String providerId = 'password';

  // todo: are these properties actually needed?
  // see: https://firebase.google.com/docs/reference/js/firebase.auth.EmailAuthProvider

  /// This corresponds to the sign-in method identifier.
  static String EMAIL_PASSWORD_SIGN_IN_METHOD;

  /// This corresponds to the sign-in method identifier.
  static String EMAIL_LINK_SIGN_IN_METHOD;

  static String PROVIDER_ID;

  // TODO: rename both methods w/o 'get' prefix?
  static AuthCredential getCredential({
    String email,
    String password,
  }) {
    return EmailAuthCredential(email: email, password: password);
  }

  static AuthCredential getCredentialWithLink({
    String email,
    String link,
  }) {
    return EmailAuthCredential(email: email, link: link);
  }
}
