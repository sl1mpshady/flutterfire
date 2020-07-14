// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_web/firebase_auth_web_user_credential.dart';
import 'package:intl/intl.dart';

import 'utils.dart';

/// The format of an incoming metadata string timestamp from the firebase-dart library
final DateFormat _dateFormat = DateFormat('EEE, d MMM yyyy HH:mm:ss');

class UserWeb extends UserPlatform {
  UserWeb(FirebaseAuthPlatform auth, this._webUser)
      : super(auth, {
          'displayName': _webUser.displayName,
          'email': _webUser.email,
          'emailVerified': _webUser.emailVerified,
          'isAnonymous': _webUser.isAnonymous,
          'metadata': <String, int>{
            'creationTime': _dateFormat
                .parse(_webUser.metadata.creationTime)
                .millisecondsSinceEpoch,
            'lastSignInTime': _dateFormat
                .parse(_webUser.metadata.lastSignInTime)
                .millisecondsSinceEpoch,
          },
          'phoneNumber': _webUser.phoneNumber,
          'photoURL': _webUser.photoURL,
          'providerData': _webUser.providerData
              .map((firebase.UserInfo webUserInfo) => <String, dynamic>{
                    'displayName': webUserInfo.displayName,
                    'email': webUserInfo.email,
                    'phoneNumber': webUserInfo.phoneNumber,
                    'providerId': webUserInfo.providerId,
                    'uid': webUserInfo.uid,
                  })
              .toList(),
          'refreshToken': _webUser.refreshToken,
          'tenantId': null, // TODO: not supported on firebase-dart
          'uid': _webUser.uid,
        });

  final firebase.User _webUser;

  @override
  Future<void> delete() {
    return _webUser.delete();
  }

  @override
  Future<String> getIdToken(bool forceRefresh) {
    return _webUser.getIdToken(forceRefresh);
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    return convertWebIdTokenResult(
        await _webUser.getIdTokenResult(forceRefresh));
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
      AuthCredential credential) async {
    return UserCredentialWeb(
        auth,
        await _webUser
            .linkWithCredential(convertPlatformCredential(credential)));
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) async {
    return UserCredentialWeb(
        auth,
        await _webUser.reauthenticateWithCredential(
            convertPlatformCredential(credential)));
  }

  @override
  Future<void> reload() async {
    await _webUser.reload();
    auth.setCurrentUser(auth.currentUser);
  }

  @override
  Future<void> sendEmailVerification(ActionCodeSettings actionCodeSettings) {
    return _webUser.sendEmailVerification(
        convertPlatformActionCodeSettings(actionCodeSettings));
  }

  @override
  Future<UserPlatform> unlink(String providerId) async {
    return UserWeb(auth, await _webUser.unlink(providerId));
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await _webUser.updateEmail(newEmail);
    await _webUser.reload();
    auth.setCurrentUser(auth.currentUser);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _webUser.updatePassword(newPassword);
    await _webUser.reload();
    auth.setCurrentUser(auth.currentUser);
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    await _webUser
        .updatePhoneNumber(convertPlatformCredential(phoneCredential));
    await _webUser.reload();
    auth.setCurrentUser(auth.currentUser);
  }

  @override
  Future<void> updateProfile(Map<String, String> profile) async {
    await _webUser.updateProfile(firebase.UserProfile(
      displayName: profile['displayName'],
      photoURL: profile['photoURL'],
    ));
    await _webUser.reload();
    auth.setCurrentUser(auth.currentUser);
  }

  // TODO: not supported on firebase-dart
  // @override
  // Future<void> verifyBeforeUpdateEmail(String newEmail,
  //     [ActionCodeSettings actionCodeSettings]) async {}
}
