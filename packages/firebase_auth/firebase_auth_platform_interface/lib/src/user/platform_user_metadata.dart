// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class PlatformUserMetadata {
  const PlatformUserMetadata({this.creationTime, this.lastSignInTime});
  final String creationTime;
  final String lastSignInTime;
}
