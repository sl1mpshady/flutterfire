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
    await FirebaseCore.instance.initializeApp();
    FirebaseApp secondaryApp = await FirebaseCore.instance.initializeApp(
        name: 'foo',
        options: FirebaseOptions(
          apiKey: '123',
          appId: '123',
          messagingSenderId: '123',
          projectId: '123',
        ));

    firestore = Firestore.instance;
    firestoreSecondary = Firestore.instanceFor(app: secondaryApp);
  });

  group("$WriteBatch", () {
    group('validate', () {
      test('may contain indirectly nested arrays', () {
        const data = {
          'nested-array': [
            1,
            {
              'foo': [2]
            }
          ]
        };
        DocumentReference ref = firestore.collection('foo').document();

        ref
            .setData(data)
            .then((value) => ref.firestore.batch().setData(ref, data))
            .then((value) => ref.updateData(data))
            .then((value) => ref.firestore.batch().updateData(ref, data))
            .then((value) => ref.firestore.runTransaction(
                (transaction) async => transaction.update(ref, data)));
      });

      test('requires correct document references', () {
        DocumentReference badRef = firestoreSecondary.document('foo/bar');
        const data = {'foo': 1};
        var batch = firestore.batch();
        expect(() => batch.setData(badRef, data), throwsAssertionError);
        expect(() => batch.updateData(badRef, data), throwsAssertionError);
        expect(() => batch.delete(badRef), throwsAssertionError);
      });
    });
  });
}
