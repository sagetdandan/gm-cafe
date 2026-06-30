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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Fix for AGP 8.6.0+ namespace requirement
subprojects {
    plugins.whenPluginAdded {
        if (this.javaClass.name.contains("com.android.build.gradle.LibraryPlugin") ||
            this.javaClass.name.contains("com.android.build.gradle.AppPlugin")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                if (namespace == null) {
                    namespace = when (project.name) {
                        "blue_thermal_printer" -> "id.kakzaki.blue_thermal_printer"
                        "permission_handler_android" -> "com.baseflow.permissionhandler"
                        "shared_preferences_android" -> "io.flutter.plugins.sharedpreferences"
                        "image_picker_android" -> "io.flutter.plugins.imagepicker"
                        else -> "com.saget.kasir.${project.name.replace("-", "_")}"
                    }
                }
            }
        }
    }
}
