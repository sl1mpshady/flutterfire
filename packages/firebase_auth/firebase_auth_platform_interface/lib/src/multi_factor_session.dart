// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class MultiFactorSession {
  MultiFactorSession(this.resolverToken);

  factory MultiFactorSession.createNewSession() {
    return MultiFactorSession(-1);
  }

  final int resolverToken;

  Map<String, dynamic> asMap() {
    return {
      'token': resolverToken == -1 ? null : resolverToken,
    };
  }
}
