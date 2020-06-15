import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;

  setUpAll(() async {
<<<<<<< HEAD
    await Firebase.initializeApp();
    FirebaseApp secondayApp = await Firebase.initializeApp(
        name: 'foo',
        options: FirebaseOptions(
          apiKey: '123',
          appId: '123',
          messagingSenderId: '123',
          projectId: '123',
        ));

=======
    await FirebaseCore.instance.initializeApp();
>>>>>>> 3703e843... Cleanup.
    firestore = Firestore.instance;
  });

  group("$Transaction", () {
    test('throws if invalid transactionHandler passed', () async {
      expect(() => firestore.runTransaction(null), throwsAssertionError);
    });
  });
}
