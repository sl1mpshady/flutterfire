// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_user.dart';
import 'package:firebase_auth_platform_interface/src/user/platform_user_info.dart';
import 'package:firebase_auth_platform_interface/src/user/platform_user_metadata.dart';
import 'package:flutter/foundation.dart';

/// Represents a `User` in Firebase.
///
/// See also: https://firebase.google.com/docs/reference/js/firebase.User
class PlatformUser extends PlatformUserInfo {
  const PlatformUser({
    @required String providerId,
    @required String uid,
    String displayName,
    String photoUrl, // todo: rename photoURL?
    String email,
    String phoneNumber,
    this.creationTimestamp, // todo: still needed? replace with PlatformUserMetadata
    this.lastSignInTimestamp, // todo: still needed? same as above
    @required this.isAnonymous,
    @required this.isEmailVerified, // todo: rename emailVerified?
    @required this.providerData,
    @required this.metadata,
    @required this.multiFactor,
    @required this.refreshToken,
    this.tenantId,
  }) : super(
          providerId: providerId,
          uid: uid,
          displayName: displayName,
          photoUrl: photoUrl,
          email: email,
          phoneNumber: phoneNumber,
        );

  final int creationTimestamp;
  final int lastSignInTimestamp;
  final bool isAnonymous;
  final bool isEmailVerified;
  final List<PlatformUserInfo> providerData;
  final PlatformUserMetadata metadata;
  final MultiFactorUser multiFactor;
  final String refreshToken;
  final String tenantId;
}
