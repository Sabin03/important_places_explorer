plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.important_places_explorer"
    compileSdk = flutter.compileSdkVersion
    
    // NDK Version Fix:
    // The plugins require NDK 27.0.12077973.
    // Replace 'ndkVersion = flutter.ndkVersion' with the specific version.
    ndkVersion = "27.0.12077973" // <--- CHANGE THIS LINE

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.important_places_explorer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        // minSdkVersion Fix:
        // Firebase Auth requires minSdk 23.
        // Replace 'minSdk = flutter.minSdkVersion' with the specific version.
        minSdk = 23 // <--- CHANGE THIS LINE (from flutter.minSdkVersion)
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
