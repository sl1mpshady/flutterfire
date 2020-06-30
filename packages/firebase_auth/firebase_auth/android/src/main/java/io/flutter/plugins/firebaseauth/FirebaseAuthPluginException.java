package io.flutter.plugins.firebaseauth;

import androidx.annotation.NonNull;

import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseAuthMultiFactorException;
import com.google.firebase.auth.FirebaseAuthUserCollisionException;
import com.google.firebase.auth.FirebaseAuthWeakPasswordException;
import com.google.firebase.auth.MultiFactorResolver;

import java.util.HashMap;
import java.util.Map;

import static io.flutter.plugins.firebaseauth.FirebaseAuthPlugin.parseAuthCredential;
import static io.flutter.plugins.firebaseauth.FirebaseAuthPlugin.parseMultiFactorInfoList;

public class FirebaseAuthPluginException extends Exception {

  private final String code;
  private final String message;
  private Map<String, Object> additionalData = new HashMap<>();

  FirebaseAuthPluginException(@NonNull String code, @NonNull String message) {
    super(message, null);

    this.code = code;
    this.message = message;
  }

  FirebaseAuthPluginException(@NonNull FirebaseAuthException nativeException, Throwable cause) {
    super(nativeException.getMessage(), cause);

    String code = nativeException.getErrorCode();
    String message = nativeException.getMessage();
    Map<String, Object> additionalData = new HashMap<>();

    if (nativeException instanceof FirebaseAuthWeakPasswordException) {
      message = ((FirebaseAuthWeakPasswordException) nativeException).getReason();
    }

    if (nativeException instanceof FirebaseAuthUserCollisionException) {
      additionalData.put(
          "email", ((FirebaseAuthUserCollisionException) nativeException).getEmail());

      AuthCredential authCredential =
          ((FirebaseAuthUserCollisionException) nativeException).getUpdatedCredential();
      additionalData.put("authCredential", parseAuthCredential(authCredential));
    }

    if (nativeException instanceof FirebaseAuthMultiFactorException) {
      Map<String, Object> resolverMap = new HashMap<>();
      MultiFactorResolver multiFactorResolver =
          ((FirebaseAuthMultiFactorException) nativeException).getResolver();
      int resolverToken = multiFactorResolver.hashCode();

      resolverMap.put("token", resolverToken);
      resolverMap.put("hints", parseMultiFactorInfoList(multiFactorResolver.getHints()));

      // TODO Store resolver with token

      additionalData.put("resolver", resolverMap);
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
