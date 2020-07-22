package io.flutter.plugins.firebaseauthexample;

import androidx.annotation.NonNull;
import dev.flutter.plugins.e2e.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import org.junit.runner.RunWith;

@RunWith(FlutterTestRunner.class)
public class MainActivity extends FlutterActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
