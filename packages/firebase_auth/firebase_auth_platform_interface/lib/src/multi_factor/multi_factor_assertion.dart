// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The base class for asserting ownership of second factor. This is used
/// to facilitate enrollment of a second factor on an existing user or
/// sign-in of a user who already verified the first factor.
abstract class MultiFactorAssertion {
  MultiFactorAssertion(this.factorId);

  /// The identifier of the second factor.
  final String factorId;
}
