// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:flutter/foundation.dart';

/// An [AuthCredential] for authenticating via github.com.
class GithubAuthCredential extends AuthCredential {
  const GithubAuthCredential({@required this.token}) : super(_providerId);

  static const String _providerId = 'github.com';

  /// The Github token.
  final String token;

  @override
  Map<String, String> _asMap() => <String, String>{
        'token': token,
      };
}
