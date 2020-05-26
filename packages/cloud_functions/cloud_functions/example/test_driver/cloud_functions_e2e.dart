import 'package:e2e/e2e.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  testWidgets('call', (WidgetTester tester) async {
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
