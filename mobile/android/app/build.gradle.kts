import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties is generated locally and never
// committed (see .gitignore and docs/RELEASE_CHECKLIST.md). Falls back to
// debug signing when absent so `flutter run`/CI without secrets still work.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.playtap.app"
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
        applicationId = "com.playtap.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Safety net: a release build silently falling back to the debug key is
// fine for `flutter run --release` on a dev machine, but must never be
// mistaken for a real, submittable Store artifact — so make the fallback
// impossible to miss in the build output (see docs/RELEASE_CHECKLIST.md).
if (!hasReleaseSigning) {
    tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }
        .configureEach {
            doFirst {
                logger.warn(
                    "\n" +
                        "==================================================================\n" +
                        "  ATTENTION : ce build RELEASE est signe avec la cle DEBUG.\n" +
                        "  android/key.properties est introuvable.\n" +
                        "  Cet .apk/.aab NE DOIT PAS etre soumis au Play Store.\n" +
                        "  Valide uniquement pour un test local (flutter run --release).\n" +
                        "==================================================================\n"
                )
            }
        }
}

flutter {
    source = "../.."
}
