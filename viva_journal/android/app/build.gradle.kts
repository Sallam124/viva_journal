plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Added for Firebase
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))

    // Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    // Add other Firebase dependencies as needed
}

android {
    namespace = "com.example.viva_journal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Update this line with the required NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.viva_journal"
        minSdk = 24 // Updated to 24 (matches flutter_sound dependency)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services") // ✅ This applies Google Services Plugin correctly
