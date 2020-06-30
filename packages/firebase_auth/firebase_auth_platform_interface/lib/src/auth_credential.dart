// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
class AuthCredential {
  @protected
  const AuthCredential({
    @required this.providerId,
    @required this.signInMethod,
  })  : assert(providerId != null),
        assert(signInMethod != null);

  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId;

  /// The authentication sign in method for the credential.
  /// For example, 'password', or 'emailLink'. This corresponds
  /// to the sign-in method identifier returned in
  /// [fetchSignInMethodsForEmail].
  final String signInMethod;

  /// Returns the current instance as a serialized [Map].
  Map<String, dynamic> asMap() {
    throw UnimplementedError("asMap() is not implemented");
  }

  /// Returns a JSON representation of this object.
  Object toJSON() {
    throw UnimplementedError("toJSON() is not implemented");
  }

  /// Static method to deserialize a JSON representation of an
  /// object into an [AuthCredential]. Input can be either Object
  /// or the stringified representation of the object. If the JSON
  /// input does not represent an [AuthCredential], null is returned.
  static AuthCredential fromJSON(dynamic json) {
    throw UnimplementedError("fromJSON() is not implemented");
  }

  @override
  String toString() =>
      'AuthCredential(providerId: $providerId, signInMethod: $signInMethod)';
}