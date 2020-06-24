// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// A response from [FirebaseAuthPlatform.checkActionCode]
class ActionCodeInfo {
  const ActionCodeInfo({
    this.operation,
    this.data,
  });

  /// The type of the operation that generated the action code.
  final String operation;

  /// The data associated with the action code.
  final Map<String, dynamic> data;
}
