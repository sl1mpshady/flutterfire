// Copyright 2018, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [WriteBatch] is a series of write operations to be performed as one unit.
///
/// Operations done on a [WriteBatch] do not take effect until you [commit].
///
/// Once committed, no further operations can be performed on the [WriteBatch],
/// nor can it be committed again.
class WriteBatch implements WriteBatchPlatform {
  final WriteBatchPlatform _delegate;

  WriteBatch._(this._delegate) {
    WriteBatchPlatform.verifyExtends(_delegate);
  }

  @override
  Future<void> commit() => _delegate.commit();

  @override
  void delete(DocumentReferencePlatform document) {
    return _delegate.delete(document);
  }

  @override
  void setData(DocumentReferencePlatform document, Map<String, dynamic> data,
      {bool merge = false}) {
    return _delegate.setData(
        document, _CodecUtility.replaceValueWithDelegatesInMap(data),
        merge: merge);
  }

  @override
  void updateData(
      DocumentReferencePlatform document, Map<String, dynamic> data) {
    return _delegate.updateData(
        document, _CodecUtility.replaceValueWithDelegatesInMap(data));
  }
}
