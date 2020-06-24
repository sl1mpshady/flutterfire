// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user_credential.dart';
import 'package:firebase_auth_platform_interface/src/platform_interface/platform_interface_user.dart';

class MethodChannelUser extends UserPlatform {
  MethodChannelUser(FirebaseAuthPlatform auth, Map<String, dynamic> data)
      : super(auth, data);

  @override
  Future<void> delete() async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#delete', <String, dynamic>{
      'appName': auth.app.name,
    });
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#getIdTokenResult', <String, dynamic>{
      'appName': auth.app.name,
      'forceRefresh': forceRefresh,
    });

    return IdTokenResult(data);
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
      AuthCredential credential) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#linkWithCredential', <String, dynamic>{
      'appName': auth.app.name,
      'credential': credential.asMap(),
    });

    return MethodChannelUserCredential(auth, data);
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#reauthenticateWithCredential', <String, dynamic>{
      'appName': auth.app.name,
      'credential': credential.asMap(),
    });

    return MethodChannelUserCredential(auth, data);
  }

  @override
  Future<void> reload() async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#reload', <String, dynamic>{
      'appName': auth.app.name,
    });
  }

  @override
  Future<void> sendEmailVerification(
      ActionCodeSettings actionCodeSettings) async {
    return MethodChannelFirebaseAuth.channel.invokeMethod<void>(
        'User#sendEmailVerification', <String, dynamic>{
      'appName': auth.app.name,
      'actionCodeSettings': actionCodeSettings.asMap()
    });
  }

  @override
  Future<void> unlink(String providerId) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#unlink', <String, dynamic>{
      'appName': auth.app.name,
      'providerId': providerId,
    });
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#updateEmail', <String, dynamic>{
      'appName': auth.app.name,
      'newEmail': newEmail,
    });
  }

  @override
  Future<void> updateProfile(Map<String, String> profile) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#updateProfile', <String, dynamic>{
      'appName': auth.app.name,
      'profile': profile,
    });
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings actionCodeSettings]) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#verifyBeforeUpdateEmail', <String, dynamic>{
      'appName': auth.app.name,
      'newEmail': newEmail,
      'actionCodeSettings': actionCodeSettings?.asMap(),
    });
  }
}
