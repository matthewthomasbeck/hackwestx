plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Auth0 Android redirect host must match the real tenant domain (and Dart AUTH0_DOMAIN).
// Prefer android/local.properties (gitignored), then gradle.properties.
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val auth0DomainProp = (
    localProps.getProperty("auth0Domain")
        ?: (project.findProperty("auth0Domain") as String?)
        ?: ""
    ).trim()
val auth0SchemeProp = (
    localProps.getProperty("auth0Scheme")
        ?: (project.findProperty("auth0Scheme") as String?)
        ?: "soothsayer"
    ).trim()

check(
    auth0DomainProp.isNotEmpty() &&
        auth0DomainProp != "YOUR_AUTH0_DOMAIN" &&
        auth0DomainProp != "PASTE_YOUR_AUTH0_DOMAIN_HERE" &&
        !auth0DomainProp.contains("://")
) {
    """
    Set your Auth0 domain for Android callbacks before building.
    Edit android/local.properties and add (no https://):
      auth0Domain=your-tenant.us.auth0.com
      auth0Scheme=soothsayer
    Then fully restart (not hot reload): flutter run --dart-define=AUTH0_DOMAIN=... --dart-define=AUTH0_CLIENT_ID=...
    """.trimIndent()
}

android {
    namespace = "com.hackwestx.soothsayer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.hackwestx.soothsayer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Must match Auth0 Allowed Callback URL host + scheme exactly.
        manifestPlaceholders["auth0Domain"] = auth0DomainProp
        manifestPlaceholders["auth0Scheme"] = auth0SchemeProp
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
