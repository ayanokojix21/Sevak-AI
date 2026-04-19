# Flutter / Dart obfuscation rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Cloudinary
-keep class com.cloudinary.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Prevent stripping FCM service
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
