// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

import 'auth_provider.dart';

const _kLinkProviderId = 'emailLink';
const _kProviderId = 'password';

/// Email and Password auth provider implementation.
class EmailAuthProvider extends AuthProvider {
  final String providerId = 'password';

  EmailAuthProvider._(String providerId) : super(providerId);

  static String get EMAIL_LINK_SIGN_IN_METHOD {
    return _kLinkProviderId;
  }

  static String get EMAIL_PASSWORD_SIGN_IN_METHOD {
    return _kProviderId;
  }

  static String get PROVIDER_ID {
    return _kProviderId;
  }

  static AuthCredential credential(String email, String password) {
    assert(email != null);
    assert(password != null);

    // TODO
    return AuthCredential();
  }

  static AuthCredential credentialWithLink(String email, String emailLink) {
    assert(email != null);
    assert(emailLink != null);

    // TODO
    return AuthCredential();
  }

  @Deprecated('Deprecated in favor of `EmailAuthProvider.credential()`')
  static AuthCredential getCredential({
    String email,
    String password,
  }) {
    return EmailAuthProvider.credential(email, password);
  }

  @Deprecated('Deprecated in favor of `EmailAuthProvider.credentialWithLink()`')
  static AuthCredential getCredentialWithLink({
    String email,
    String link,
  }) {
    return EmailAuthProvider.credentialWithLink(email, link);
  }
}
