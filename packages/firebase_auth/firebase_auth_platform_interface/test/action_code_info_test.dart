// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final int kMockOperation = 1;
  final String kMockEmail = 'test@test.com';
  final String kMockPreviousEmail = 'previous@test.com';
  final Map<String, dynamic> kMockData = <String, dynamic>{
    'email': kMockEmail,
    'previousEmail': kMockPreviousEmail
  };

  group('$ActionCodeInfo', () {
    ActionCodeInfo actionCodeInfo =
        ActionCodeInfo(operation: kMockOperation, data: kMockData);
    group('Constructor', () {
      test('returns an instance of [ActionCodeInfo]', () {
        expect(actionCodeInfo, isA<ActionCodeInfo>());
      });
      test('throws [AssertionError] when data is null', () {
        expect(() => ActionCodeInfo(operation: kMockOperation, data: null),
            throwsAssertionError);
      });
    });

    group('data', () {
      test('returns expected data', () {
        expect(actionCodeInfo.data, isA<Map<String, dynamic>>());
        expect(actionCodeInfo.data['email'], equals(kMockEmail));
        expect(
            actionCodeInfo.data['previousEmail'], equals(kMockPreviousEmail));
      });

      test('handles email is null', () {
        ActionCodeInfo testActionCodeInfo = ActionCodeInfo(
            operation: kMockOperation,
            data: <String, dynamic>{
              'email': null,
              'previousEmail': kMockPreviousEmail
            });
        expect(testActionCodeInfo.data, isA<Map<String, dynamic>>());
        expect(testActionCodeInfo.data['email'], isNull);
        expect(testActionCodeInfo.data['previousEmail'],
            equals(kMockPreviousEmail));
      });

      test('handles previousEmail is null', () {
        ActionCodeInfo testActionCodeInfo = ActionCodeInfo(
            operation: kMockOperation,
            data: <String, dynamic>{
              'email': kMockEmail,
              'previousEmail': null
            });
        expect(testActionCodeInfo.data, isA<Map<String, dynamic>>());
        expect(testActionCodeInfo.data['email'], equals(kMockEmail));
        expect(testActionCodeInfo.data['previousEmail'], isNull);
      });
    });

    group('operation', () {
      test('returns an instance of [ActionCodeInfoOperation]', () {
        expect(actionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(actionCodeInfo.operation,
            equals(ActionCodeInfoOperation.verifyEmail));
      });

      test('returns opertaion type `emailSignIn`', () {
        ActionCodeInfo testActionCodeInfo =
            ActionCodeInfo(operation: 4, data: kMockData);

        expect(testActionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(testActionCodeInfo.operation,
            equals(ActionCodeInfoOperation.emailSignIn));
      });

      test('returns opertaion type `passwordReset`', () {
        ActionCodeInfo testActionCodeInfo =
            ActionCodeInfo(operation: 0, data: kMockData);

        expect(testActionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(testActionCodeInfo.operation,
            equals(ActionCodeInfoOperation.passwordReset));
      });

      test('returns opertaion type `recoverEmail`', () {
        ActionCodeInfo testActionCodeInfo =
            ActionCodeInfo(operation: 2, data: kMockData);

        expect(testActionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(testActionCodeInfo.operation,
            equals(ActionCodeInfoOperation.recoverEmail));
      });

      test('returns opertaion type `verifyAndChangeEmail`', () {
        ActionCodeInfo testActionCodeInfo =
            ActionCodeInfo(operation: 5, data: kMockData);

        expect(testActionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(testActionCodeInfo.operation,
            equals(ActionCodeInfoOperation.verifyAndChangeEmail));
      });

      test('returns opertaion type `verifyEmail`', () {
        ActionCodeInfo testActionCodeInfo =
            ActionCodeInfo(operation: 1, data: kMockData);

        expect(testActionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(testActionCodeInfo.operation,
            equals(ActionCodeInfoOperation.verifyEmail));
      });

      test(
          'throws a [FallThroughError] when operation does not match a known type',
          () {
        expect(actionCodeInfo.operation, isA<ActionCodeInfoOperation>());
        expect(
            () => actionCodeInfo.operation, throwsA(isA<FallThroughError>()));
      });
    });
  });
}
