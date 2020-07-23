// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The type of operation that generated the action code from calling [checkActionCode].
enum ActionCodeInfoOperation {
  /// Email sign in code generated via [sendSignInLinkToEmail].
  emailSignIn,

  /// Password reset code generated via [sendPasswordResetEmail].
  passwordReset,

  /// Email change revocation code generated via [User.updateEmail].
  recoverEmail,

  /// Verify and change email code generated via [User.verifyBeforeUpdateEmail].
  verifyAndChangeEmail,

  /// Email verification code generated via [User.sendEmailVerification].
  verifyEmail,
}

/// A response from calling [checkActionCode].
class ActionCodeInfo {
  // ignore: public_member_api_docs
  @protected
  ActionCodeInfo({
    int operation,
    @required Map<String, dynamic> data,
  })  : assert(data != null),
        _operation = operation,
        _data = data;

  int _operation;

  Map<String, dynamic> _data;

  /// The type of operation that generated the action code.
  ActionCodeInfoOperation get operation {
    switch (_operation) {
      case 4:
        return ActionCodeInfoOperation.emailSignIn;
      case 0:
        return ActionCodeInfoOperation.passwordReset;
      case 2:
        return ActionCodeInfoOperation.recoverEmail;
      case 5:
        return ActionCodeInfoOperation.verifyAndChangeEmail;
      case 1:
        return ActionCodeInfoOperation.verifyEmail;
      default:
        throw FallThroughError();
    }
  }

  /// The data associated with the action code.
  ///
  /// Depending on the [ActionCodeInfoOperation], `email` and `previousEmail`
  /// may be available.
  Map<String, dynamic> get data {
    if (data == null) return null;
    return <String, dynamic>{
      'email': _data['email'],
      'previousEmail': _data['previousEmail'],
    };
  }
}
