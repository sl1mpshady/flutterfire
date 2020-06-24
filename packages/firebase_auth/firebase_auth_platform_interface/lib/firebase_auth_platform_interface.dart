// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_auth_platform_interface;

import 'dart:async';

import 'package:firebase_auth_platform_interface/src/action_code/action_code_info.dart';
import 'package:firebase_auth_platform_interface/src/action_code/action_code_settings.dart';
import 'package:firebase_auth_platform_interface/src/application_verifier/application_verifier.dart';
import 'package:firebase_auth_platform_interface/src/auth_credential/auth_credential.dart';
import 'package:firebase_auth_platform_interface/src/auth_credential/phone_auth_credential.dart';
import 'package:firebase_auth_platform_interface/src/auth_exception.dart';
import 'package:firebase_auth_platform_interface/src/auth_provider/auth_provider.dart';
import 'package:firebase_auth_platform_interface/src/auth_settings.dart';
import 'package:firebase_auth_platform_interface/src/result/confirmation_result.dart';
import 'package:firebase_auth_platform_interface/src/result/platform_auth_result.dart';
import 'package:firebase_auth_platform_interface/src/result/platform_id_token_result.dart';
import 'package:firebase_auth_platform_interface/src/user/platform_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

part 'src/method_channel_firebase_auth.dart';
part 'src/types.dart';

/// The interface that implementations of `firebase_auth` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `firebase_auth` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [FirebaseAuthPlatform] methods.
abstract class FirebaseAuthPlatform extends PlatformInterface {
  /// The app associated with this FirebaseAuth instance.
  final FirebaseApp app;

  /// The currently signed-in user (or null).
  final PlatformUser currentUser;

  /// The current instance's language code. This is a readable/writeable
  /// property. When set to null, the default Firebase Console language setting
  /// is applied.
  final String languageCode;

  /// The current instance's settings.
  final AuthSettings settings;

  /// The current instance's tenant ID. When set to null, users are signed in
  /// to the parent project. By default, this is set to null;
  final String tenantId;

  /// The persistence mechanism type. Possible values include LOCAL, NONE, SESSION
  final String persistence;

  static final Object _token = Object();
  static FirebaseAuthPlatform _instance;

  /// Create an instance using [app]
  FirebaseAuthPlatform(
      {FirebaseApp app,
      this.currentUser,
      this.languageCode,
      this.settings,
      this.tenantId,
      this.persistence})
      : app = app ?? Firebase.app(),
        super(token: _token);

  /// Create an instance using [app] using the existing implementation
  factory FirebaseAuthPlatform.instanceFor({FirebaseApp app}) {
    return FirebaseAuthPlatform.instance.withApp(app);
  }

  /// The current default [FirebaseAuthPlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseAuth]
  /// if no web implementation was provided.
  static FirebaseAuthPlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirebaseAuth();
    }
    return _instance;
  }

  /// Sets the [FirebaseAuthPlatform.instance]
  static set instance(FirebaseAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  FirebaseAuthPlatform withApp(FirebaseApp app) {
    throw UnimplementedError("withApp() not implemented");
  }

  /// Applies a verification code sent to the user by email or
  /// other out-of-band mechanism.
  Future<void> applyActionCode(String code) {
    throw UnimplementedError("applyActionCode() is not implemented");
  }

  /// Checks a verification code sent to the user by email or
  /// other out-of-band mechanism.
  Future<ActionCodeInfo> checkActionCode(String code) {
    throw UnimplementedError("checkActionCode() is not implemented");
  }

  /// Completes the password reset process, given a confirmation code and new password.
  Future<void> confirmPasswordReset(
    String code,
    String newPassword,
  ) {
    throw UnimplementedError('confirmPasswordReset() is not implemented');
  }

  /// Create a user with the given [email] and [password].
  Future<PlatformAuthResult> createUserWithEmailAndPassword(
    String app,
    String email,
    String password,
  ) {
    throw UnimplementedError(
        'createUserWithEmailAndPassword() is not implemented');
  }

  /// Gets the list of possible sign in methods for the given email address.
  Future<List<String>> fetchSignInMethodsForEmail(String app, String email) {
    throw UnimplementedError('fetchSignInMethodsForEmail() is not implemented');
  }

  /// Returns a [PlatformAuthResult] from the redirect-based sign-in flow.
  Future<PlatformAuthResult> getRedirectResult() {
    throw UnimplementedError('getRedirectResult() is not implemented');
  }

  /// Checks if an incoming link is a sign-in with email link.
  Future<bool> isSignInWithEmailLink(String app, String emailLink) {
    throw UnimplementedError('isSignInWithEmailLink() is not implemented');
  }

  /// Creates a new stream which emits the current user on signOut and signIn.
  Stream<PlatformUser> onAuthStateChanged(String app) {
    throw UnimplementedError('onAuthStateChanged() is not implemented');
  }

  /// Creates a new stream which emits the current user when there are changes to
  /// the signed-in user's ID token, which includes sign-in sign-out, and token
  /// refresh events. This method has the same behavior as [onAuthStateChanged]
  /// had prior to 4.0.0.
  Stream<PlatformUser> onIdTokenChanged() {
    throw UnimplementedError('onIdTokenChanged() is not implemented');
  }

  /// Sends a password reset email to the given [email].
  Future<void> sendPasswordResetEmail(String app, String email,
      [ActionCodeSettings actionCodeSettings]) {
    throw UnimplementedError('sendPasswordResetEmail() is not implemented');
  }

  /// Sends a sign-in email link to the given [email].
  Future<void> sendSignInLinkToEmail(String email,
      [ActionCodeSettings actionCodeSettings]) {
    throw UnimplementedError('sendSignInLinkToEmail() is not implemented');
  }

  /// Changes the current type of persistence on the current Auth instance for
  /// the currently save Auth session and applies this type of persistence for
  /// future sign-in requests, including sign-in with redirect requests.
  Future<void> setPersistence(String persistence) {
    throw UnimplementedError('setPersistence() is not implemented');
  }

  /// Sign in anonymously and return the auth result.
  Future<PlatformAuthResult> signInAnonymously() {
    throw UnimplementedError('signInAnonymously() is not implemented');
  }

  /// Signs in with the given [credential].
  Future<PlatformAuthResult> signInWithCredential(
    String app,
    AuthCredential credential,
  ) {
    throw UnimplementedError('signInWithCredential() is not implemented');
  }

  /// Signs in with the given custom [token].
  Future<PlatformAuthResult> signInWithCustomToken(String app, String token) {
    throw UnimplementedError('signInWithCustomToken() is not implemented');
  }

  /// Signs in with the given [email] and [password]
  Future<PlatformAuthResult> signInWithEmailAndPassword(
      String email, String password) {
    throw UnimplementedError('signInWithEmailAndPassword() is not implemented');
  }

  /// Signs in with the given [email] and sign-in email link. If no link is passed,
  /// the link is inferred from the current URL.
  Future<PlatformAuthResult> signInWithEmailLink(String email,
      [String emailLink]) {
    throw UnimplementedError('signInWithEmailLink() is not implemented');
  }

  /// Signs in with the given [phoneNumber]. For abuse prevention, this method also
  /// requires an [ApplicationVerifier].
  Future<ConfirmationResult> signInWithPhoneNumber(
      String phoneNumber, ApplicationVerifier applicationVerifier) {
    throw UnimplementedError('signInWithPhoneNumber() is not implemented');
  }

  /// Authenticates a client using a full-page redirect flow.
  Future<void> signInWithRedirect(AuthProvider provider) {
    throw UnimplementedError('signInWithRedirect() is not implemented');
  }

  /// Signs the current user out of the app.
  Future<void> signOut(String app) {
    throw UnimplementedError('signOut() is not implemented');
  }

  /// Sets the provided user as [currentUser] on the current Auth instance.
  Future<void> updateCurrentUser(PlatformUser user) {
    throw UnimplementedError('updateCurrentUser() is not implemented');
  }

  /// Sets the current language to the default device/browser preference.
  void useDeviceLanguage() {
    throw UnimplementedError('useDeviceLanguage() is not implemented');
  }

  /// Checks a password reset code sent to the user by email or other
  /// out-of-band mechanism.
  Future<String> verifyPasswordResetCode(String code) {
    throw UnimplementedError('verifyPasswordResetCode() is not implemented');
  }

  // TODO: All the below deprecated? not in latest js SDK...?
//  /// Returns the current user.
//  Future<PlatformUser> getCurrentUser(String app) {
//    throw UnimplementedError('getCurrentUser() is not implemented');
//  }
//
//  /// Sends a sign in with email link to provided email address.
//  Future<void> sendLinkToEmail(
//    String app, {
//    @required String email,
//    @required String url,
//    @required bool handleCodeInApp,
//    @required String iOSBundleID,
//    @required String androidPackageName,
//    @required bool androidInstallIfNotAvailable,
//    @required String androidMinimumVersion,
//  }) {
//    throw UnimplementedError('sendLinkToEmail() is not implemented');
//  }
//
//  /// Signs in with the given [email] and [link].
//  Future<PlatformAuthResult> signInWithEmailAndLink(
//    String app,
//    String email,
//    String link,
//  ) {
//    throw UnimplementedError('signInWithEmailAndLink() is not implemented');
//  }
//
//  /// Sends an email verification to the current user.
//  Future<void> sendEmailVerification(String app) {
//    throw UnimplementedError('sendEmailVerification() is not implemented');
//  }
//
//  /// Refreshes the current user, if signed in.
//  Future<void> reload(String app) {
//    throw UnimplementedError('reload() is not implemented');
//  }
//
//  /// Delete the current user and logs them out.
//  Future<void> delete(String app) {
//    throw UnimplementedError('delete() is not implemented');
//  }
//
//  /// Returns a token used to identify the user to a Firebase service.
//  Future<PlatformIdTokenResult> getIdToken(String app, bool refresh) {
//    throw UnimplementedError('getIdToken() is not implemented');
//  }
//
//  /// Re-authenticates the current user with the given [credential].
//  Future<PlatformAuthResult> reauthenticateWithCredential(
//    String app,
//    AuthCredential credential,
//  ) {
//    throw UnimplementedError(
//        'reauthenticalWithCredential() is not implemented');
//  }
//
//  /// Links the current user with the given [credential].
//  Future<PlatformAuthResult> linkWithCredential(
//    String app,
//    AuthCredential credential,
//  ) {
//    throw UnimplementedError('linkWithCredential() is not implemented');
//  }
//
//  /// Unlinks the current user with the given [provider].
//  Future<void> unlinkFromProvider(String app, String provider) {
//    throw UnimplementedError('unlinkFromProvider() is not implemented');
//  }
//
//  /// Updates the current user's email to the given [email].
//  Future<void> updateEmail(String app, String email) {
//    throw UnimplementedError('updateEmail() is not implemented');
//  }
//
//  /// Update the current user's phone number with the given [phoneAuthCredential].
//  Future<void> updatePhoneNumberCredential(
//    String app,
//    PhoneAuthCredential phoneAuthCredential,
//  ) {
//    throw UnimplementedError(
//        'updatePhoneNumberCredential() is not implemented');
//  }
//
//  /// Update the current user's password to the given [password].
//  Future<void> updatePassword(String app, String password) {
//    throw UnimplementedError('updatePassword() is not implemented');
//  }
//
//  /// Update the current user's profile.
//  Future<void> updateProfile(
//    String app, {
//    String displayName,
//    String photoUrl,
//  }) {
//    throw UnimplementedError('updateProfile() is not implemented');
//  }
//
//  /// Sets the current language code.
//  Future<void> setLanguageCode(String app, String language) {
//    throw UnimplementedError('setLanguageCode() is not implemented');
//  }
//
//  /// Verify the current user's phone number.
//  Future<void> verifyPhoneNumber(
//    String app, {
//    @required String phoneNumber,
//    @required Duration timeout,
//    int forceResendingToken,
//    @required PhoneVerificationCompleted verificationCompleted,
//    @required PhoneVerificationFailed verificationFailed,
//    @required PhoneCodeSent codeSent,
//    @required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
//  }) {
//    throw UnimplementedError('verifyPhoneNumber() is not implemented');
//  }
}
