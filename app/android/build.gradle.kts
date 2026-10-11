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
// Plugin lama (mis. flutter_native_splash 2.4.4) masih compileSdk 31,
// padahal library AndroidX yang ikut dipakai butuh minimal 34. compileSdk
// hanya SDK untuk kompilasi; minSdk/targetSdk app tidak berubah.
// Harus sebelum evaluationDependsOn di bawah supaya afterEvaluate sempat
// didaftarkan.
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.let { android ->
            if ((android.compileSdk ?: 0) < 34) android.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
