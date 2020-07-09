package io.flutter.plugins.firebaseauth;

import androidx.annotation.NonNull;

import com.google.firebase.FirebaseNetworkException;
import com.google.firebase.FirebaseTooManyRequestsException;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseAuthUserCollisionException;
import com.google.firebase.auth.FirebaseAuthWeakPasswordException;

import java.util.HashMap;
import java.util.Map;

import static io.flutter.plugins.firebaseauth.FirebaseAuthPlugin.parseAuthCredential;

public class FirebaseAuthPluginException extends Exception {

  private final String code;
  private final String message;
  private Map<String, Object> additionalData = new HashMap<>();

  FirebaseAuthPluginException(@NonNull String code, @NonNull String message) {
    super(message, null);

    this.code = code;
    this.message = message;
  }

  FirebaseAuthPluginException(@NonNull Exception nativeException, Throwable cause) {
    super(nativeException.getMessage(), cause);

    String code = "UNKNOWN";
    String message = nativeException.getMessage();
    Map<String, Object> additionalData = new HashMap<>();

    if (nativeException instanceof FirebaseAuthException) {
      code = ((FirebaseAuthException) nativeException).getErrorCode();
    }

    if (nativeException instanceof FirebaseAuthWeakPasswordException) {
      message = ((FirebaseAuthWeakPasswordException) nativeException).getReason();
    }

    if (nativeException instanceof FirebaseAuthUserCollisionException) {
      String email = ((FirebaseAuthUserCollisionException) nativeException).getEmail();

      if (email != null) {
        additionalData.put("email", email);
      }

      AuthCredential authCredential =
          ((FirebaseAuthUserCollisionException) nativeException).getUpdatedCredential();

      if (authCredential != null) {
        additionalData.put("authCredential", parseAuthCredential(authCredential));
      }
    }

    if ("UNKNOWN".equals(code)) {
      if (nativeException instanceof FirebaseNetworkException) {
        code = "NETWORK_REQUEST_FAILED";
      } else if (nativeException instanceof FirebaseTooManyRequestsException) {
        code = "TOO_MANY_REQUESTS";
      }
    }

    this.code = code;
    this.message = message;
    this.additionalData = additionalData;
  }

  static FirebaseAuthPluginException noUser() {
    return new FirebaseAuthPluginException("NO_CURRENT_USER", "No user currently signed in.");
  }

  static FirebaseAuthPluginException invalidCredential() {
    return new FirebaseAuthPluginException(
        "INVALID_CREDENTIAL",
        "The supplied auth credential is malformed, has expired or is not currently supported.");
  }

  static FirebaseAuthPluginException noSuchProvider() {
    return new FirebaseAuthPluginException(
        "NO_SUCH_PROVIDER", "User was not linked to an account with the given provider.");
  }

  public String getCode() {
    return code.toLowerCase().replace("error_", "").replace("_", "-");
  }

  @Override
  public String getMessage() {
    return message;
  }

  public Map<String, Object> getAdditionalData() {
    return additionalData;
  }
}
