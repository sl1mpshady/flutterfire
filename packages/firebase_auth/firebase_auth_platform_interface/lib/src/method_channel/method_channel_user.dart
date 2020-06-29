// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user_credential.dart';
import 'package:firebase_auth_platform_interface/src/platform_interface/platform_interface_user.dart';

import 'utils/exception.dart';

class MethodChannelUser extends UserPlatform {
  MethodChannelUser(FirebaseAuthPlatform auth, Map<String, dynamic> data)
      : super(auth, data);

  @override
  Future<void> delete() async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#delete', <String, dynamic>{
      'appName': auth.app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<String> getIdToken(bool forceRefresh) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<String>('User#getIdToken', <String, dynamic>{
      'appName': auth.app.name,
      'forceRefresh': forceRefresh,
      'tokenOnly': true,
    }).catchError(catchPlatformException);
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#getIdToken', <String, dynamic>{
      'appName': auth.app.name,
      'forceRefresh': forceRefresh,
      'tokenOnly': false,
    }).catchError(catchPlatformException);

    return IdTokenResult(data);
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
      AuthCredential credential) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#linkWithCredential', <String, dynamic>{
      'appName': auth.app.name,
      'credential': credential.asMap(),
    }).catchError(catchPlatformException);

    return MethodChannelUserCredential(auth, data);
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod('User#reauthenticateWithCredential', <String, dynamic>{
      'appName': auth.app.name,
      'credential': credential.asMap(),
    }).catchError(catchPlatformException);

    return MethodChannelUserCredential(auth, data);
  }

  @override
  Future<void> reload() async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#reload', <String, dynamic>{
      'appName': auth.app.name,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> sendEmailVerification(
      ActionCodeSettings actionCodeSettings) async {
    return MethodChannelFirebaseAuth.channel.invokeMethod<void>(
        'User#sendEmailVerification', <String, dynamic>{
      'appName': auth.app.name,
      'actionCodeSettings': actionCodeSettings?.asMap()
    }).catchError(catchPlatformException);
  }

  @override
  Future<UserPlatform> unlink(String providerId) async {
    Map<String, dynamic> data = await MethodChannelFirebaseAuth.channel
        .invokeMapMethod<String, dynamic>('User#unlink', <String, dynamic>{
      'appName': auth.app.name,
      'providerId': providerId,
    }).catchError(catchPlatformException);

    return MethodChannelUser(auth, data);
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#updateEmail', <String, dynamic>{
      'appName': auth.app.name,
      'newEmail': newEmail,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> updateProfile(Map<String, String> profile) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#updateProfile', <String, dynamic>{
      'appName': auth.app.name,
      'profile': profile,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings actionCodeSettings]) async {
    return MethodChannelFirebaseAuth.channel
        .invokeMethod<void>('User#verifyBeforeUpdateEmail', <String, dynamic>{
      'appName': auth.app.name,
      'newEmail': newEmail,
      'actionCodeSettings': actionCodeSettings?.asMap(),
    }).catchError(catchPlatformException);
  }
}
