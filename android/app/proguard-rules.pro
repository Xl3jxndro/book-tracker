# -------------------------------------------------------------------------
# REGLAS DE PROGUARD PARA BOOK TRACKER
# -------------------------------------------------------------------------

# 1. PROTECCIÓN DEL MOTOR DE FLUTTER Y PLUGINS
# Evita que R8 elimine o renombre clases críticas del framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# 2. PROTECCIÓN DE TU LÓGICA DE NEGOCIO (¡CRÍTICO PARA STATS!)
# Sustituye 'com.jabc.booktracker' por el package name real de tu app si es distinto.
# Esto evita que se ofusquen tus modelos (Book, ReadingSession) y se rompa la DB.
-keep class com.jabc.booktracker.** { *; }

# 3. GOOGLE MOBILE ADS (ADMOD)
# Reglas necesarias para que los anuncios y tu Native Ad Factory funcionen
-keep class com.jabc.booktracker.ListTileNativeAdFactory { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# 4. PERSISTENCIA Y SERIALIZACIÓN (SQLite / Drift / Riverpod)
# Mantiene las anotaciones y firmas necesarias para la inyección de dependencias
-keepattributes *Annotation*,Signature,EnclosingMethod,InnerClasses
-keep class androidx.sqlite.db.** { *; }
-dontwarn androidx.sqlite.db.**

# 5. MANEJO DE ADVERTENCIAS AUTOMÁTICAS
# Evita errores de compilación por librerías que referencian clases inexistentes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# 6. REGLAS PARA TUTORIAL COACH MARK Y UI
# Mantiene los nombres de los widgets para que las GlobalKeys funcionen
-keepnames class * extends android.view.View
-keepnames class * extends android.app.Activity