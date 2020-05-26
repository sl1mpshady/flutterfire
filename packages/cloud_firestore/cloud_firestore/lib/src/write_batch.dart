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
class WriteBatch {
  final WriteBatchPlatform _delegate;

  WriteBatch._(this._delegate) {
    WriteBatchPlatform.verifyExtends(_delegate);
  }

  /// Commits all of the writes in this write batch as a single atomic unit.
  ///
  /// Calling this method prevents any future operations from being added.
  Future<void> commit() => _delegate.commit();

  /// Deletes the document referred to by [document].
  void delete(DocumentReference document) {
    return _delegate.delete(document._delegate);
  }

  /// Writes to the document referred to by [document].
  ///
  /// If the document does not yet exist, it will be created.
  ///
  /// If [SetOptions] are provided, the data will be merged into an existing
  /// document instead of overwriting.
  // TODO(ehesp): should this be `set()`?
  void setData(DocumentReference document, Map<String, dynamic> data,
      [SetOptions options]) {
    return _delegate.setData(document._delegate,
        _CodecUtility.replaceValueWithDelegatesInMap(data), options);
  }

  // TODO(ehesp): should this be `update()`?
  void updateData(DocumentReference document, Map<String, dynamic> data) {
    return _delegate.updateData(
        document._delegate, _CodecUtility.replaceValueWithDelegatesInMap(data));
  }
}
