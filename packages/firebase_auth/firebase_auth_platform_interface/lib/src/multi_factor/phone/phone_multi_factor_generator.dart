// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential/phone_auth_credential.dart';
import 'package:firebase_auth_platform_interface/src/multi_factor/phone/phone_multi_factor_assertion.dart';

/// The class used to initialize [PhoneMultiFactorAssertion].
class PhoneMultiFactorGenerator {
  // constructor

  /// The identifier of the phone second factor: phone.
  static String FACTOR_ID;

  /// Initializes the [PhoneMultiFactorAssertion] to confirm ownership of the phone
  /// second factor.
  static PhoneMultiFactorAssertion assertion(
      PhoneAuthCredential phoneAuthCredential) {
    // todo
  }
}
