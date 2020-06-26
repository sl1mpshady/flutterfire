// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:meta/meta.dart';

class OAuthProvider {
  OAuthProvider(this.providerId) : assert(providerId != null);

  final String providerId;

  List<String> _scopes = [];
  Map<dynamic, dynamic> _parameters;

  List<String> get scopes {
    return _scopes;
  }

  Map<dynamic, dynamic> get parameters {
    return _parameters;
  }

  /// Adds OAuth scope.
  OAuthProvider addScope(String scope) {
    assert(scope != null);
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a OAuth
  /// request for popup and redirect sign-in operations.
  OAuthProvider setCustomParameters(
      Map<dynamic, dynamic> customOAuthParameters) {
    assert(customOAuthParameters != null);
    _parameters = customOAuthParameters;
    return this;
  }

  /// Create a new [FacebookAuthCredential] from a provided [accessToken];
  OAuthCredential credential({String accessToken, String idToken}) {
    return OAuthCredential(
      providerId: providerId,
      signInMethod: 'custom',
      accessToken: accessToken,
      idToken: idToken,
    );
  }

  @Deprecated('Deprecated in favor of `FacebookAuthProvider.credential()`')
  static AuthCredential getCredential(String token) {
    return FacebookAuthProvider.credential(token);
  }
}

class OAuthCredential extends AuthCredential {
  @protected
  const OAuthCredential(
      {@required String providerId,
      @required String signInMethod,
      this.accessToken,
      this.idToken,
      this.secret})
      : assert(providerId != null),
        assert(signInMethod != null),
        super(providerId: providerId, signInMethod: signInMethod);

  /// The OAuth access token associated with the credential if it belongs to an
  /// OAuth provider, such as `facebook.com`, `twitter.com`, etc.
  final String accessToken;

  /// The OAuth ID token associated with the credential if it belongs to an
  /// OIDC provider, such as `google.com`.
  final String idToken;

  /// The OAuth access token secret associated with the credential if it belongs
  /// to an OAuth 1.0 provider, such as `twitter.com`.
  final String secret;

  @override
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'idToken': idToken,
      'accessToken': accessToken,
      'secret': secret,
    };
  }
}
