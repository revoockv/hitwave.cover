pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// Embedded Python (serious_python): a plain `flutter run` or an IDE run gets what
// tool/flutter_python.sh gives — the Python app is packaged when its sources changed, and the
// plugin's build script (which reads only environment variables) finds the packaged folders.
run {
    val projectRoot = rootDir.parentFile
    val python = File(projectRoot, "build/python/android")
    val packaging = ProcessBuilder("bash", File(projectRoot, "tool/package_python.sh").path, "android")
        .directory(projectRoot)
        .inheritIO()
        .start()
    check(packaging.waitFor() == 0) { "Packaging the embedded Python app failed (tool/package_python.sh android)" }

    val defaults = mapOf(
        "SERIOUS_PYTHON_VERSION" to "3.14",
        "SERIOUS_PYTHON_SITE_PACKAGES" to File(python, "site-packages").path,
        "SERIOUS_PYTHON_APP" to File(python, "app").path,
    ).filterKeys { System.getenv(it).isNullOrEmpty() }
    if (defaults.isNotEmpty()) {
        // System.getenv() is Gradle's input-tracking wrapper ("delegate") around the JDK's
        // read-only view ("m") of the JVM's mutable environment map; Gradle opens java.util to
        // build scripts. Only these two known wrappers are unwrapped.
        var environment: Any = System.getenv()
        for (fieldName in listOf("delegate", "m")) {
            val field = environment.javaClass.declaredFields.firstOrNull { it.name == fieldName } ?: continue
            field.isAccessible = true
            environment = field.get(environment)
        }
        @Suppress("UNCHECKED_CAST")
        (environment as MutableMap<String, String>).putAll(defaults)
    }
}
