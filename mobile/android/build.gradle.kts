allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Distribuição arm64-v8a — plugins com código nativo (ex.: :jni) deixam de
// compilar CMake para as outras ABIs: build mais rápido e sem dependência
// dos sysroots que não usamos. O :app é regido pelos splits do Flutter.
// plugins.withId dispara na aplicação do plugin — seguro com evaluationDependsOn.
subprojects {
    plugins.withId("com.android.library") {
        val androidExt =
            extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        androidExt.defaultConfig.ndk.abiFilters.clear()
        androidExt.defaultConfig.ndk.abiFilters.add("arm64-v8a")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
