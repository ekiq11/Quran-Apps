// android/app/build.gradle - FIXED v2.0 WITH DESUGARING

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    namespace "com.yourcompany.myquran" // ⭐ GANTI dengan package name Anda
    
    // ⭐ CRITICAL: SDK version untuk notification features
    compileSdkVersion 34 // Minimal 33 untuk POST_NOTIFICATIONS
    ndkVersion flutter.ndkVersion

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ⭐ CRITICAL FIX #3: DESUGARING ENABLED
    // Required for Android 14+ scheduled notifications
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    compileOptions {
        coreLibraryDesugaringEnabled true  // ⭐ CRITICAL!
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.yourcompany.myquran" // ⭐ GANTI dengan package name Anda
        
        // ⭐ CRITICAL: Min SDK 21 untuk notification features
        minSdkVersion 21
        
        // ⭐ CRITICAL: Target SDK 34 untuk latest notification features
        targetSdkVersion 34
        
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // ⭐ MultiDex support (jika app besar)
        multiDexEnabled true
    }

    buildTypes {
        release {
            // ⭐ Production settings
            signingConfig signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        
        debug {
            // ⭐ Debug settings
            applicationIdSuffix ".debug"
            versionNameSuffix "-DEBUG"
        }
    }
    
    // ⭐ Lint options untuk menghindari error
    lintOptions {
        disable 'InvalidPackage'
        checkReleaseBuilds false
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    
    // ⭐ AndroidX core libraries
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    
    // ⭐ CRITICAL: WorkManager untuk background tasks
    implementation 'androidx.work:work-runtime-ktx:2.9.0'
    
    // ⭐ MultiDex support
    implementation 'androidx.multidex:multidex:2.0.1'
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ⭐ CRITICAL FIX #3: DESUGARING + WINDOW DEPENDENCIES
    // Required for Android 14+ compatibility
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.2'
    implementation 'androidx.window:window:1.0.0'
    implementation 'androidx.window:window-java:1.0.0'
}