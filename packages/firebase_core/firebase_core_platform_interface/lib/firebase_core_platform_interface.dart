// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_core_platoform_interface;

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:quiver/core.dart';

part 'src/firebase_options.dart';

part 'src/platform_interface/platform_interface_firebase_core.dart';
part 'src/platform_interface/platform_interface_firebase_app.dart';

part 'src/method_channel/method_channel_firebase_core.dart';
part 'src/method_channel/method_channel_firebase_app.dart';
