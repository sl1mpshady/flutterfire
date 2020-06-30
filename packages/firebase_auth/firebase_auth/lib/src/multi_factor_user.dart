// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

class MultiFactorUser {
  MultiFactorUserPlatform _delegate;

  MultiFactorUser._(this._delegate) {
    MultiFactorUserPlatform.verifyExtends(_delegate);
  }

  List<MultiFactorInfo> get enrolledFactors {
    return _delegate.enrolledFactors;
  }

  Future<void> enroll(MultiFactorAssertion multiFactorAssertion,
      [String displayName]) async {
    assert(multiFactorAssertion != null);
    await _delegate.enroll(multiFactorAssertion);
  }

  Future<void> unenroll(MultiFactorInfo multiFactorInfo) async {
    assert(multiFactorInfo != null);
    await _delegate.unenroll(multiFactorInfo);
  }
}
