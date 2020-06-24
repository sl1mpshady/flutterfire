// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Represents a `UserInfo` from Firebase.
///
/// See also: https://firebase.google.com/docs/reference/js/firebase.UserInfo
class PlatformUserInfo {
  const PlatformUserInfo({
    @required this.providerId,
    @required this.uid,
    this.displayName,
    this.photoUrl, // todo: rename photoURL?
    this.email,
    this.phoneNumber,
  });

  final String providerId;
  final String uid;
  final String displayName;
  final String photoUrl;
  final String email;
  final String phoneNumber;
}
