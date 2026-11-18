import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // El plugin de Flutter debe aplicarse después del de Android.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- FIRMA ---
// Las credenciales del keystore viven en android/key.properties (fuera de git):
//   storePassword=...
//   keyPassword=...
//   keyAlias=upload
//   storeFile=upload-keystore.jks   (relativo a android/app)
// Sin ese archivo (p. ej. un clon nuevo) el release se firma con la clave de debug.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.jabc.booktracker"
    // Varias dependencias (notificaciones, permisos, androidx.core) exigen API 37;
    // Flutter 3.50 trae 36 por defecto. No cambia el targetSdk.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // El lint de AGP 9 falla con Java 17 (usa List.removeLast(), de Java 21) al
    // analizar plugins. Se omite en release; no afecta al APK/AAB generado.
    lint {
        checkReleaseBuilds = false
    }

    defaultConfig {
        applicationId = "com.jabc.booktracker"
        minSdk = 24 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
