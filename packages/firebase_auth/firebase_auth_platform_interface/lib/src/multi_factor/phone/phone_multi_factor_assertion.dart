// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/multi_factor/multi_factor_assertion.dart';

/// The class for asserting ownership of a phone second factor
class PhoneMultiFactorAssertion extends MultiFactorAssertion {
  PhoneMultiFactorAssertion(String factorId) : super(factorId);
}
