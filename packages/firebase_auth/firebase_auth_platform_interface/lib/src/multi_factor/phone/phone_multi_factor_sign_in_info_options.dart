// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_info.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_session.dart';
import 'package:flutter/foundation.dart';

/// The phone info options for multi-factor sign-in. Either multi-factor
/// hint or multi-factor UID and multi-factor session are required.
class PhoneMultiFactorSignInInfoOptions {
  const PhoneMultiFactorSignInInfoOptions(
      {this.multiFactorHint, this.multiFactorUid, @required this.session});

  final MultiFactorInfo multiFactorHint;
  final String multiFactorUid;
  final MultiFactorSession session;
}
