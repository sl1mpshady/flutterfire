// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Represents `AdditionalUserInfo` from Firebase.
///
/// See also: https://firebase.google.com/docs/reference/js/firebase.auth.html#additionaluserinfo
class PlatformAdditionalUserInfo {
  // TODO: username no longer required?
  const PlatformAdditionalUserInfo({
    @required this.isNewUser,
    @required this.providerId,
    @required this.username,
    @required this.profile,
  });

  final bool isNewUser;
  final String providerId;
  final String username;
  final Map<String, dynamic> profile;
}
