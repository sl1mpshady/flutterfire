// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A structure containing the information of a second factor entity.
abstract class MultiFactorInfo {
  const MultiFactorInfo({
    this.displayName,
    this.enrollmentTime,
    this.factorId,
    this.uid,
  });

  /// The user friendly name of the current second factor.
  final String displayName;

  /// The enrollment date of the second factor formatted as a UTC string.
  final String enrollmentTime;

  /// The identifier of the second factor.
  final String factorId;

  /// The multi-factor enrollment ID.
  final String uid;
}
