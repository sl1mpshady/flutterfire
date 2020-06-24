// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:flutter/foundation.dart';

/// An [AuthCredential] created by an email auth provider.
class EmailAuthCredential extends AuthCredential {
  const EmailAuthCredential({@required this.email, this.password, this.link})
      : assert(password != null || link != null,
            'One of "password" or "link" must be provided'),
        super(_providerId);

  static const String _providerId = 'password';

  /// The user's email address.
  final String email;

  /// The user account password.
  final String password;

  /// The sign-in email link.
  final String link;

  @override
  Map<String, String> _asMap() {
    final Map<String, String> result = <String, String>{'email': email};
    if (password != null) {
      result['password'] = password;
    }
    if (link != null) {
      result['link'] = link;
    }
    return result;
  }
}
