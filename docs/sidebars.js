function toReferenceAPI(plugin) {
  return {
    type: "link",
    label: "Reference API",
    href: `https://pub.dev/documentation/${plugin}/latest/`,
  };
}

module.exports = {
  main: {
    "Getting Started": [
      "overview",
      "installation/android",
      "installation/ios",
      "installation/web",
    ],
    // AdMob: ["admob/usage", toReferenceAPI("firebase_admob")],
    // Analytics: ["analytics/usage", toReferenceAPI("firebase_analytics")],
    Authentication: [
      "auth/overview",
      "auth/usage",
      "auth/social",
      "auth/phone",
      "auth/error-handling",
      toReferenceAPI("firebase_auth"),
    ],
    "Cloud Firestore": [
      "firestore/overview",
      "firestore/usage",
      toReferenceAPI("cloud_firestore"),
    ],
    // "Cloud Functions": ["functions/usage", toReferenceAPI("cloud_functions")],
    // "Cloud Messaging": ["messaging/usage", toReferenceAPI("firebase_messaging")],
    // "Cloud Storage": ["storage/usage", toReferenceAPI("firebase_storage")],
    Core: ["core/usage", toReferenceAPI("firebase_core")],
    // Crashlytics: ["crashlytics/usage", toReferenceAPI("firebase_crashlytics")],
    // "Realtime Database": ["database/usage", toReferenceAPI("firebase_database")],
    // "Dynamic Links": ["dynamic-links/usage", toReferenceAPI("firebase_dynamic_links")],
    // "Instance ID": ["iid/usage", toReferenceAPI("firebase_in_app_messaging")],
    // "In-App Messaging": ["in-app-messaging/usage", toReferenceAPI("firebase_in_app_messaging")],
    // "ML Kit Natural Language": ["ml-language/usage"],
    // "ML Kit Vision": ["ml-vision/usage", toReferenceAPI("firebase_ml_vision")],
    // "Remote Config": ["remote-config/usage", toReferenceAPI("firebase_remote_config")],
    // "Performance Monitoring": ["performance/usage", toReferenceAPI("firebase_performance")],
  },
};
