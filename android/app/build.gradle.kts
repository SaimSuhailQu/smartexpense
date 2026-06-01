plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase plugin
    id("com.google.android.gms.strict-version-matcher-plugin")
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

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
            storeFile = file("smartexpense.jks")
            storePassword = "Prex1211"
            keyAlias = "smartexpense"
            keyPassword = "Prex1211"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Add compiler arguments to show deprecation details and suppress obsolete warnings
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf(
            "-Xlint:deprecation",
            "-Xlint:-options"
        ))
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
