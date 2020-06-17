# Ignore this hacky script! This is just a proof of concept...
def use_firebase_frameworks!()
  ENV['USE_FIREBASE_FRAMEWORKS'] = 'true'
  require_relative 'firebase_sdk_version'
  require 'open-uri'
  
  firebase_sdk_version = firebase_sdk_version!
  symlink = File.join('.symlinks', 'FirebaseFrameworks')
  cached_sdk_path = File.expand_path("~/.firebase-ios-sdk-frameworks/#{firebase_sdk_version}/")

  unless File.exist?(cached_sdk_path)
    FileUtils.mkdir_p(cached_sdk_path)
  end

  unless File.exist?(File.join(cached_sdk_path, 'firebase_firestore_frameworks.podspec'))
    system("cd #{cached_sdk_path} && curl -O https://storage.googleapis.com/firebase-ios-sdk.appspot.com/6.26.0/FirebaseFirestore.zip")
    system("cd #{cached_sdk_path} && unzip -qq -o FirebaseFirestore.zip && rm FirebaseFirestore.zip")
  end

  File.symlink(File.expand_path(cached_sdk_path), symlink)
  pod 'firebase_firestore_frameworks', :path => symlink
end
