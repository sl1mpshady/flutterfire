// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

void runInstanceTests() {
  group('$FirebaseAuth.instance', () {
    FirebaseAuth auth;

    setUpAll(() async {
      auth = FirebaseAuth.instance;
    });

    group('applyActionCode', () {
      test('throws if invalid code', () async {
        try {
          await auth.applyActionCode('!!!!!!');
          fail("Should have thrown");
        } on FirebaseException catch (e) {
          expect(e.code, equals("invalid-action-code"));
        } catch (e) {
          fail(e.toString());
        }
      });
    });
  });
}
