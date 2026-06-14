allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        @Suppress("DEPRECATION")
        jcenter()
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

subprojects {
    val configureNamespace = {
        val android = extensions.findByName("android")
        if (android != null) {
            val hasNamespace = try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val ns = getNamespace.invoke(android) as? String
                ns.isNullOrEmpty().not()
            } catch (e: Exception) {
                false
            }
            if (hasNamespace.not()) {
                val fallbackNamespace = when (project.name) {
                    "dji" -> "cloud.dragonx.plugin.flutter.dji"
                    else -> "com.example.${project.name.replace(Regex("[^a-zA-Z0-9]"), "")}"
                }
                try {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, fallbackNamespace)
                } catch (e: Exception) {
                    // Ignora silenciosamente se o método não existir
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}

subprojects {
    configurations.all {
        exclude(group = "com.mapbox.mapboxsdk")
    }

    tasks.withType<JavaCompile>().configureEach {
        options.isFork = true
        options.forkOptions.jvmArgs = (options.forkOptions.jvmArgs ?: mutableListOf()).apply {
            addAll(listOf(
                "--add-opens=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
                "--add-opens=jdk.compiler/com.sun.tools.javac.jvm=ALL-UNNAMED"
            ))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
