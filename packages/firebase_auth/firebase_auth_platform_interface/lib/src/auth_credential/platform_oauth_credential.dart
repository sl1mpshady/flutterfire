// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/oauth_auth_credential.dart';
import 'package:flutter/foundation.dart';

/// An [OAuthCredential] for authenticating via custom providerId.
/// Example: For Apple you can do it with
/// PlatformOAuthCredential _credential = PlatformOAuthCredential(
///   providerId: "apple.com",
///   idToken: appleIdToken,
///   accessToken: appleAccessToken
/// )
/// Optionally you can provide a rawNonce param
/// More info in https://firebase.google.com/docs/auth/ios/apple
class PlatformOAuthCredential extends OAuthCredential {
  const PlatformOAuthCredential(
      {@required String providerId,
      @required String idToken,
      String accessToken,
      String rawNonce})
      : super(providerId, idToken, accessToken, rawNonce);
}
