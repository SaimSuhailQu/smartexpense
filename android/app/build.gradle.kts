import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase plugin
    id("com.google.android.gms.strict-version-matcher-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = project.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.smartexpense"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13599879"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // ✅ For Java 8+ APIs
    }

    defaultConfig {
        applicationId = "com.smartexpense"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "dummy")
            keyPassword = keystoreProperties.getProperty("keyPassword", "dummy")
            val storeFileProp = keystoreProperties.getProperty("storeFile", "smartexpense.jks")
            storeFile = if (storeFileProp.startsWith("android/app/")) {
                rootProject.file(storeFileProp)
            } else {
                project.file(storeFileProp)
            }
            storePassword = keystoreProperties.getProperty("storePassword", "dummy")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    lintOptions {
        // See android/build.gradle.kts: AGP 9.3.1 lint crashes on
        // :image_picker_android during release builds.
        checkReleaseBuilds = false
    }

    // Add compiler arguments to show deprecation details and suppress obsolete warnings
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf(
            "-Xlint:deprecation",
            "-Xlint:-options"
        ))
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Optional but recommended: use Firebase BoM to manage Firebase SDK versions
    implementation(platform("com.google.firebase:firebase-bom:33.7.0")) // ✅ Aligned with firebase_storage 13.x
    implementation("com.google.firebase:firebase-analytics") // ✅ Add any Firebase services you use
}
