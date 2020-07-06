// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// User profile information, visible only to the Firebase project's apps.
class UserInfo {
  @protected
  UserInfo(this._data);

  final Map<String, dynamic> _data;

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  String get displayName {
    return _data['displayName'];
  }

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  String get email {
    return _data['email'];
  }

  /// Returns the users phone number.
  ///
  /// This property will be `null` if the user has not signed in or been has their
  /// phone number linked.
  String get phoneNumber {
    return _data['phoneNumber'];
  }

  /// The federated provider ID.
  String get providerId {
    return _data['providerId'];
  }

  /// The user's unique ID.
  String get uid {
    return _data['uid'];
  }

  @override
  String toString() {
    return '$UserInfo(displayName: $displayName, email: $email, phoneNumber: $phoneNumber, providerId: $providerId, uid: $uid)';
  }
}
