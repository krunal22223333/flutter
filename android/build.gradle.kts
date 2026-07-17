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

// Force Android plugin (library) modules to compile against SDK 36.
// flutter_plugin_android_lifecycle 2.0.32+ requires compileSdk 36; Flutter injects
// flutter.compileSdkVersion into plugin subprojects, so we override it after they evaluate.
// The state.executed guard avoids "afterEvaluate on an already-evaluated project", which the
// evaluationDependsOn(":app") block above can trigger by force-evaluating :app early.
subprojects {
    val forcePluginCompileSdk: () -> Unit = {
        if (plugins.hasPlugin("com.android.library")) {
            val ext = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            ext?.compileSdkVersion(36)
        }
    }
    if (state.executed) {
        forcePluginCompileSdk()
    } else {
        afterEvaluate { forcePluginCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


