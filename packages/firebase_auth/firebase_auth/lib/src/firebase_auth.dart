// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// The entry point of the Firebase Authentication SDK.
class FirebaseAuth extends FirebasePluginPlatform {
  // Cached and lazily loaded instance of [FirebaseAuthPlatform] to avoid
  // creating a [MethodChannelFirebaseAuth] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirebaseAuthPlatform _delegatePackingProperty;

  FirebaseAuthPlatform get _delegate {
    print('pluginConstants $pluginConstants');
    if (_delegatePackingProperty == null) {
      _delegatePackingProperty = FirebaseAuthPlatform.instanceFor(
          app: app, pluginConstants: pluginConstants);
    }
    return _delegatePackingProperty;
  }

  /// The [FirebaseApp] for this current Auth instance.
  FirebaseApp app;

  FirebaseAuth._({this.app})
      : super(app.name, 'plugins.flutter.io/firebase_auth');

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseAuth get instance {
    return FirebaseAuth._(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseAuth instanceFor({FirebaseApp app}) {
    assert(app != null);
    return FirebaseAuth._(app: app);
  }

  @Deprecated('Deprecated in favor of `FirebaseAuth.instanceFor`')
  factory FirebaseAuth.fromApp(FirebaseApp app) {
    return FirebaseAuth.instanceFor(app: app);
  }

  @Deprecated('Deprecated in favor of `authStateChanges`')
  Stream<User> get onAuthStateChanged {
    return authStateChanges();
  }

  /// Returns the current [User] if they are currently signed-in, or `null` if not.
  ///
  /// You should not use this getter to determine the users current state, instead
  /// use [authStateChanges] to subscribe to updates.
  User get currentUser {
    if (_delegate.currentUser != null) {
      return User._(this, _delegate.currentUser);
    }

    return null;
  }

  /// Applies a verification code sent to the user by email or other out-of-band mechanism.
  Future<void> applyActionCode(String code) async {
    assert(code != null);
    await _delegate.applyActionCode(code);
  }

  /// Checks a verification code sent to the user by email or other out-of-band mechanism.
  ///
  /// Returns metadata about the code.
  Future<ActionCodeInfo> checkActionCode(String code) {
    assert(code != null);
    return _delegate.checkActionCode(code);
  }

  /// Completes the password reset process, given a confirmation code and new password.
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    assert(code != null);
    assert(newPassword != null);
    await _delegate.confirmPasswordReset(code, newPassword);
  }

  /// Tries to create a new user account with the given email address and password.
  Future<UserCredential> createUserWithEmailAndPassword({
    @required String email,
    @required String password,
  }) async {
    assert(email != null);
    assert(password != null);
    return UserCredential._(
        this, await _delegate.createUserWithEmailAndPassword(email, password));
  }

  /// Returns a list of sign-in methods that can be used to sign in a given
  /// user (identified by its main email address).
  ///
  /// This method is useful when you support multiple authentication mechanisms
  /// if you want to implement an email-first authentication flow.
  ///
  /// An empty `List` is returned if the user could not be found.
  Future<List<String>> fetchSignInMethodsForEmail({
    @required String email,
  }) {
    assert(email != null);
    return _delegate.fetchSignInMethodsForEmail(email);
  }

  /// Returns a UserCredential from the redirect-based sign-in flow.
  ///
  /// If sign-in succeeded, returns the signed in user. If sign-in was unsuccessful,
  ///  fails with an error. If no redirect operation was called, returns a [UserCredential] with a null User.
  ///
  /// This method is only support on web platforms.
  Future<UserCredential> getRedirectResult() async {
    return UserCredential._(this, await _delegate.getRedirectResult());
  }

  /// Checks if an incoming link is a sign-in with email link.
  bool isSignInWithEmailLink(String emailLink) {
    assert(emailLink != null);
    return _delegate.isSignInWithEmailLink(emailLink);
  }

  /// Notifies about changes to the user's sign-in state (such as sign-in or sign-out).
  Stream<User> authStateChanges() {
    Stream<User> stream = _delegate.authStateChanges().map((delegateUser) {
      if (delegateUser == null) {
        return null;
      }

      return User._(this, delegateUser);
    });

    StreamController<User> streamController;
    streamController = StreamController<User>.broadcast(onListen: () {
      // Fire an event straight away
      streamController.add(currentUser);
      // Pipe events of the broadcast stream into this stream
      stream.pipe(streamController);
    });

    return streamController.stream;
  }

  /// Notifies about changes to the user's sign-in state (such as sign-in or sign-out)
  /// and also token refresh events.
  Stream<User> idTokenChanges() {
    Stream<User> stream = _delegate.idTokenChanges().map((delegateUser) {
      if (delegateUser == null) {
        return null;
      }

      return User._(this, delegateUser);
    });

    StreamController<User> streamController;
    streamController = StreamController<User>.broadcast(onListen: () {
      // Fire an event straight away
      streamController.add(currentUser);
      // Pipe events of the broadcast stream into this stream
      stream.pipe(streamController);
    });

    return streamController.stream;
  }

  /// Triggers the Firebase Authentication backend to send a password-reset
  /// email to the given email address, which must correspond to an existing
  /// user of your app.
  Future<void> sendPasswordResetEmail({
    @required String email,
    ActionCodeSettings actionCodeSettings,
  }) {
    assert(email != null);
    return _delegate.sendPasswordResetEmail(email, actionCodeSettings);
  }

  /// Sends a sign in with email link to provided email address.
  Future<void> sendSignInWithEmailLink({
    @required String email,
    @required ActionCodeSettings actionCodeSettings,
  }) async {
    assert(email != null);
    assert(actionCodeSettings != null);
    await _delegate.sendSignInWithEmailLink(email, actionCodeSettings);
  }

  /// When set to null, the default Firebase Console language setting is applied.
  ///
  /// The language code will propagate to email action templates (password reset,
  /// email verification and email change revocation), SMS templates for phone
  /// authentication, reCAPTCHA verifier and OAuth popup/redirect operations
  /// provided the specified providers support localization with the language
  /// code specified.
  ///
  /// On web platforms, if `null` is provided as the [languageCode] the Firebase
  /// project default language will be used. On native platforms, the app language will be used.
  Future<void> setLanguageCode(String languageCode) {
    return _delegate.setLanguageCode(languageCode);
  }

  /// Changes the current type of persistence on the current Auth instance for
  /// the currently saved Auth session and applies this type of persistence for
  /// future sign-in requests, including sign-in with redirect requests. This
  /// will return a promise that will resolve once the state finishes copying
  /// from one type of storage to the other. Calling a sign-in method after
  /// changing persistence will wait for that persistence change to complete
  /// before applying it on the new Auth state.
  ///
  /// This makes it easy for a user signing in to specify whether their session
  /// should be remembered or not. It also makes it easier to never persist the
  /// Auth state for applications that are shared by other users or have sensitive data.
  ///
  /// This is only supported on web based platforms.
  Future<void> setPersistence(Persistence persistence) async {
    assert(persistence != null);
    return _delegate.setPersistence(persistence);
  }

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  Future<UserCredential> signInAnonymously() async {
    return UserCredential._(this, await _delegate.signInAnonymously());
  }

  /// Asynchronously signs in to Firebase with the given 3rd-party credentials
  /// (e.g. a Facebook login Access Token, a Google ID Token/Access Token pair,
  /// etc.) and returns additional identity provider data.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// If the user doesn't have an account already, one will be created automatically.
  ///
  /// **Important**: You must enable the relevant accounts in the Auth section
  /// of the Firebase console before being able to use them.
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    assert(credential != null);
    return UserCredential._(
        this, await _delegate.signInWithCredential(credential));
  }

  /// Tries to sign in a user with a given Custom Token [token].
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Use this method after you retrieve a Firebase Auth Custom Token from your server.
  ///
  /// If the user identified by the [uid] specified in the token doesn't
  /// have an account already, one will be created automatically.
  ///
  /// Read how to use Custom Token authentication and the cases where it is
  /// useful in [the guides](https://firebase.google.com/docs/auth/android/custom-auth).
  Future<UserCredential> signInWithCustomToken(String token) async {
    assert(token != null);
    return UserCredential._(this, await _delegate.signInWithCustomToken(token));
  }

  /// Tries to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [authStateChanges] stream.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  Future<UserCredential> signInWithEmailAndPassword({
    @required String email,
    @required String password,
  }) {
    assert(email != null);
    assert(password != null);

    // TODO
    // return signInWithCredential(EmailAuthProvider.getCredential(
    //   email: email,
    //   password: password,
    // ));
  }

  /// Signs in using an email address and email sign-in link.
  Future<UserCredential> signInWithEmailAndLink(
      {@required String email, @required String emailLink}) async {
    assert(email != null);
    assert(emailLink != null);

    return UserCredential._(
        this, await _delegate.signInWithEmailAndLink(email, emailLink));
  }

  Future<UserCredential> signInWithPopup() {
    // TODO
  }

  Future<UserCredential> signInWithRedirect() {
    // TODO
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _delegate.signOut();
  }

  /// Checks a password reset code sent to the user by email or other out-of-band mechanism.
  ///
  /// Returns the user's email address if valid.
  Future<String> verifyPasswordResetCode(String code) {
    assert(code != null);
    return _delegate.verifyPasswordResetCode(code);
  }
}
