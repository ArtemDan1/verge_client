import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Ключ подписи релиза. APK раздаётся не через Google Play, поэтому обновление
// поверх установленной версии пройдёт, только если обе подписаны одним и тем
// же ключом. Ключ лежит вне репозитория: локально — в android/key.properties,
// в CI его собирает workflow из секретов (см. docs/ANDROID.md). Без ключа
// релиз подписывается debug-ключом — такой APK годится для проверки, но
// обновить им чужую установку нельзя.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.singboxclient.verge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Не менять: по applicationId Android узнаёт приложение при обновлении.
        applicationId = "com.singboxclient.verge"
        // 26 (Android 8): каналы уведомлений и foreground-сервис VPN без
        // обходных путей для старых версий.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            // Xray запускается отдельным процессом из nativeLibraryDir
            // (libxray.so — это исполняемый файл, а не библиотека). Для этого
            // .so должны лежать распакованными на диске, а не внутри APK.
            useLegacyPackaging = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // sing-box как библиотека (gomobile). AAR в репозитории нет — его собирает
    // scripts/android/build_libbox.sh (локально и в CI).
    implementation(files("libs/libbox.aar"))
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
