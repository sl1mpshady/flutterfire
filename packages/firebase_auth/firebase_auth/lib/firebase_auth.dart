// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_auth;

import 'dart:async';

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';

export 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show
        IdTokenResult,
        UserMetadata,
        UserInfo,
        ActionCodeInfo,
        ActionCodeSettings,
        AdditionalUserInfo,
        ActionCodeInfoOperation,
        MultiFactorInfo,
        Persistence,
        AuthCredential,
        EmailAuthProvider,
        EmailAuthCredential,
        FacebookAuthProvider,
        FacebookAuthCredential,
        GithubAuthProvider,
        GithubAuthCredential,
        GoogleAuthProvider,
        GoogleAuthCredential,
        OAuthProvider,
        OAuthCredential,
        SAMLAuthProvider,
        TwitterAuthProvider,
        TwitterAuthCredential;

export 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    show FirebaseException;

part 'src/firebase_auth.dart';
part 'src/user_credential.dart';
part 'src/user.dart';
