// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'field_path.dart';

// TODO(ehesp): comments imply `.set()` is used on DocumentReference, WriteBatch & Transaction - check once confirmed

/// An options class that configures the behavior of set() calls in [DocumentReference],
/// [WriteBatcerh] and [Transaction].
class SetOptions {
  /// Changes the behavior of a set() call to only replace the values specified
  /// in its data argument.
  ///
  /// Fields omitted from the set() call remain untouched.
  final bool merge;

  /// Changes the behavior of set() calls to only replace the specified field paths.
  ///
  /// Any field path that is not specified is ignored and remains untouched.
  final List<FieldPath> mergeFields;

  /// Creates a [SetOptions] instance.
  SetOptions({
    this.merge,
    this.mergeFields,
  }) {
    assert(merge != null && mergeFields != null, "options must provide 'merge' or 'mergeFields'");
    // TODO(ehesp): Put into single assert statement
    if (merge != null && mergeFields != null) {
      assert(false, "options cannot have both 'merge' & 'mergeFields'");
    }
  }
}
