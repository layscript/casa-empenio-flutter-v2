# SDK del lector de huellas Suprema BioMini.
# Su código nativo (JNI) busca estas clases Java por su NOMBRE EXACTO
# (Java_com_biominiseries_..., Java_com_android_biomini_...). Si el compilador
# las renombra o las quita, la app se cierra al capturar la huella.
-keep class com.biominiseries.** { *; }
-keep class com.android.biomini.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class com.example.casa_empenio_pe.HuelleroChannel { *; }
-dontwarn com.biominiseries.**
-dontwarn com.android.biomini.**

# ML Kit (escáner de bienes): idiomas de texto que no usamos
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Avisos de movimientos (flutter_local_notifications)
-keep class com.dexterous.** { *; }
