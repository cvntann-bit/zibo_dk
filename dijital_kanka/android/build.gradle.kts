allprojects {
    repositories {
        google()
        mavenCentral()
        // TikTok Business SDK (kurulum/olay takibi, bkz. app/build.gradle.kts)
        // JitPack üzerinden dağıtılıyor — resmi Maven Central/Google
        // deposunda YOK.
        maven { url = uri("https://jitpack.io") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
