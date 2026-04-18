plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.kotlinSerialization)
    alias(libs.plugins.sqldelight)
}

kotlin {
    androidTarget()
    jvm()

    sourceSets {
        commonMain.dependencies {
            api(projects.shared.domain)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.datetime)
            implementation(libs.koin.core)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
            implementation(libs.sqldelight.android.driver)
        }
        jvmMain.dependencies {
            implementation(libs.ktor.client.cio)
            implementation(libs.sqldelight.sqlite.driver)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.serialization.json)
        }
    }
}

sqldelight {
    databases {
        create("BfmDatabase") {
            packageName.set("me.amermahsoub.bfm.shared.data.db")
        }
    }
}

android {
    namespace = "me.amermahsoub.bfm.shared.data"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.android.minSdk.get().toInt()
    }
}
