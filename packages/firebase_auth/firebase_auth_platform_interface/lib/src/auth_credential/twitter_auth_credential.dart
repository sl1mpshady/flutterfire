// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:flutter/foundation.dart';

/// An [AuthCredential] for authenticating via twitter.com.
class TwitterAuthCredential extends AuthCredential {
  const TwitterAuthCredential({
    @required this.authToken,
    @required this.authTokenSecret,
  }) : super(_providerId);

  static const String _providerId = 'twitter.com';

  /// The Twitter access token.
  final String authToken;

  /// The Twitter secret token.
  final String authTokenSecret;

  @override
  Map<String, String> _asMap() => <String, String>{
        'authToken': authToken,
        'authTokenSecret': authTokenSecret,
      };
}
