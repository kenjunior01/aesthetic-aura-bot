import java.util.Properties

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
        // Universal: SEM abiFilters por omissão — o APK leva todos os ABIs
        // (arm64-v8a, armeabi-v7a, x86, x86_64). Um APK arm64-only devolve
        // "App não instalado" em dispositivos 32-bit.
        //
        // Para builds honestos por ABI (cada APK declara só os ABIs que
        // REALMENTE contém — evita "instala e quebra" de ABIs fantasmas):
        //   flutter build apk --release --target-platform android-arm64 \
        //       -Pabi=arm64-v8a
        // Aceita também LISTA separada por vírgulas — o APK de telemóvel
        // (arm64-v8a + armeabi-v7a num só ficheiro, qualquer dispositivo real):
        //   flutter build apk --release \
        //       --target-platform android-arm64,android-arm \
        //       -Pabi=arm64-v8a,armeabi-v7a
        val abiFilter = (project.findProperty("abi") as String?)
            ?.split(',')?.map { it.trim() }?.filter { it.isNotEmpty() }
        if (!abiFilter.isNullOrEmpty()) {
            ndk { abiFilters += abiFilter }
        }
    }

    // O stub libdatastore_shared_counter.so (datastore/shared_preferences)
    // VAZA pelo ndk.abiFilters — entra no APK em ABIs que não o alvo, e um
    // telemóvel desse ABI instalava e QUEBRAVA no arranque (sem libflutter).
    // Exclui, no packaging, todo o diretório lib/<abi> que não seja o alvo.
    val abiTarget = (project.findProperty("abi") as String?)
        ?.split(',')?.map { it.trim() }?.filter { it.isNotEmpty() }
    if (!abiTarget.isNullOrEmpty()) {
        val todosAbis = listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        packagingOptions {
            jniLibs {
                excludes += todosAbis.filter { it !in abiTarget }.map { "lib/$it/**" }
            }
        }
    }

    // ── Assinatura release PERSISTENTE ────────────────────────────────────
    // A chave vive no repo (mobile/android/aura-release.jks + keystore.
    // properties) para que TODOS os builds — em qualquer máquina/sandbox —
    // assinem igual e cada atualização instale sobre a anterior. Sem isto,
    // o release assinava com a debug key efémera do ambiente e o Android
    // bloqueava o upgrade com "App não instalado".
    // Tradeoff assumido (app de estudo): chave e password são públicas.
    val keystoreProps = Properties()
    val keystorePropsFile = rootProject.file("keystore.properties")
    val hasReleaseKey = keystorePropsFile.exists()
    if (hasReleaseKey) {
        keystorePropsFile.inputStream().use { keystoreProps.load(it) }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // R8 desligado: no ambiente de build (4 GB RAM) o minify estoura
            // a memória — e o APK fica ~1 MB maior, sem perda de função.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Fallback: sem keystore no repo (ex.: fork sem as chaves),
                // assina com a debug key para `flutter run --release` funcionar.
                signingConfigs.getByName("debug")
            }
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
