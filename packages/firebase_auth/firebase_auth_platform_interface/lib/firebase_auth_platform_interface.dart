// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_auth_platform_interface;

export 'src/platform_interface/platform_interface_firebase_auth.dart';
export 'src/platform_interface/platform_interface_user.dart';
export 'src/platform_interface/platform_interface_user_credential.dart';

export 'src/auth_credential.dart';
export 'src/action_code_info.dart';
export 'src/action_code_settings.dart';
export 'src/user_metadata.dart';
export 'src/id_token_result.dart';
export 'src/user_info.dart';
export 'src/additional_user_info.dart';
export 'src/multi_factor/multi_factor_info.dart';
export 'src/types.dart';

export 'src/auth_provider/email_auth.dart';
export 'src/auth_provider/facebook_auth.dart';
export 'src/auth_provider/github_auth.dart';
export 'src/auth_provider/google_auth.dart';
export 'src/auth_provider/oauth.dart';
// todo import phone/saml
export 'src/auth_provider/twitter_auth.dart';
