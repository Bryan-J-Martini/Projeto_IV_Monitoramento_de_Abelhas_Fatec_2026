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

    // Força o Java 17 e o Kotlin 17 em qualquer subprojeto/plugin (incluindo o tflite_flutter)
    afterEvaluate {
        extensions.findByName("android")?.let { androidExtension ->
            try {
                val compileOptionsMethod = androidExtension.javaClass.getMethod("getCompileOptions")
                val compileOptions = compileOptionsMethod.invoke(androidExtension)
                val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                setSource.invoke(compileOptions, JavaVersion.VERSION_17)
                setTarget.invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // Ignora se o extensão não possuir a propriedade android padrão
            }
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}