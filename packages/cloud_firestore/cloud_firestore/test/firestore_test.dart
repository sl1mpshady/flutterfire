import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;
  Firestore firestoreSecondary;

  setUpAll(() async {
    await Firebase.initializeApp();

    FirebaseApp secondaryApp = await Firebase.initializeApp(
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

  expectWriteToFail(data, [includeSets = true, includeUpdates = true]) {
    DocumentReference ref = firestore.document('foo/bar');

    if (includeSets) {
      expect(() => ref.setData(data), throwsAssertionError);
      expect(
          () => ref.firestore.batch().setData(ref, data), throwsAssertionError);
    }

    if (includeUpdates) {
      expect(() => ref.updateData(data), throwsAssertionError);
      expect(() => ref.firestore.batch().updateData(ref, data),
          throwsAssertionError);
    }

    return ref.firestore.runTransaction((transaction) async {
      if (includeSets) {
        expect(() => transaction.set(ref, data), throwsAssertionError);
      }

      if (includeUpdates) {
        expect(() => transaction.update(ref, data), throwsAssertionError);
      }
    });
  }

  expectUpdateToFail(data) {
    return expectWriteToFail(data, false, true);
  }

  expectSetToFail(data) {
    return expectWriteToFail(data, true, false);
  }

  expectFieldPathToFail(snapshot, path) {
    // Snapshot paths.
    expect(() => snapshot.get(path), throwsAssertionError);

    // Query filter / order fields.
    CollectionReference ref = firestore.collection('test-collection');
    expect(() => ref.where(path, isEqualTo: 1), throwsAssertionError);
    expect(() => ref.orderBy(path), throwsAssertionError);

    // Update paths.
    const data = {};
    data[path] = 1;
    expectUpdateToFail(data);
  }

  group("$Firestore", () {
    group('validate', () {
      test('throws for invalid transaction functions', () {
        expect(() => firestore.runTransaction(null), throwsAssertionError);
      });

      test('must be objects', () {
        expectWriteToFail(1);
        expectWriteToFail([2]);
        expectWriteToFail(null);
      });

      test('must not contain custom objects', () {
        expectWriteToFail({'foo': () => {}});
        expectWriteToFail({
          'foo': {'bar': () => {}}
        });
      });

      test('must not contain directly nested arrays', () {
        expectWriteToFail({
          'nested-array': [
            1,
            [2]
          ]
        });
      });

      test('must not contain references to a different store', () {
        var ref = firestoreSecondary.document('baz/quu');
        var data = {'foo': ref};
        expectWriteToFail(data);
      });

      test('document fields cannot begin and end with "__"', () {
        expectWriteToFail({'__baz__': 1});
        expectWriteToFail({
          'foo': {'__baz__': 1}
        });
        expectWriteToFail({
          '__baz__': {'foo': 1}
        });
        expectUpdateToFail({'foo.__baz__': 1});
        expectUpdateToFail({'__baz__.foo': 1});
      });

      test('document fields must not be empty', () {
        expectSetToFail({'': 'foo'});
      });

      test('.set() must not contain FieldValue.delete()', () {
        expectSetToFail({'foo': FieldValue.delete()});
      });

      test('.update() must not contain nested FieldValue.delete()', () {
        expectUpdateToFail({
          'foo': {'bar': FieldValue.delete()}
        });
      });

      test('field paths must not have empty segments', () {
        DocumentReference ref = firestore.collection('test').document();
        ref.setData({'test': 1}).then((value) => ref.get()).then((snapshot) {
              expectFieldPathToFail(snapshot, '');
              expectFieldPathToFail(snapshot, 'foo..baz');
              expectFieldPathToFail(snapshot, '.foo');
              expectFieldPathToFail(snapshot, 'foo.');
            });
      });

      test('field paths must not have invalid segments', () {
        DocumentReference ref = firestore.collection('test').document();
        ref.setData({'test': 1}).then((value) => ref.get()).then((snapshot) {
              expectFieldPathToFail(snapshot, 'foo~bar');
              expectFieldPathToFail(snapshot, 'foo*bar');
              expectFieldPathToFail(snapshot, 'foo/bar');
              expectFieldPathToFail(snapshot, 'foo[1');
              expectFieldPathToFail(snapshot, 'foo]1');
              expectFieldPathToFail(snapshot, 'foo[1]');
            });
      });
    });
  });
}
