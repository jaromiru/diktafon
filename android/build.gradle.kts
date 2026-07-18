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

// Reproducible builds: plugin-built native libs (package:jni's libdartjni.so)
// otherwise differ across build machines by their ELF build-id alone — the
// linker hashes debug info full of machine-specific paths (NDK install dir,
// pub cache), and the note survives stripping. The NDK toolchain composes
// CMAKE_SHARED_LINKER_FLAGS as "<android flags> <user value>", so this lands
// after the NDK's own -Wl,--build-id=sha1 and wins without dropping its
// defaults. Our own engine libs get the same treatment in native/CMakeLists.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
            defaultConfig.externalNativeBuild.cmake.arguments +=
                "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--build-id=none"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
