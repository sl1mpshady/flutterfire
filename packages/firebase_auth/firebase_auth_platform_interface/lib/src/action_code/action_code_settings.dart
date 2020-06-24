// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Interface that defines the required continue/state URL with optional
/// Android and iOS bundle identifiers.
class ActionCodeSettings {
  const ActionCodeSettings({
    this.android,
    this.dynamicLinkDomain,
    this.handleCodeInApp,
    this.iOS,
    @required this.url,
  });

  /// Sets the Android package name.
  final Map<String, dynamic> android;
  final String dynamicLinkDomain;

  /// The default is false. When true, the action code link will be sent
  /// as a Universal Link or Android App Link and will be opened by the
  /// app if installed.
  final bool handleCodeInApp;

  /// Sets the iOS bundle ID.
  final Map<String, dynamic> iOS;

  /// Sets the link continue/state URL
  final String url;
}
