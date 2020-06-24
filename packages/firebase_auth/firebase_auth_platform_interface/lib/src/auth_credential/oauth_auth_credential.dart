// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';

/// Abstract class to implement [OAuthCredential] authentications
abstract class OAuthCredential extends AuthCredential {
  // todo constructor

  /// The ID Token associated with this credential.
  final String idToken;

  /// The OAuth access token.
  final String accessToken;

  // The OAuth access token secret.
  final String secret;

// todo: remove below?

  /// The OAuth raw nonce.
//  final String rawNonce;
//
//  const OAuthCredential(
//    this.providerId,
//    this.idToken,
//    this.accessToken,
//    this.rawNonce,
//  ) : super(providerId);
//
//  @override
//  Map<String, String> _asMap() => <String, String>{
//        'idToken': idToken,
//        'accessToken': accessToken,
//        'providerId': providerId,
//        'rawNonce': rawNonce,
//      };
}
