import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

String TEST_PASSWORD = 'testpassword';

// Random timebased email to ensure unique test user account
// each time.
String generateRandomEmail({prefix = '', suffix = '@foo.bar'}) {
  var uuid = Uuid().v1();
  var testEmail = prefix + uuid + suffix;

  return testEmail;
}

// Gets a custom token from the rnfirebase api for test purposes.
Future getCustomToken(
    String uid, Map<String, dynamic> claims, String idToken) async {
  try {
    var path = "https://api.rnfirebase.io/auth/user/" + uid + "/custom-token";
    var body = json.encode(claims);
    var headers = {"authorization": "Bearer " + idToken};

    final response = await http.post(path, headers: headers, body: body);
    if (response.statusCode == 200) {
      // successful, parse json
      var jsonData = json.decode(response.body);
      return jsonData["token"];
    } else {
      // response wasn't successful, throw
      throw Exception("Unexpected response from server: (" +
          response.statusCode.toString() +
          ") " +
          response.reasonPhrase);
    }
  } catch (err) {
    throw Exception(err.toString());
  }
}
