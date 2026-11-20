# -------------------------------------------------------------------------
# Reglas de R8 para Book Tracker (solo en release)
#
# La mayoría de librerías traen sus propias reglas (Google Mobile Ads,
# Play Billing, ML Kit, AndroidX) y el plugin de Flutter añade las del motor.
# Aquí solo va lo que no está cubierto. El mapa de desofuscación
# (mapping.txt) viaja dentro del AAB y Play Console lo usa automáticamente.
# -------------------------------------------------------------------------

# Código propio de la app: MainActivity, widget y fábrica de anuncios nativos
# (se registran por nombre desde Flutter y el manifest).
-keep class com.jabc.booktracker.** { *; }

# flutter_local_notifications guarda las notificaciones programadas con Gson
# (sin estas reglas, tras reiniciar el teléfono no se reprograman).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# home_widget: receptor y servicio de las acciones del widget en segundo plano.
-keep class es.antonborri.home_widget.** { *; }

# Componentes diferidos de Flutter que la app no usa (Play Core no se incluye).
-dontwarn com.google.android.play.core.**

# Números de línea en los informes de fallos de Play Console.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
