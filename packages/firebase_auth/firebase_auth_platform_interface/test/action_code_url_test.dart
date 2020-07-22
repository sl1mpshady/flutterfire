// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/action_code_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final String kMockApiKey = 'test-key';
  final String kMockCode = 'test-code';
  final String kMockContinueURL = 'http://test.com';
  final String kMockLanguageCode = 'test-language-code';
  final String kMockOperation = 'test-operation';
  final String kMockTenantId = 'test-tenant-id';

  group('$ActionCodeURL', () {
    final actionCodeURL = ActionCodeURL(
        apiKey: kMockApiKey,
        code: kMockCode,
        operation: kMockOperation,
        tenantId: kMockTenantId,
        continueURL: kMockContinueURL,
        languageCode: kMockLanguageCode);
    group('Constructor', () {
      test('returns an instance of [ActionCodeInfo]', () {
        expect(actionCodeURL, isA<ActionCodeURL>());
        expect(actionCodeURL.apiKey, equals(kMockApiKey));
        expect(actionCodeURL.code, equals(kMockCode));
        expect(actionCodeURL.continueURL, equals(kMockContinueURL));
        expect(actionCodeURL.languageCode, equals(kMockLanguageCode));
        expect(actionCodeURL.operation, equals(kMockOperation));
        expect(actionCodeURL.tenantId, equals(kMockTenantId));
      });
    });

    // TODO (helenaford): test for parseLink when method has been updated
    // group('parseLink', () {
    //   test('returns the current instance as a [ActionCodeURL]', () {
    //     final String testLink = 'http://link.com';
    //     final result = ActionCodeURL.parseLink(testLink);

    //     expect(result, isA<ActionCodeURL>());
    //   });
    // });
  });
}
