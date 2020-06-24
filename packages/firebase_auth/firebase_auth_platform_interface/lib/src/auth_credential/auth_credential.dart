// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
abstract class AuthCredential {
  const AuthCredential({this.providerId, this.signInMethod});

  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId;

  /// The authentication sign in method for the credential.
  /// For example, 'password', or 'emailLink'. This corresponds
  /// to the sign-in method identifier returned in
  /// [fetchSignInMethodsForEmail].
  final String signInMethod;

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

  /// Returns the data for this credential serialized as a map.
  Map<String, String> _asMap();

  @override
  String toString() => _asMap().toString();
}
