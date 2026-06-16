import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

fun releaseSigningValue(propertyKey: String, envKey: String): String? {
    val localValue = releaseSigningProperties.getProperty(propertyKey)?.trim()
    if (!localValue.isNullOrEmpty()) {
        return localValue
    }
    val envValue = System.getenv(envKey)?.trim()
    return if (envValue.isNullOrEmpty()) null else envValue
}

android {
    namespace = "com.novelagent.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.novelagent.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseKeystoreFilePath = releaseSigningValue(
        "novel_agent_release_keystore_file",
        "NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_FILE",
    )
    val releaseKeystorePassword = releaseSigningValue(
        "novel_agent_release_keystore_password",
        "NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_PASSWORD",
    )
    val releaseKeyAlias = releaseSigningValue(
        "novel_agent_release_key_alias",
        "NOVEL_AGENT_ANDROID_RELEASE_KEY_ALIAS",
    )
    val releaseKeyPassword = releaseSigningValue(
        "novel_agent_release_key_password",
        "NOVEL_AGENT_ANDROID_RELEASE_KEY_PASSWORD",
    )
    val releaseSigningConfigured = listOf(
        releaseKeystoreFilePath,
        releaseKeystorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    ).all { !it.isNullOrEmpty() }
    val releaseKeystoreFile = releaseKeystoreFilePath?.let { rootProject.file(it) }

    signingConfigs {
        create("release") {
            if (releaseSigningConfigured) {
                storeFile = releaseKeystoreFile
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

if (
    gradle.startParameter.taskNames.any {
        it.contains("release", ignoreCase = true)
    } &&
        listOf(
            releaseSigningValue(
                "novel_agent_release_keystore_file",
                "NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_FILE",
            ),
            releaseSigningValue(
                "novel_agent_release_keystore_password",
                "NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_PASSWORD",
            ),
            releaseSigningValue(
                "novel_agent_release_key_alias",
                "NOVEL_AGENT_ANDROID_RELEASE_KEY_ALIAS",
            ),
            releaseSigningValue(
                "novel_agent_release_key_password",
                "NOVEL_AGENT_ANDROID_RELEASE_KEY_PASSWORD",
            ),
        ).any { it.isNullOrBlank() }
) {
    error(
        """
        Release signing is not configured.
        Set these keys in android/local.properties or the matching environment variables:
        - novel_agent_release_keystore_file / NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_FILE
        - novel_agent_release_keystore_password / NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_PASSWORD
        - novel_agent_release_key_alias / NOVEL_AGENT_ANDROID_RELEASE_KEY_ALIAS
        - novel_agent_release_key_password / NOVEL_AGENT_ANDROID_RELEASE_KEY_PASSWORD
        """.trimIndent(),
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
