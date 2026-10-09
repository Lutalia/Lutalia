plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter Plugin MUSS nach Android & Kotlin kommen
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase Google Services Plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.lutalia_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.lutalia_app"

        // ⭐ Health-Plugin benötigt minSdk 26
        minSdk = 26

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ⭐ Java 17 + Desugaring (KOTLIN DSL!)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // ← KORREKTE KTS-SYNTAX
    }

    kotlinOptions {
        jvmTarget = "17"
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

dependencies {
    // ⭐ Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))

    // ⭐ Firebase Produkte
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // ⭐ WICHTIG: Für flutter_local_notifications (KTS!)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ⭐ Health Connect: MainActivity registers the permission contract itself.
    // Keep this on the exact version the `health` plugin resolves (13.3.1).
    implementation("androidx.health.connect:connect-client:1.2.0-alpha02")
}
