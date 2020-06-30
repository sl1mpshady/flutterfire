// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// A structure containing the information of a second factor entity.
class MultiFactorInfo {
  @protected
  MultiFactorInfo(Map<String, dynamic> data) : _data = data;

  Map<String, dynamic> _data;

  /// The user friendly name of the current second factor.
  String get displayName {
    return _data['displayName'];
  }

  /// The enrollment date of the second factor.
  DateTime get enrollmentTime =>
      DateTime.fromMillisecondsSinceEpoch(_data['enrollmentTimestamp']);

  /// The identifier of the second factor.
  String get factorId {
    return _data['factorId'];
  }

  /// The multi-factor enrollment ID.
  String get uid {
    return _data['uid'];
  }
}
