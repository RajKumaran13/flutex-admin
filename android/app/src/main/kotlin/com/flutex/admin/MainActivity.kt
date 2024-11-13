package com.flutex.admin

import android.os.Bundle // Import the Bundle class
import io.flutter.embedding.android.FlutterActivity
import com.google.firebase.FirebaseApp
import io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize Firebase (usually not necessary for Flutter, but can be done here if needed)
        FirebaseApp.initializeApp(this)
    }
}
