allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Cambiamos la ubicación del build para evitar problemas de permisos y rutas largas
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Los plugins necesitan que la app se configure antes (como en la plantilla de Flutter)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}