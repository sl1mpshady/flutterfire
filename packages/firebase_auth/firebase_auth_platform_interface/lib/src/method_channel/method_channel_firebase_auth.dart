// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/firebase_auth_exception.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user.dart';
import 'package:firebase_auth_platform_interface/src/platform_interface/platform_interface_user_credential.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_user_credential.dart';
import 'utils/exception.dart';
import 'utils/phone_auth_callbacks.dart';

class MethodChannelFirebaseAuth extends FirebaseAuthPlatform {
  /// Keeps an internal handle ID for the channel.
  static int _methodChannelHandleId = 0;

  /// Increments and returns the next channel ID handler for Auth.
  static int get nextMethodChannelHandleId => _methodChannelHandleId++;

  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_auth',
  );

  /// A map containing all the pending user state change listeners, keyed by their id.
  static final Map<int, StreamController<UserPlatform>> userObservers =
      <int, StreamController<UserPlatform>>{};

  static Map<String, StreamController<UserPlatform>>
      _authStateChangesListeners = {};

  static Map<String, StreamController<UserPlatform>> _idTokenChangesListeners =
      {};

  static Map<int, PhoneAuthCallbacks> _phoneAuthCallbacks = {};

  StreamController<T> createBroadcastStream<T>() {
    return StreamController<T>.broadcast();
  }

  MethodChannelFirebaseAuth({FirebaseApp app}) : super(appInstance: app) {
    _authStateChangesListeners[app.name] =
        createBroadcastStream<UserPlatform>();
    _idTokenChangesListeners[app.name] = createBroadcastStream<UserPlatform>();

    channel.setMethodCallHandler((MethodCall call) async {
      Map<dynamic, dynamic> arguments = call.arguments();

      switch (call.method) {
        case 'Auth#authStateChanges':
          return _handleChangeListener(
              _authStateChangesListeners[arguments['appName']], arguments);
        case 'Auth#idTokenChanges':
          return _handleChangeListener(
              _idTokenChangesListeners[arguments['appName']], arguments);
        case 'Auth#phoneVerificationCompleted':
          return _handlePhoneVerificationCompleted(arguments);
        case 'Auth#phoneVerificationFailed':
          return _handlePhoneVerificationFailed(arguments);
        case 'Auth#phoneCodeSent':
          return _handlePhoneCodeSent(arguments);
        case 'Auth#phoneCodeAutoRetrievalTimeout':
          return _handlePhoneCodeAutoRetrievalTimeout(arguments);
        default:
          throw UnimplementedError("${call.method} has not been implemented");
      }
    });

    // Send a request to start listening to change listeners straight away
    channel
        .invokeMethod<void>('Auth#registerChangeListeners', <String, dynamic>{
      'appName': app.name,
    });
  }

  UserPlatform currentUser;

  String languageCode;

  /// Handles an incoming change listener (authStateChanges or idTokenChanges) and
  /// fans out the result to any subscribers.
  Future<void> _handleChangeListener(
      StreamController<UserPlatform> streamController,
      Map<dynamic, dynamic> arguments) async {
    final Map<String, dynamic> user =
        Map<String, dynamic>.from(arguments['user']);

    if (user == null) {
      streamController.add(null);
    } else {
      streamController.add(MethodChannelUser(this, user));
    }
  }

  Future<void> _handlePhoneVerificationCompleted(
      Map<dynamic, dynamic> arguments) async {
    final int handle = arguments['handle'];

    PhoneAuthCredential phoneAuthCredential =
        PhoneAuthProvider.credentialFromHandle(handle);
    PhoneAuthCallbacks callbacks = _phoneAuthCallbacks[handle];
    callbacks.verificationCompleted(phoneAuthCredential);
  }

  Future<void> _handlePhoneVerificationFailed(
      Map<dynamic, dynamic> arguments) async {
    final int handle = arguments['handle'];
    final Map<dynamic, dynamic> error = arguments['error'];
    final Map<dynamic, dynamic> details = error['details'];

    PhoneAuthCallbacks callbacks = _phoneAuthCallbacks[handle];

    FirebaseAuthException exception = FirebaseAuthException(
      message: details != null ? details['message'] : error['message'],
      code: details != null ? details['code'] : 'unknown',
    );

    callbacks.verificationFailed(exception);
  }

  Future<void> _handlePhoneCodeSent(Map<dynamic, dynamic> arguments) async {
    final int handle = arguments['handle'];
    final String verificationId = arguments['verificationId'];
    final int forceResendingToken = arguments['forceResendingToken'];

    PhoneAuthCallbacks callbacks = _phoneAuthCallbacks[handle];
    callbacks.codeSent(verificationId, forceResendingToken);
  }

  Future<void> _handlePhoneCodeAutoRetrievalTimeout(
      Map<dynamic, dynamic> arguments) async {
    final int handle = arguments['handle'];
    final String verificationId = arguments['verificationId'];

    PhoneAuthCallbacks callbacks = _phoneAuthCallbacks[handle];
    callbacks.codeAutoRetrievalTimeout(verificationId);
  }

  /// Gets a [FirebaseAuthPlatform] with specific arguments such as a different
  /// [FirebaseApp].
  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp app}) {
    return MethodChannelFirebaseAuth(app: app);
  }

  @override
  MethodChannelFirebaseAuth setInitialValues({
    Map<String, dynamic> currentUser,
    String languageCode,
  }) {
    if (currentUser != null) {
      this.currentUser = MethodChannelUser(this, currentUser);
    }

    this.languageCode = languageCode;
    return this;
  }

  @override
  Future<void> applyActionCode(String code) async {
    await channel.invokeMethod<void>('Auth#applyActionCode', <String, dynamic>{
      'appName': app.name,
      'code': code,
    }).catchError(catchPlatformException);
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    Map<String, dynamic> result = await channel
        .invokeMapMethod<String, dynamic>(
            'Auth#checkActionCode', <String, dynamic>{
      'appName': app.name,
      'code': code,
    });

    return ActionCodeInfo(
      operation: result['operation'],
      data: result['data'],
    );
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await channel
        .invokeMethod<void>('Auth#confirmPasswordReset', <String, dynamic>{
      'appName': app.name,
      'code': code,
      'newPassword': newPassword,
    });
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#createUserWithEmailAndPassword', <String, dynamic>{
      'appName': app.name,
      'email': email,
      'password': password,
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return channel.invokeListMethod<String>(
        'Auth#fetchSignInMethodsForEmail', <String, dynamic>{
      'appName': app.name,
      'email': email,
    });
  }

  @override
  Stream<UserPlatform> authStateChanges() =>
      _authStateChangesListeners[app.name].stream;

  @override
  Stream<UserPlatform> idTokenChanges() =>
      _idTokenChangesListeners[app.name].stream;

  @override
  Future<void> sendPasswordResetEmail(String email,
      [ActionCodeSettings actionCodeSettings]) {
    return channel
        .invokeMethod<void>('Auth#sendPasswordResetEmail', <String, dynamic>{
      'appName': app.name,
      'actionCodeSettings': actionCodeSettings?.asMap(),
    });
  }

  @override
  Future<void> sendSignInWithEmailLink(
      String email, ActionCodeSettings actionCodeSettings) {
    return channel
        .invokeMethod<void>('Auth#sendPasswordResetEmail', <String, dynamic>{
      'appName': app.name,
      'email': email,
      'actionCodeSettings': actionCodeSettings.asMap(),
    });
  }

  @override
  Future<void> setLanguageCode(String languageCode) async {
    this.languageCode = await channel
        .invokeMethod<String>('Auth#setLanguageCode', <String, dynamic>{
      'appName': app.name,
      'languageCode': languageCode,
    });
  }

  @override
  Future<void> setPersistence(Persistence persistence) {
    throw UnimplementedError(
        'setPersistence() is only supported on web based platforms');
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#signInAnonymously', <String, dynamic>{
      'appName': app.name,
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
      AuthCredential credential) async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#signInWithCredential', <String, dynamic>{
      'appName': app.name,
      'credential': credential.asMap(),
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#signInWithCustomToken', <String, dynamic>{
      'appName': app.name,
      'token': token,
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#signInWithEmailAndPassword', <String, dynamic>{
      'appName': app.name,
      'email': email,
      'password': password,
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndLink(
      String email, String emailLink) async {
    Map<String, dynamic> data = await channel.invokeMapMethod<String, dynamic>(
        'Auth#signInWithEmailAndLink', <String, dynamic>{
      'appName': app.name,
      'email': email,
      'emailLink': emailLink,
    });

    return MethodChannelUserCredential(this, data);
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) {
    throw UnimplementedError(
        'signInWithPopup() is only supported on web based platforms');
  }

  @override
  Future<UserCredentialPlatform> signInWithRedirect(AuthProvider provider) {
    throw UnimplementedError(
        'signInWithRedirect() is only supported on web based platforms');
  }

  Future<void> signOut() async {
    await channel
        .invokeMapMethod<String, dynamic>('Auth#signOut', <String, dynamic>{
      'appName': app.name,
    });
  }

  Future<String> verifyPasswordResetCode(String code) {
    return channel
        .invokeMethod<String>('Auth#verifyPasswordResetCode', <String, dynamic>{
      'appName': app.name,
      'code': code,
    });
  }

  Future<void> verifyPhoneNumber({
    String phoneNumber,
    Duration timeout = const Duration(seconds: 30),
    int forceResendingToken,
    PhoneVerificationCompleted verificationCompleted,
    PhoneVerificationFailed verificationFailed,
    PhoneCodeSent codeSent,
    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) {
    int handle = MethodChannelFirebaseAuth.nextMethodChannelHandleId;

    _phoneAuthCallbacks[handle] = PhoneAuthCallbacks(verificationCompleted,
        verificationFailed, codeSent, codeAutoRetrievalTimeout);

    return channel
        .invokeMethod<String>('Auth#verifyPhoneNumber', <String, dynamic>{
      'appName': app.name,
      'handle': handle,
      'phoneNumber': phoneNumber,
      'timeout': timeout.inMilliseconds,
      'forceResendingToken': forceResendingToken,
    });
  }
}
