# Google ML Kit - OCR text recognition (all scripts)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ML Kit text recognition models (Chinese/Japanese/Korean/Devanagari)
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Flutter plugin bridge
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google_mlkit_text_recognition.**

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# General: keep Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
