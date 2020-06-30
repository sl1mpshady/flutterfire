// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// A structure containing the information of a second factor entity.
class MultiFactorAssertion {
  MultiFactorAssertion._({this.factorId, this.token})
      : assert(factorId != null),
        assert(token != null);

  final String factorId;

  final int token;

  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'factorId': factorId,
      'token': token,
    };
  }
}

abstract class PhoneMultiFactorGenerator {
  static String get FACTOR_ID {
    return 'phone';
  }

  static MultiFactorAssertion assertion(
      PhoneAuthCredential phoneAuthCredential) {
    assert(phoneAuthCredential != null);
    Map<String, dynamic> credentialMap = phoneAuthCredential.asMap();
    assert(credentialMap['token'] != null);

    return MultiFactorAssertion._(
      factorId: PhoneMultiFactorGenerator.FACTOR_ID,
      token: credentialMap['token'],
    );
  }
}
