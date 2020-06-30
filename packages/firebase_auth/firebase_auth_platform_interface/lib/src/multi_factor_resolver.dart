// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class MultiFactorResolver {
  MultiFactorResolver(Map<String, dynamic> data) : _data = data;

  Map<String, dynamic> _data;

  List<MultiFactorInfo> get hints {
    return _data['hints'].map((multiFactorInfo) {
      return MultiFactorInfo(Map<String, dynamic>.from(multiFactorInfo));
    });
  }

  MultiFactorSession get session {
    return MultiFactorSession(_data['token']);
  }
}
