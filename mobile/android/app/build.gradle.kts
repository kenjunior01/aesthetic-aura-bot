plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aurastyle.aurastyle_mobile"
    // NDK não é necessário: app puro Dart/Kotlin (sem C++). Removido
    // flutter.ndkVersion para não forçar o download de ~3GB.
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications exige java.time nas APIs < 26:
        // core library desugaring (desugar_jdk_libs via AGP).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aurastyle.aurastyle_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Entrega arm64-only: a fusão de nativas só processa arm64-v8a
        // (os AAR dos plugins trazem 4 ABIs — ~4× o espaço no merge).
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            // R8 desligado: no ambiente de build (4 GB RAM) o minify estoura
            // a memória — e o APK fica ~1 MB maior, sem perda de função.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// O NDK aqui é um esqueleto (source.properties + llvm-strip shim para o
// binutils-aarch64 do apt — 9 KB em vez de ~2,5 GB): nenhuma dependência
// compila C++. A extração de tabelas de símbolos (objcopy) não existe no
// esqueleto e não serve para nada em produção — desligada.
tasks.whenTaskAdded {
    if (name.equals("extractReleaseNativeSymbolTables", ignoreCase = true)) {
        enabled = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
