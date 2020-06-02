import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;
  Firestore firestoreSecondary;

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseApp secondayApp = await Firebase.initializeApp(
        name: 'foo',
        options: FirebaseOptions(
          apiKey: '123',
          appId: '123',
          messagingSenderId: '123',
          projectId: '123',
        ));

    firestore = Firestore.instance;
    firestoreSecondary = Firestore.instanceFor(app: secondayApp);
  });

  group("$Transaction", () {
    test('requires correct document references', () async {
      DocumentReference ref = firestoreSecondary.document('foo/bar');
      const data = {'foo': 1};

      firestore.runTransaction((transaction) async {
        expect(() => transaction.get(ref), throwsAssertionError);
        expect(() => transaction.set(ref, data), throwsAssertionError);
        expect(() => transaction.update(ref, data), throwsAssertionError);
        expect(() => transaction.delete(ref), throwsAssertionError);
      });
    });
  });
}
