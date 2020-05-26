import 'dart:async';

import 'package:e2e/e2e.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions_example/main.dart';
import 'dart:async';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
// void main() {
//   E2EWidgetsFlutterBinding.ensureInitialized();

//   group('$CloudFunctions', () {
//     final CloudFunctions cloudFunctions = CloudFunctions.instance;

//     testWidgets('runTransaction', (WidgetTester tester) async {});
//   });
// }
// Future<void> main() async {
//   E2EWidgetsFlutterBinding.ensureInitialized();
//   await FirebaseCore.instance.initializeApp();
//   // final Completer<String> completer = Completer<String>();
//   // enableFlutterDriverExtension(handler: (_) => completer.future);
//   // tearDownAll(() => completer.complete(null));
// }

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  // testWidgets('CloudFunctions example widget test',
  //     (WidgetTester tester) async {
  //   await tester.pumpWidget(MyApp());
  //   expect(find.text('Cloud Functions example app'), findsOneWidget);
  // });

  testWidgets('call', (WidgetTester tester) async {
    await FirebaseCore.instance.initializeApp();
    //   Firestore firestore = Firestore();
    //   expect(firestore, isNotNull);
    // });

    // test('call', () async {
    await FirebaseCore.instance.initializeApp();
    final HttpsCallable callable =
        CloudFunctions.instance.getHttpsCallable(functionName: 'repeat');
    final HttpsCallableResult response = await callable.call(<String, dynamic>{
      'message': 'foo',
      'count': 1,
    });
    expect(response.data['repeat_message'], 'foo');
  });
}
