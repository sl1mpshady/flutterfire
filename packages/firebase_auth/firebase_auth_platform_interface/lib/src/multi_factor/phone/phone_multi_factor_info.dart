// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_info.dart';

/// The subclass of [MultiFactorInfo] for phone number second factors. The factorId
/// of this second factor is [PhoneMultiFactorGenerator.FACTOR_ID].
class PhoneMultiFactorInfo extends MultiFactorInfo {
  // todo constructor

  /// The phone number associated with the current second factor.
  final String phoneNumber;
}
