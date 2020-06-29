// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user.dart';
import 'package:firebase_auth_platform_interface/src/platform_interface/platform_interface_user_credential.dart';

class MethodChannelUserCredential extends UserCredentialPlatform {
  MethodChannelUserCredential(
      FirebaseAuthPlatform auth, Map<String, dynamic> data)
      : super(
          auth: auth,
          additionalUserInfo: AdditionalUserInfo(
            isNewUser: data['additionalUserInfo']['isNewUser'],
            profile: data['additionalUserInfo']['profile'],
            providerId: data['additionalUserInfo']['providerId'],
            username: data['additionalUserInfo']['username'],
          ),
          credential: AuthCredential(
            providerId: data['authCredential']['providerId'],
            signInMethod: data['authCredential']['signInMethod'],
          ),
          user: MethodChannelUser(auth, data['user']),
        );
}
