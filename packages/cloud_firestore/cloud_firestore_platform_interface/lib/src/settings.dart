// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Constant used to indicate the LRU garbage collection should be disabled.
///
/// Set this value as the cacheSizeBytes on the settings passed to the Firestore instance.
const int CACHE_SIZE_UNLIMITED = -1;

class Settings {
  /// Creates an instance for these [Settings].
  const Settings(
      {this.persistenceEnabled,
      this.host,
      this.sslEnabled,
      this.cacheSizeBytes});

  /// Attempts to enable persistent storage, if possible.
  final bool persistenceEnabled;

  /// The hostname to connect to.
  final String host;

  /// Whether to use SSL when connecting.
  final bool sslEnabled;

  /// An approximate cache size threshold for the on-disk data.
  ///
  /// If the cache grows beyond this size, Firestore will start removing data that hasn't
  /// been recently used. The size is not a guarantee that the cache will stay
  /// below that size, only that if the cache exceeds the given size, cleanup
  /// will be attempted.
  ///
  /// The default value is 40 MB. The threshold must be set to at least 1 MB,
  /// and can be set to CACHE_SIZE_UNLIMITED to disable garbage collection.
  final int cacheSizeBytes;

  /// Returns the settings as a [Map]
  Map<String, dynamic> get asMap {
    return {
      'persistenceEnabled': persistenceEnabled,
      'host': host,
      'sslEnabled': sslEnabled,
      'cacheSizeBytes': cacheSizeBytes
    };
  }
}
