// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// The options used to configure a Firebase app.
///
/// ```dart
/// await FirebaseCore.instance.initializeApp(
///   name: 'SecondaryApp',
///   options: const FirebaseOptions(
///     apiKey: '...',
///     appId: '...',
///     messagingSenderId: '...',
///     projectId: '...',
///   )
/// );
/// ```
class FirebaseOptions {
  const FirebaseOptions({
    this.apiKey,
    this.appId,
    this.messagingSenderId,
    this.projectId,
    this.authDomain,
    this.databaseURL,
    this.storageBucket,
    this.measurementId,
    // ios specific
    this.trackingId,
    this.deepLinkURLScheme,
    this.androidClientId,
    this.iosBundleId,
    // deprecated
    @Deprecated("Deprecated in favor of 'appId'") this.googleAppID,
    @Deprecated("Deprecated in favor of 'projectId'") this.projectID,
    @Deprecated("Deprecated in favor of 'iosBundleId'") this.bundleID,
    @Deprecated("Deprecated in favor of 'androidClientId'") this.clientID,
    @Deprecated("Deprecated in favor of 'trackingId'") this.trackingID,
    @Deprecated("Deprecated in favor of 'messagingSenderId'") this.gcmSenderID,
  })  : assert(apiKey != null, "'apiKey' cannot be null"),
        assert(appId != null || googleAppID != null, "'appId' and 'googleAppID' cannot be null."),
        assert(messagingSenderId != null || gcmSenderID != null, "'messagingSenderId' and 'gcmSenderID' cannot be null."),
        assert(projectId != null || projectID != null, "'projectId' and 'projectID' cannot be null.");

  /// Named constructor to create [FirebaseOptions] from a Map.
  ///
  /// This constructor is used when platforms cannot directly return a
  /// [FirebaseOptions] instance, for example when data is sent back from a
  /// [MethodChannel].
  FirebaseOptions.fromMap(Map<dynamic, dynamic> map)
      : assert(map['apiKey'] != null, "'apiKey' cannot be null."),
        assert(map['appId'] != null || map['googleAppID'], "'appId' and 'googleAppID' cannot be null."),
        assert(map['messagingSenderId'] != null || map['gcmSenderID'], "'messagingSenderId' and 'gcmSenderID' cannot be null."),
        assert(map['projectId'] != null || map['projectID'], "'projectId' and 'projectID' cannot be null."),
        apiKey = map['apiKey'],
        appId = map['appId'],
        messagingSenderId = map['messagingSenderId'],
        projectId = map['projectId'],
        authDomain = map['authDomain'],
        databaseURL = map['databaseURL'],
        storageBucket = map['storageBucket'],
        measurementId = map['measurementId'],
        trackingId = map['trackingId'],
        deepLinkURLScheme = map['deepLinkURLScheme'],
        androidClientId = map['androidClientId'],
        iosBundleId = map['iosBundleId'],
        trackingID = map['trackingID'],
        googleAppID = map['googleAppID'],
        projectID = map['projectID'],
        bundleID = map['bundleID'],
        clientID = map['clientID'],
        gcmSenderID = map['gcmSenderID'];

  /// An API key used for authenticating requests from your app, for example
  /// "AIzaSyDdVgKwhZl0sTTTLZ7iTmt1r3N2cJLnaDk", used to identify your app to
  /// Google servers.
  final String apiKey;

  /// The Google App ID that is used to uniquely identify an instance of an app.
  ///
  /// This property is required cannot be `null`.
  final String appId;

  /// The unique sender ID value used in messaging to identify your app.
  ///
  /// This property is required cannot be `null`.
  final String messagingSenderId;

  /// The Project ID from the Firebase console, for example "my-awesome-app".
  final String projectId;

  /// The auth domain used to handle redirects from OAuth provides on web
  /// platforms, for example "my-awesome-app.firebaseapp.com".
  final String authDomain;

  /// The database root URL, for example "https://my-awesome-app.firebaseio.com."
  ///
  /// This property should be set for apps that use Firebase Database.
  final String databaseURL;

  /// The Google Cloud Storage bucket name, for example
  /// "my-awesome-app.appspot.com".
  final String storageBucket;

  /// The project measurement ID value used on web platforms with analytics.
  final String measurementId;

  /// The tracking ID for Google Analytics, for example "UA-12345678-1", used to
  /// configure Google Analytics.
  ///
  /// This property is used on iOS only.
  final String trackingId;

  /// The URL scheme used by iOS secondary apps for Dynamic Links.
  final String deepLinkURLScheme;

  /// The Android client ID from the Firebase Console, for example
  /// "12345.apps.googleusercontent.com."
  ///
  /// This value is used by iOS only.
  final String androidClientId;

  /// The iOS bundle ID for the application. Defaults to `[[NSBundle mainBundle] bundleID]`
  /// when not set manually or in a plist.
  ///
  /// This property is used on iOS only.
  final String iosBundleId;

  @Deprecated("Deprecated in favor of 'appId'")
  final String googleAppID;

  @Deprecated("Deprecated in favor of 'projectId'")
  final String projectID;

  @Deprecated("Deprecated in favor of 'iosBundleId'")
  final String bundleID;

  @Deprecated("Deprecated in favor of 'androidClientId'")
  final String clientID;

  @Deprecated("Deprecated in favor of 'trackingId'")
  final String trackingID;

  @Deprecated("Deprecated in favor of 'messagingSenderId'")
  final String gcmSenderID;

  /// The current instance as a [Map].
  Map<String, String> get asMap {
    return <String, String>{
      'apiKey': apiKey ?? googleAppID,
      'appId': appId,
      'messagingSenderId': messagingSenderId ?? gcmSenderID,
      'projectId': projectId ?? projectID,
      'authDomain': authDomain,
      'databaseURL': databaseURL,
      'storageBucket': storageBucket,
      'measurementId': measurementId,
      'trackingId': trackingId ?? trackingID,
      'deepLinkURLScheme': deepLinkURLScheme,
      'androidClientId': androidClientId ?? clientID,
      'iosBundleId': iosBundleId ?? bundleID,
    };
  }

  // Required from `fromMap` comparison
  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseOptions) return false;
    return other.apiKey == apiKey &&
        other.appId == appId &&
        other.messagingSenderId == messagingSenderId &&
        other.projectId == projectId &&
        other.authDomain == authDomain &&
        other.databaseURL == databaseURL &&
        other.storageBucket == storageBucket &&
        other.measurementId == measurementId &&
        other.trackingId == trackingId &&
        other.deepLinkURLScheme == deepLinkURLScheme &&
        other.androidClientId == androidClientId &&
        other.iosBundleId == iosBundleId &&
        other.googleAppID == googleAppID &&
        other.projectID == projectID &&
        other.bundleID == bundleID &&
        other.clientID == clientID &&
        other.trackingID == trackingID &&
        other.gcmSenderID == gcmSenderID;
  }

  @override
  int get hashCode {
    return hashObjects(asMap.entries);
  }

  @override
  String toString() => asMap.toString();
}
