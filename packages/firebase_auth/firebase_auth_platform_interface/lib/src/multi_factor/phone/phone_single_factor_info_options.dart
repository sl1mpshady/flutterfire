// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The phone info options for single-factor sign-in. Only phone number is
/// required.
class PhoneSingleFactorInfoOptions {
  const PhoneSingleFactorInfoOptions(this.phoneNumber);

  final String phoneNumber;
}
