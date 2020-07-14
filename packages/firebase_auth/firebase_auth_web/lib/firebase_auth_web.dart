// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase/firebase.dart' as firebase;
// import 'package:firebase_auth_web/firebase_auth_web_confirmation_result.dart';
import 'package:firebase_auth_web/firebase_auth_web_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';

import 'firebase_auth_web_recaptcha_verifier_factory.dart';
import 'firebase_auth_web_user_credential.dart';
import 'utils.dart';

/// The web delegate implementation for [FirebaseAuth].
class FirebaseAuthWeb extends FirebaseAuthPlatform {
  /// instance of Auth from the web plugin
  final firebase.Auth _webAuth;

  /// Called by PluginRegistry to register this plugin for Flutter Web
  static void registerWith(Registrar registrar) {
    FirebaseAuthPlatform.instance = FirebaseAuthWeb.instance;
    RecaptchaVerifierFactoryPlatform.instance =
        RecaptchaVerifierFactoryWeb.instance;
  }

  static Map<String, StreamController<UserPlatform>>
      _authStateChangesListeners = <String, StreamController<UserPlatform>>{};

  static Map<String, StreamController<UserPlatform>> _idTokenChangesListeners =
      <String, StreamController<UserPlatform>>{};

  static Map<String, StreamController<UserPlatform>> _userChangesListeners =
      <String, StreamController<UserPlatform>>{};

  /// Initializes a stub instance to allow the class to be registered.
  static FirebaseAuthWeb get instance {
    return FirebaseAuthWeb._();
  }

  /// Stub initializer to allow the [registerWith] to create an instance without
  /// registering the web delegates or listeners.
  FirebaseAuthWeb._()
      : _webAuth = null,
        super(appInstance: null);

  /// The entry point for the [FirebaseAuthWeb] class.
  FirebaseAuthWeb({FirebaseApp app})
      : _webAuth = firebase.auth(firebase.app(app?.name)),
        super(appInstance: app) {
    if (app != null) {
      // Create a app instance broadcast stream for both delegate listener events
      _userChangesListeners[app.name] = _createBroadcastStream<UserPlatform>();
      _authStateChangesListeners[app.name] =
          _createBroadcastStream<UserPlatform>();
      _idTokenChangesListeners[app.name] =
          _createBroadcastStream<UserPlatform>();

      _webAuth.onAuthStateChanged.map((firebase.User webUser) {
        if (webUser == null) {
          _authStateChangesListeners[app.name].add(null);
        } else {
          _userChangesListeners[app.name].add(UserWeb(this, webUser));
        }
      });

      // Also triggers `userChanged` events
      _webAuth.onIdTokenChanged.map((firebase.User webUser) {
        if (webUser == null) {
          _idTokenChangesListeners[app.name].add(null);
          _userChangesListeners[app.name].add(null);
        } else {
          UserWeb user = UserWeb(this, webUser);
          _idTokenChangesListeners[app.name].add(user);
          _userChangesListeners[app.name].add(user);
        }
      });
    }
  }

  StreamController<T> _createBroadcastStream<T>() {
    return StreamController<T>.broadcast();
  }

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp app}) {
    return FirebaseAuthWeb(app: app);
  }

  @override
  FirebaseAuthWeb setInitialValues({
    Map<String, dynamic> currentUser,
    String languageCode,
  }) {
    return this;
  }

  @override
  UserPlatform get currentUser {
    firebase.User webCurrentUser = _webAuth.currentUser;

    if (webCurrentUser == null) {
      return null;
    }

    return UserWeb(this, _webAuth.currentUser);
  }

  @override
  void setCurrentUser(UserPlatform userPlatform) {
    _userChangesListeners[app.name].add(userPlatform);
  }

  @override
  Future<void> applyActionCode(String code) {
    return _webAuth.applyActionCode(code);
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    return convertWebActionCodeInfo(await _webAuth.checkActionCode(code));
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) async {
    return UserCredentialWeb(
        this, await _webAuth.createUserWithEmailAndPassword(email, password));
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) {
    return _webAuth.fetchSignInMethodsForEmail(email);
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() async {
    return UserCredentialWeb(this, await _webAuth.getRedirectResult());
  }

  @override
  Stream<UserPlatform> authStateChanges() =>
      _authStateChangesListeners[app.name].stream;

  @override
  Stream<UserPlatform> idTokenChanges() =>
      _idTokenChangesListeners[app.name].stream;

  @override
  Stream<UserPlatform> userChanges() => _userChangesListeners[app.name].stream;

  @override
  Future<void> sendPasswordResetEmail(String email,
      [ActionCodeSettings actionCodeSettings]) {
    return _webAuth.sendPasswordResetEmail(
        email, convertPlatformActionCodeSettings(actionCodeSettings));
  }

  @override
  Future<void> sendSignInWithEmailLink(String email,
      [ActionCodeSettings actionCodeSettings]) {
    return _webAuth.sendSignInLinkToEmail(
        email, convertPlatformActionCodeSettings(actionCodeSettings));
  }

  @override
  Future<void> setLanguageCode(String languageCode) async {
    _webAuth.languageCode = languageCode;
  }

  // TODO: not supported in firebase-dart
  // @override
  // Future<void> setSettings({bool appVerificationDisabledForTesting}) async {
  //   //
  // }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    return _webAuth.setPersistence(convertPlatformPersistence(persistence));
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    return UserCredentialWeb(this, await _webAuth.signInAnonymously());
  }

  Future<UserCredentialPlatform> signInWithCredential(
      AuthCredential credential) async {
    return UserCredentialWeb(
        this,
        await _webAuth
            .signInWithCredential(convertPlatformCredential(credential)));
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    return UserCredentialWeb(this, await _webAuth.signInWithCustomToken(token));
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) async {
    return UserCredentialWeb(
        this, await _webAuth.signInWithEmailAndPassword(email, password));
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
      String email, String emailLink) async {
    return UserCredentialWeb(
        this, await _webAuth.signInWithEmailLink(email, emailLink));
  }

  // TODO(ehesp): This is currently unimplemented due to an underlying firebase.ApplicationVerifier issue on the firebase-dart repository.
  // @override
  // Future<ConfirmationResultPlatform> signInWithPhoneNumber(String phoneNumber,
  //     RecaptchaVerifierFactoryPlatform applicationVerifier) async {
  //   return ConfirmationResultlWeb(
  //       this,
  //       await _webAuth.signInWithPhoneNumber(phoneNumber,
  //           applicationVerifier.getDelegate<firebase.ApplicationVerifier>()));
  // }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) async {
    return UserCredentialWeb(this,
        await _webAuth.signInWithPopup(convertPlatformAuthProvider(provider)));
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    return _webAuth.signInWithRedirect(convertPlatformAuthProvider(provider));
  }

  @override
  Future<void> signOut() {
    return _webAuth.signOut();
  }

  @override
  Future<String> verifyPasswordResetCode(String code) {
    return _webAuth.verifyPasswordResetCode(code);
  }

  @override
  Future<void> verifyPhoneNumber(
      {@required String phoneNumber,
      @required PhoneVerificationCompleted verificationCompleted,
      @required PhoneVerificationFailed verificationFailed,
      @required PhoneCodeSent codeSent,
      @required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
      String autoRetrievedSmsCodeForTesting,
      Duration timeout = const Duration(seconds: 30),
      int forceResendingToken}) {
    throw UnimplementedError(
        'verifyPhoneNumber() is not supported on the web. Please use `signInWithPhoneNumber` instead.');
  }
}
