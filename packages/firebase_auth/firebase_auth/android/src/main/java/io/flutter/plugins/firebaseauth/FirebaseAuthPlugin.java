// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebaseauth;

import android.app.Activity;
import android.net.Uri;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.ActionCodeEmailInfo;
import com.google.firebase.auth.ActionCodeInfo;
import com.google.firebase.auth.ActionCodeMultiFactorInfo;
import com.google.firebase.auth.ActionCodeResult;
import com.google.firebase.auth.ActionCodeSettings;
import com.google.firebase.auth.AdditionalUserInfo;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.EmailAuthProvider;
import com.google.firebase.auth.FacebookAuthProvider;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GetTokenResult;
import com.google.firebase.auth.GithubAuthProvider;
import com.google.firebase.auth.GoogleAuthProvider;
import com.google.firebase.auth.MultiFactorInfo;
import com.google.firebase.auth.OAuthProvider;
import com.google.firebase.auth.SignInMethodQueryResult;
import com.google.firebase.auth.TwitterAuthProvider;
import com.google.firebase.auth.UserInfo;
import com.google.firebase.auth.UserProfileChangeRequest;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;

import static io.flutter.plugins.firebase.core.FlutterFirebasePluginRegistry.registerPlugin;

/** Flutter plugin for Firebase Auth. */
public class FirebaseAuthPlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final HashMap<String, FirebaseAuth.AuthStateListener> mAuthListeners =
      new HashMap<>();
  private static final HashMap<String, FirebaseAuth.IdTokenListener> mIdTokenListeners =
      new HashMap<>();
  private PluginRegistry.Registrar registrar;
  private MethodChannel channel;
  private Activity activity;

  @SuppressWarnings("unused")
  public static void registerWith(PluginRegistry.Registrar registrar) {
    FirebaseAuthPlugin instance = new FirebaseAuthPlugin();
    instance.registrar = registrar;
    instance.initInstance(registrar.messenger());
  }

  static Map<String, Object> parseAuthCredential(@NonNull AuthCredential authCredential) {
    Map<String, Object> output = new HashMap<>();

    output.put("providerId", authCredential.getProvider());
    output.put("signInMethod", authCredential.getSignInMethod());

    return output;
  }

  private void initInstance(BinaryMessenger messenger) {
    String channelName = "plugins.flutter.io/firebase_auth";
    registerPlugin(channelName, this);
    channel = new MethodChannel(messenger, channelName);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    removeEventListeners();
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    activity = activityPluginBinding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    activity = activityPluginBinding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  // Ensure any listeners are removed when the app
  // is detached from the FlutterEngine
  private void removeEventListeners() {
    Iterator<?> authListenerIterator = mAuthListeners.entrySet().iterator();

    while (authListenerIterator.hasNext()) {
      Map.Entry<?, ?> pair = (Map.Entry<?, ?>) authListenerIterator.next();
      String appName = (String) pair.getKey();
      FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
      FirebaseAuth firebaseAuth = FirebaseAuth.getInstance(firebaseApp);
      FirebaseAuth.AuthStateListener mAuthListener =
          (FirebaseAuth.AuthStateListener) pair.getValue();
      firebaseAuth.removeAuthStateListener(mAuthListener);
      authListenerIterator.remove();
    }

    Iterator<?> idTokenListenerIterator = mIdTokenListeners.entrySet().iterator();

    while (idTokenListenerIterator.hasNext()) {
      Map.Entry<?, ?> pair = (Map.Entry<?, ?>) idTokenListenerIterator.next();
      String appName = (String) pair.getKey();
      FirebaseApp firebaseApp = FirebaseApp.getInstance(appName);
      FirebaseAuth firebaseAuth = FirebaseAuth.getInstance(firebaseApp);
      FirebaseAuth.IdTokenListener mAuthListener = (FirebaseAuth.IdTokenListener) pair.getValue();
      firebaseAuth.removeIdTokenListener(mAuthListener);
      idTokenListenerIterator.remove();
    }
  }

  private FirebaseAuth getAuth(Map<String, Object> arguments) {
    String appName = (String) arguments.get("appName");
    FirebaseApp app = FirebaseApp.getInstance(appName);
    return FirebaseAuth.getInstance(app);
  }

  private FirebaseUser getCurrentUser(Map<String, Object> arguments) {
    String appName = (String) arguments.get("appName");
    FirebaseApp app = FirebaseApp.getInstance(appName);
    return FirebaseAuth.getInstance(app).getCurrentUser();
  }

  private AuthCredential getCredential(Map<String, Object> arguments) {
    //noinspection unchecked
    Map<String, String> credentialMap = (Map<String, String>) arguments.get("credential");
    String providerId = credentialMap.get("providerId");
    String secret = credentialMap.get("secret");
    String idToken = credentialMap.get("idToken");
    String accessToken = credentialMap.get("accessToken");
    String rawNonce = credentialMap.get("rawNonce");

    switch (providerId) {
      case "password":
        return EmailAuthProvider.getCredential(credentialMap.get("email"), secret);
      case "emailLink":
        return EmailAuthProvider.getCredentialWithLink(
            credentialMap.get("email"), credentialMap.get("emailLink"));
      case "facebook.com":
        return FacebookAuthProvider.getCredential(accessToken);
      case "google.com":
        return GoogleAuthProvider.getCredential(idToken, accessToken);
      case "twitter.com":
        return TwitterAuthProvider.getCredential(accessToken, secret);
      case "github.com":
        return GithubAuthProvider.getCredential(accessToken);
      case "oauth":
        {
          OAuthProvider.CredentialBuilder builder = OAuthProvider.newCredentialBuilder(providerId);
          builder.setAccessToken(accessToken);

          if (rawNonce == null) {
            builder.setIdToken(idToken);
          } else {
            builder.setIdTokenWithRawNonce(idToken, rawNonce);
          }

          return builder.build();
        }
      default:
        return null;
    }
  }

  private Map<String, Object> parseActionCodeResult(@NonNull ActionCodeResult actionCodeResult) {
    Map<String, Object> output = new HashMap<>();
    Map<String, Object> data = new HashMap<>();

    int operation = actionCodeResult.getOperation();
    output.put("operation", operation);

    if (operation == ActionCodeResult.VERIFY_EMAIL
        || operation == ActionCodeResult.PASSWORD_RESET) {
      ActionCodeInfo actionCodeInfo = actionCodeResult.getInfo();
      data.put("email", actionCodeInfo.getEmail());
      data.put("previousEmail", null);
      data.put("multiFactorInfo", null);
    } else if (operation == ActionCodeResult.REVERT_SECOND_FACTOR_ADDITION) {
      ActionCodeMultiFactorInfo actionCodeMultiFactorInfo =
          (ActionCodeMultiFactorInfo) actionCodeResult.getInfo();
      data.put("email", null);
      data.put("previousEmail", null);
      data.put(
          "multiFactorInfo", parseMultiFactorInfo(actionCodeMultiFactorInfo.getMultiFactorInfo()));
    } else if (operation == ActionCodeResult.RECOVER_EMAIL
        || operation == ActionCodeResult.VERIFY_BEFORE_CHANGE_EMAIL) {
      ActionCodeEmailInfo actionCodeEmailInfo = (ActionCodeEmailInfo) actionCodeResult.getInfo();
      data.put("email", actionCodeEmailInfo.getEmail());
      data.put("previousEmail", actionCodeEmailInfo.getPreviousEmail());
      data.put("multiFactorInfo", null);
    }

    output.put("data", data);
    return output;
  }

  private Map<String, Object> parseMultiFactorInfo(@NonNull MultiFactorInfo multiFactorInfo) {
    Map<String, Object> output = new HashMap<>();

    output.put("displayName", multiFactorInfo.getDisplayName());
    output.put("enrollmentTimestamp", multiFactorInfo.getEnrollmentTimestamp() * 1000);
    output.put("factorId", multiFactorInfo.getFactorId());
    output.put("uid", multiFactorInfo.getUid());

    return output;
  }

  private Map<String, Object> parseAuthResult(@NonNull AuthResult authResult) {
    Map<String, Object> output = new HashMap<>();

    output.put("additionalUserInfo", parseAdditionalUserInfo(authResult.getAdditionalUserInfo()));
    output.put("authCredential", parseAuthCredential(authResult.getCredential()));
    output.put("user", parseFirebaseUser(authResult.getUser()));

    return output;
  }

  private Map<String, Object> parseAdditionalUserInfo(
      @NonNull AdditionalUserInfo additionalUserInfo) {
    Map<String, Object> output = new HashMap<>();

    output.put("isNewUser", additionalUserInfo.isNewUser());
    output.put("profile", additionalUserInfo.getProfile());
    output.put("providerId", additionalUserInfo.getProviderId());
    output.put("username", additionalUserInfo.getUsername());

    return output;
  }

  private Map<String, Object> parseFirebaseUser(@NonNull FirebaseUser firebaseUser) {
    Map<String, Object> output = new HashMap<>();
    Map<String, Object> metadata = new HashMap<>();
    List<Map<String, Object>> providerData = new ArrayList<>();

    output.put("displayName", firebaseUser.getDisplayName());
    output.put("email", firebaseUser.getEmail());
    output.put("emailVerified", firebaseUser.isEmailVerified());
    output.put("isAnonymous", firebaseUser.isAnonymous());
    output.put("metadata", firebaseUser.isAnonymous()); // todo

    metadata.put("creationTime", firebaseUser.getMetadata().getCreationTimestamp());
    metadata.put("lastSignInTime", firebaseUser.getMetadata().getLastSignInTimestamp());
    output.put("metadata", metadata);

    output.put("phoneNumber", firebaseUser.getPhoneNumber());

    List<? extends UserInfo> userInfoList = firebaseUser.getProviderData();
    for (UserInfo userInfo : userInfoList) {
      providerData.add(parseUserInfo(userInfo));
    }
    output.put("providerData", providerData);
    output.put("refreshToken", ""); // native does not provide refresh tokens
    output.put("uid", firebaseUser.getUid());

    return output;
  }

  private Map<String, Object> parseUserInfo(@NonNull UserInfo userInfo) {
    Map<String, Object> output = new HashMap<>();

    output.put("displayName", userInfo.getDisplayName());
    output.put("email", userInfo.getEmail());
    output.put("phoneNumber", userInfo.getPhoneNumber());
    output.put("providerId", userInfo.getProviderId());
    output.put("uid", userInfo.getUid());

    return output;
  }

  private ActionCodeSettings getActionCodeSettings(
      @NonNull Map<String, Object> actionCodeSettingsMap) {
    ActionCodeSettings.Builder builder = ActionCodeSettings.newBuilder();

    builder.setUrl((String) actionCodeSettingsMap.get("url"));

    if (actionCodeSettingsMap.get("dynamicLinkDomain") != null) {
      builder.setDynamicLinkDomain((String) actionCodeSettingsMap.get("dynamicLinkDomain"));
    }

    if (actionCodeSettingsMap.get("handleCodeInApp") != null) {
      builder.setHandleCodeInApp((Boolean) actionCodeSettingsMap.get("handleCodeInApp"));
    }

    if (actionCodeSettingsMap.get("android") != null) {
      @SuppressWarnings("unchecked")
      Map<String, Object> android = (Map<String, Object>) actionCodeSettingsMap.get("android");
      Boolean installIfNotAvailable = false;
      if (android.get("installApp") != null) {
        installIfNotAvailable = (Boolean) android.get("installApp");
      }
      String minimumVersion = null;
      if (android.get("minimumVersion") != null) {
        minimumVersion = (String) android.get("minimumVersion");
      }

      builder.setAndroidPackageName(
          (String) android.get("packageName"), installIfNotAvailable, minimumVersion);
    }

    if (actionCodeSettingsMap.get("iOS") != null) {
      @SuppressWarnings("unchecked")
      Map<String, Object> iOS = (Map<String, Object>) actionCodeSettingsMap.get("iOS");
      builder.setIOSBundleId((String) iOS.get("bundleId"));
    }

    return builder.build();
  }

  private Map<String, Object> parseTokenResult(@NonNull GetTokenResult tokenResult) {
    Map<String, Object> output = new HashMap<>();

    output.put("authTimestamp", tokenResult.getAuthTimestamp() * 1000);
    output.put("claims", tokenResult.getClaims());
    output.put("expirationTimestamp", tokenResult.getExpirationTimestamp() * 1000);
    output.put("issuedAtTimestamp", tokenResult.getIssuedAtTimestamp() * 1000);
    output.put("signInProvider", tokenResult.getSignInProvider());
    output.put("signInSecondFactor", tokenResult.getSignInSecondFactor());
    output.put("token", tokenResult.getToken());

    return output;
  }

  private Task<Void> registerChangeListeners(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          String appName = (String) Objects.requireNonNull(arguments.get("appName"));
          FirebaseAuth firebaseAuth = getAuth(arguments);

          FirebaseAuth.AuthStateListener authStateListener = mAuthListeners.get(appName);
          FirebaseAuth.IdTokenListener idTokenListener = mIdTokenListeners.get(appName);

          Map<String, Object> event = new HashMap<>();
          event.put("appName", appName);

          if (authStateListener == null) {
            FirebaseAuth.AuthStateListener newAuthStateListener =
                auth -> {
                  FirebaseUser user = firebaseAuth.getCurrentUser();

                  if (user == null) {
                    event.put("user", null);
                  } else {
                    event.put("user", parseFirebaseUser(user));
                  }

                  channel.invokeMethod("Auth#authStateChanges", event);
                };

            firebaseAuth.addAuthStateListener(newAuthStateListener);
            mAuthListeners.put(appName, newAuthStateListener);
          }

          if (idTokenListener == null) {
            FirebaseAuth.IdTokenListener newIdTokenChangeListener =
                auth -> {
                  FirebaseUser user = firebaseAuth.getCurrentUser();

                  if (user == null) {
                    event.put("user", null);
                  } else {
                    event.put("user", parseFirebaseUser(user));
                  }

                  channel.invokeMethod("Auth#idTokenChanges", event);
                };

            firebaseAuth.addIdTokenListener(newIdTokenChangeListener);
            mIdTokenListeners.put(appName, newIdTokenChangeListener);
          }

          return null;
        });
  }

  private Task<Void> applyActionCode(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String code = (String) Objects.requireNonNull(arguments.get("code"));

          return Tasks.await(firebaseAuth.applyActionCode(code));
        });
  }

  private Task<Map<String, Object>> checkActionCode(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String code = (String) Objects.requireNonNull(arguments.get("code"));

          ActionCodeResult actionCodeResult = Tasks.await(firebaseAuth.checkActionCode(code));
          return parseActionCodeResult(actionCodeResult);
        });
  }

  private Task<Void> confirmPasswordReset(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String code = (String) Objects.requireNonNull(arguments.get("code"));
          String newPassword = (String) Objects.requireNonNull(arguments.get("newPassword"));

          return Tasks.await(firebaseAuth.confirmPasswordReset(code, newPassword));
        });
  }

  private Task<Map<String, Object>> createUserWithEmailAndPassword(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String email = (String) Objects.requireNonNull(arguments.get("email"));
          String password = (String) Objects.requireNonNull(arguments.get("password"));

          AuthResult authResult =
              Tasks.await(firebaseAuth.createUserWithEmailAndPassword(email, password));

          return parseAuthResult(authResult);
        });
  }

  private Task<List<String>> fetchSignInMethodsForEmail(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String email = (String) Objects.requireNonNull(arguments.get("email"));

          SignInMethodQueryResult result =
              Tasks.await(firebaseAuth.fetchSignInMethodsForEmail(email));
          return result.getSignInMethods();
        });
  }

  private Task<Void> sendPasswordResetEmail(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String email = (String) Objects.requireNonNull(arguments.get("email"));
          Object rawActionCodeSettings = arguments.get("actionCodeSettings");

          if (rawActionCodeSettings == null) {
            return Tasks.await(firebaseAuth.sendPasswordResetEmail(email));
          }

          @SuppressWarnings("unchecked")
          Map<String, Object> actionCodeSettings = (Map<String, Object>) rawActionCodeSettings;

          return Tasks.await(
              firebaseAuth.sendPasswordResetEmail(
                  email, getActionCodeSettings(actionCodeSettings)));
        });
  }

  //    private Task<Integer> authStateChanges(Map<String, Object> arguments) {
  //        return Tasks.call(
  //                cachedThreadPool,
  //                () -> {
  //                    int handle = (int) Objects.requireNonNull(arguments.get("handle"));
  //                    FirebaseAuth firebaseAuth = getAuth(arguments);
  //
  //                    AuthStateListener listener = auth -> {
  //                        FirebaseUser firebaseUser = auth.getCurrentUser();
  //                        Map<String, Object> output = new HashMap<>();
  //
  //                        if (firebaseUser == null) {
  //                            output.put("user", null);
  //                        } else {
  //                            output.put("user", parseFirebaseUser(firebaseUser));
  //                        }
  //
  //                        channel.invokeMethod("Auth#authStateChanges", output);
  //                    };
  //
  //                    authListenerRegistrations.put(handle, listener);
  //                    firebaseAuth.addAuthStateListener(listener);
  //
  //                    return handle;
  //                });
  //    }
  //
  //    private Task<Integer> idTokenChanges(Map<String, Object> arguments) {
  //        return Tasks.call(
  //                cachedThreadPool,
  //                () -> {
  //                    int handle = (int) Objects.requireNonNull(arguments.get("handle"));
  //                    FirebaseAuth firebaseAuth = getAuth(arguments);
  //
  //                    IdTokenListener listener = auth -> {
  //                        FirebaseUser firebaseUser = auth.getCurrentUser();
  //                        Map<String, Object> output = new HashMap<>();
  //
  //                        if (firebaseUser == null) {
  //                            output.put("user", null);
  //                        } else {
  //                            output.put("user", parseFirebaseUser(firebaseUser));
  //                        }
  //
  //                        channel.invokeMethod("Auth#authStateChanges", output);
  //                    };
  //
  //                    authListenerRegistrations.put(handle, listener);
  //                    firebaseAuth.addIdTokenListener(listener);
  //
  //                    return handle;
  //                });
  //    }

  private Task<String> setLanguageCode(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String languageCode = (String) arguments.get("languageCode");

          if (languageCode == null) {
            firebaseAuth.useAppLanguage();
          } else {
            firebaseAuth.setLanguageCode(languageCode);
          }

          return firebaseAuth.getLanguageCode();
        });
  }

  private Task<Map<String, Object>> signInAnonymously(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          AuthResult authResult = Tasks.await(firebaseAuth.signInAnonymously());
          return parseAuthResult(authResult);
        });
  }

  private Task<Map<String, Object>> signInWithCredential(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          AuthCredential credential = getCredential(arguments);

          if (credential == null) {
            throw FirebaseAuthPluginException.invalidCredential();
          }

          AuthResult authResult = Tasks.await(firebaseAuth.signInWithCredential(credential));
          return parseAuthResult(authResult);
        });
  }

  private Task<Map<String, Object>> signInWithCustomToken(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String token = (String) Objects.requireNonNull(arguments.get("token"));

          AuthResult authResult = Tasks.await(firebaseAuth.signInWithCustomToken(token));
          return parseAuthResult(authResult);
        });
  }

  private Task<Map<String, Object>> signInWithEmailAndPassword(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String email = (String) Objects.requireNonNull(arguments.get("email"));
          String password = (String) Objects.requireNonNull(arguments.get("password"));

          AuthResult authResult =
              Tasks.await(firebaseAuth.signInWithEmailAndPassword(email, password));
          return parseAuthResult(authResult);
        });
  }

  private Task<Map<String, Object>> signInWithEmailAndLink(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String email = (String) Objects.requireNonNull(arguments.get("email"));
          String emailLink = (String) Objects.requireNonNull(arguments.get("emailLink"));

          AuthResult authResult = Tasks.await(firebaseAuth.signInWithEmailLink(email, emailLink));
          return parseAuthResult(authResult);
        });
  }

  private Task<Void> signOut(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          firebaseAuth.signOut();
          return null;
        });
  }

  private Task<String> verifyPasswordResetCode(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseAuth firebaseAuth = getAuth(arguments);
          String code = (String) Objects.requireNonNull(arguments.get("code"));
          return Tasks.await(firebaseAuth.verifyPasswordResetCode(code));
        });
  }

  private Task<Void> deleteUser(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          return Tasks.await(firebaseUser.delete());
        });
  }

  private Task<Object> getIdToken(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);
          Boolean forceRefresh = (Boolean) Objects.requireNonNull(arguments.get("forceRefresh"));
          Boolean tokenOnly = (Boolean) Objects.requireNonNull(arguments.get("tokenOnly"));

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          GetTokenResult tokenResult = Tasks.await(firebaseUser.getIdToken(forceRefresh));

          if (tokenOnly) {
            return tokenResult.getToken();
          } else {
            return parseTokenResult(tokenResult);
          }
        });
  }

  private Task<Map<String, Object>> linkUserWithCredential(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);
          AuthCredential credential = getCredential(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          if (credential == null) {
            throw FirebaseAuthPluginException.invalidCredential();
          }

          AuthResult authResult = Tasks.await(firebaseUser.linkWithCredential(credential));
          return parseAuthResult(authResult);
        });
  }

  private Task<Map<String, Object>> reauthenticateUserWithCredential(
      Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);
          AuthCredential credential = getCredential(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          if (credential == null) {
            throw FirebaseAuthPluginException.invalidCredential();
          }

          AuthResult authResult =
              Tasks.await(firebaseUser.reauthenticateAndRetrieveData(credential));
          return parseAuthResult(authResult);
        });
  }

  private Task<Void> reloadUser(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          return Tasks.await(firebaseUser.reload());
        });
  }

  private Task<Void> sendEmailVerification(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          Object rawActionCodeSettings = arguments.get("actionCodeSettings");
          if (rawActionCodeSettings == null) {
            return Tasks.await(firebaseUser.sendEmailVerification());
          }

          @SuppressWarnings("unchecked")
          Map<String, Object> actionCodeSettings = (Map<String, Object>) rawActionCodeSettings;

          return Tasks.await(
              firebaseUser.sendEmailVerification(getActionCodeSettings(actionCodeSettings)));
        });
  }

  private Task<Map<String, Object>> unlinkUserProvider(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          String providerId = (String) Objects.requireNonNull(arguments.get("providerId"));
          AuthResult result = Tasks.await(firebaseUser.unlink(providerId));
          return parseAuthResult(result);
        });
  }

  private Task<Void> updateEmail(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          String newEmail = (String) Objects.requireNonNull(arguments.get("newEmail"));
          return Tasks.await(firebaseUser.updateEmail(newEmail));
        });
  }

  private Task<Void> updateProfile(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          @SuppressWarnings("unchecked")
          Map<String, String> profile =
              (Map<String, String>) Objects.requireNonNull(arguments.get("profile"));
          UserProfileChangeRequest.Builder builder = new UserProfileChangeRequest.Builder();

          if (profile.get("displayName") != null) {
            builder.setDisplayName(profile.get("displayName"));
          }

          if (profile.get("photoURL") != null) {
            builder.setPhotoUri(Uri.parse(profile.get("photoURL")));
          }

          return Tasks.await(firebaseUser.updateProfile(builder.build()));
        });
  }

  private Task<Void> verifyBeforeUpdateEmail(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseUser firebaseUser = getCurrentUser(arguments);

          if (firebaseUser == null) {
            throw FirebaseAuthPluginException.noUser();
          }

          String newEmail = (String) Objects.requireNonNull(arguments.get("newEmail"));
          Object rawActionCodeSettings = arguments.get("actionCodeSettings");

          if (rawActionCodeSettings == null) {
            return Tasks.await(firebaseUser.verifyBeforeUpdateEmail(newEmail));
          }

          @SuppressWarnings("unchecked")
          Map<String, Object> actionCodeSettings = (Map<String, Object>) rawActionCodeSettings;

          return Tasks.await(
              firebaseUser.verifyBeforeUpdateEmail(
                  newEmail, getActionCodeSettings(actionCodeSettings)));
        });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Task<?> methodCallTask;

    switch (call.method) {
      case "Auth#registerChangeListeners":
        methodCallTask = registerChangeListeners(call.arguments());
        break;
      case "Auth#applyActionCode":
        methodCallTask = applyActionCode(call.arguments());
        break;
      case "Auth#checkActionCode":
        methodCallTask = checkActionCode(call.arguments());
        break;
      case "Auth#confirmPasswordReset":
        methodCallTask = confirmPasswordReset(call.arguments());
        break;
      case "Auth#createUserWithEmailAndPassword":
        methodCallTask = createUserWithEmailAndPassword(call.arguments());
        break;
      case "Auth#fetchSignInMethodsForEmail":
        methodCallTask = fetchSignInMethodsForEmail(call.arguments());
        break;
      case "Auth#sendPasswordResetEmail":
        methodCallTask = sendPasswordResetEmail(call.arguments());
        break;
      case "Auth#signInWithCredential":
        methodCallTask = signInWithCredential(call.arguments());
        break;
      case "Auth#setLanguageCode":
        methodCallTask = setLanguageCode(call.arguments());
        break;
      case "Auth#signInAnonymously":
        methodCallTask = signInAnonymously(call.arguments());
        break;
      case "Auth#signInWithCustomToken":
        methodCallTask = signInWithCustomToken(call.arguments());
        break;
      case "Auth#signInWithEmailAndPassword":
        methodCallTask = signInWithEmailAndPassword(call.arguments());
        break;
      case "Auth#signInWithEmailAndLink":
        methodCallTask = signInWithEmailAndLink(call.arguments());
        break;
      case "Auth#signOut":
        methodCallTask = signOut(call.arguments());
        break;
      case "Auth#verifyPasswordResetCode":
        methodCallTask = verifyPasswordResetCode(call.arguments());
        break;
      case "User#delete":
        methodCallTask = deleteUser(call.arguments());
        break;
      case "User#getIdToken":
        methodCallTask = getIdToken(call.arguments());
        break;
      case "User#linkWithCredential":
        methodCallTask = linkUserWithCredential(call.arguments());
        break;
      case "User#reauthenticateUserWithCredential":
        methodCallTask = reauthenticateUserWithCredential(call.arguments());
        break;
      case "User#reload":
        methodCallTask = reloadUser(call.arguments());
        break;
      case "User#sendEmailVerification":
        methodCallTask = sendEmailVerification(call.arguments());
        break;
      case "User#unlink":
        methodCallTask = unlinkUserProvider(call.arguments());
        break;
      case "User#updateEmail":
        methodCallTask = updateEmail(call.arguments());
        break;
      case "User#updateProfile":
        methodCallTask = updateProfile(call.arguments());
        break;
      case "User#verifyBeforeUpdateEmail":
        methodCallTask = verifyBeforeUpdateEmail(call.arguments());
        break;
      default:
        result.notImplemented();
        return;
    }

    methodCallTask.addOnCompleteListener(
        task -> {
          if (task.isSuccessful()) {
            result.success(task.getResult());
          } else {
            Exception exception = task.getException();
            result.error(
                "firebase_auth",
                exception != null ? exception.getMessage() : null,
                getExceptionDetails(exception));
          }
        });
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Map<String, Object> constants = new HashMap<>();
          FirebaseAuth firebaseAuth = FirebaseAuth.getInstance(firebaseApp);
          FirebaseUser firebaseUser = firebaseAuth.getCurrentUser();
          String languageCode = firebaseAuth.getLanguageCode();

          Map<String, Object> user = firebaseUser == null ? null : parseFirebaseUser(firebaseUser);

          if (languageCode != null) {
            constants.put("APP_LANGUAGE_CODE", languageCode);
          }

          if (user != null) {
            constants.put("APP_CURRENT_USER", user);
          }

          return constants;
        });
  }

  private Map<String, Object> getExceptionDetails(Exception exception) {
    Map<String, Object> details = new HashMap<>();

    if (exception == null) {
      return details;
    }

    FirebaseAuthPluginException authException = null;

    if (exception instanceof FirebaseAuthException) {
      authException =
          new FirebaseAuthPluginException((FirebaseAuthException) exception, exception.getCause());
    } else if (exception.getCause() != null
        && exception.getCause() instanceof FirebaseAuthException) {
      authException =
          new FirebaseAuthPluginException(
              (FirebaseAuthException) exception.getCause(),
              exception.getCause().getCause() != null
                  ? exception.getCause().getCause()
                  : exception.getCause());
    }

    if (authException != null) {
      details.put("code", authException.getCode());
      details.put("message", authException.getMessage());
      details.put("additionalData", authException.getAdditionalData());
    }

    return details;
  }
}
