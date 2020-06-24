// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Interface that represents an auth provider.
class AuthProvider {
  const AuthProvider(this.providerId);
  final String providerId;
}
