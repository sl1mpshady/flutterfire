// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_session.dart';

/// The phone info options for multi-factor enrollment. Phone number and
/// multi-factor session are required.
class PhoneMultiFactorEnrollInfoOptions {
  //todo

  final MultiFactorSession session;
  final String phoneNumber;
}
