import 'package:firebase_auth_platform_interface/src/application_verifier/application_verifier.dart';
import 'package:firebase_core/firebase_core.dart';

/// A reCAPTCHA-based application verifier.
class RecaptchaVerifier implements ApplicationVerifier {
  RecaptchaVerifier(dynamic container, {Object parameters, FirebaseApp app})
      : this.type = "recaptcha";

  // TODO: Implementation
  /// Clears the reCAPTCHA widget from the page
  /// and destroys the current instance.
  void clear() {}

  /// Renders the reCAPTCHA widget on the page.
  /// Returns a [Future] that resolves with the
  /// ReCAPTCHA widget ID.
  Future<Object> render() {}

  @override
  String type;

  @override
  Future<String> verify() {
    // TODO: implement verify
  }
}
