// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:flutter/foundation.dart';

/// An [AuthCredential] for authenticating via google.com.
class GoogleAuthCredential extends AuthCredential {
  const GoogleAuthCredential({
    @required this.idToken,
    @required this.accessToken,
  }) : super(_providerId);

  static const String _providerId = 'google.com';

  /// The Google ID token.
  final String idToken;

  /// The Google access token.
  final String accessToken;

  @override
  Map<String, String> _asMap() => <String, String>{
        'idToken': idToken,
        'accessToken': accessToken,
      };
}
