package com.jabc.booktracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.net.Uri
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget de pantalla de inicio. Solo dibuja: los datos los escribe Flutter
 * (lib/services/home_widget_sync.dart) y las claves deben coincidir.
 */
class BookTrackerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.book_tracker_widget)
            bind(context, views, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bind(context: Context, views: RemoteViews, data: SharedPreferences) {
        val bookId = data.getString("bookId", null)
        val bookTitle = data.getString("bookTitle", null)

        if (bookId.isNullOrEmpty() || bookTitle.isNullOrEmpty()) {
            // Sin libros: mensaje y tocar abre la app
            views.setTextViewText(R.id.widget_empty_title, label(data, "label_empty_title", "Añade tu primer libro"))
            views.setTextViewText(R.id.widget_empty_subtitle, label(data, "label_empty_subtitle", "Toca para empezar"))
            views.setViewVisibility(R.id.widget_no_book_section, View.VISIBLE)
            views.setViewVisibility(R.id.widget_cover, View.GONE)
            views.setViewVisibility(R.id.widget_content_section, View.GONE)
            views.setImageViewBitmap(R.id.widget_ambient, null)
            views.setOnClickPendingIntent(R.id.widget_main_layout, launch(context, "home", null))
            return
        }

        views.setViewVisibility(R.id.widget_no_book_section, View.GONE)
        views.setViewVisibility(R.id.widget_cover, View.VISIBLE)
        views.setViewVisibility(R.id.widget_content_section, View.VISIBLE)

        // --- Portada y fondo ambiental ---
        views.setContentDescription(R.id.widget_cover, label(data, "label_cover", "Portada"))
        val art = CoverArt.load(context, data.getString("bookCover", null))
        if (art != null) {
            views.setImageViewBitmap(R.id.widget_cover, art.thumbnail)
            views.setImageViewBitmap(R.id.widget_ambient, art.ambient)
        } else {
            views.setImageViewResource(R.id.widget_cover, R.drawable.widget_cover_placeholder)
            views.setImageViewBitmap(R.id.widget_ambient, null) // se ve el degradado de la app
        }

        // --- Libro y progreso ---
        val progress = data.getString("bookProgress", "0")?.toIntOrNull()?.coerceIn(0, 100) ?: 0
        views.setTextViewText(R.id.widget_book_title, bookTitle)
        views.setTextViewText(R.id.widget_book_author, data.getString("bookAuthor", "") ?: "")
        views.setProgressBar(R.id.widget_progress_bar, 100, progress, false)
        val pages = data.getString("pagesInfo", "") ?: ""
        views.setTextViewText(R.id.widget_pages_info, if (pages.isEmpty()) "$progress%" else "$progress% · $pages")

        // Minutos de hoy: si los datos son de otro día, hoy aún no se ha leído
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val todayMinutes = if (data.getString("todayDate", null) == today) {
            data.getString("todayMinutes", "0") ?: "0"
        } else "0"
        val goal = data.getString("dailyGoalMinutes", null)
        // Plantillas en el idioma de la app ({m} = minutos de hoy, {g} = meta)
        views.setTextViewText(
            R.id.widget_today_session,
            if (goal.isNullOrEmpty()) {
                label(data, "label_today", "Hoy {m} min").replace("{m}", todayMinutes)
            } else {
                label(data, "label_today_goal", "Hoy {m}/{g} min").replace("{m}", todayMinutes).replace("{g}", goal)
            }
        )

        // --- Sesión (cronómetro) ---
        val sessionState = data.getString("sessionState", "none") ?: "none"
        val sessionBookId = data.getString("sessionBookId", null)
        val hasSession = sessionState != "none" && sessionBookId == bookId

        // Con sesión, el cronómetro y los botones ocupan el lugar del autor y
        // de la fila de páginas, para que todo quepa en un widget de 2 filas
        val detail = if (hasSession) View.GONE else View.VISIBLE
        views.setViewVisibility(R.id.widget_book_author, detail)
        views.setViewVisibility(R.id.widget_pages_row, detail)
        views.setInt(R.id.widget_book_title, "setMaxLines", if (hasSession) 1 else 2)

        if (hasSession) {
            val isRunning = sessionState == "running"
            val accumulatedMs = data.getString("sessionAccumulatedMs", "0")?.toLongOrNull() ?: 0L
            val runningSinceMs = data.getString("sessionRunningSinceMs", "0")?.toLongOrNull() ?: 0L
            val runningMs = if (isRunning && runningSinceMs > 0) {
                (System.currentTimeMillis() - runningSinceMs).coerceAtLeast(0L)
            } else 0L
            val base = SystemClock.elapsedRealtime() - (accumulatedMs + runningMs)

            views.setViewVisibility(R.id.widget_session_section, View.VISIBLE)
            views.setChronometer(R.id.widget_chronometer, base, null, isRunning)
            views.setTextViewText(
                R.id.widget_session_label,
                if (isRunning) label(data, "label_reading", "LEYENDO") else label(data, "label_paused", "EN PAUSA")
            )
            views.setImageViewResource(
                R.id.widget_pause_button,
                if (isRunning) R.drawable.widget_ic_pause else R.drawable.widget_ic_play
            )
            views.setContentDescription(
                R.id.widget_pause_button,
                if (isRunning) label(data, "label_pause", "Pausar") else label(data, "label_resume", "Reanudar")
            )
            views.setTextViewText(R.id.widget_finish_button, label(data, "label_finish", "Finalizar"))
            views.setContentDescription(
                R.id.widget_finish_button,
                label(data, "label_finish_description", "Finalizar la sesión")
            )

            // Pausar/reanudar sin abrir la app (callback de Dart en segundo plano)
            views.setOnClickPendingIntent(
                R.id.widget_pause_button,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("booktracker://toggle_pause"))
            )
            // Finalizar: abre la app en el libro con el diálogo de páginas
            views.setOnClickPendingIntent(
                R.id.widget_finish_button,
                launch(context, "finish_session", bookId)
            )
        } else {
            views.setViewVisibility(R.id.widget_session_section, View.GONE)
        }

        // Tocar el widget abre el libro
        views.setOnClickPendingIntent(R.id.widget_main_layout, launch(context, "open_book", bookId))
    }

    /** Texto en el idioma de la app (lo escribe Flutter); si falta, el español. */
    private fun label(data: SharedPreferences, key: String, fallback: String): String {
        val value = data.getString(key, null)
        return if (value.isNullOrEmpty()) fallback else value
    }

    private fun launch(context: Context, host: String, bookId: String?) =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(if (bookId == null) "booktracker://$host" else "booktracker://$host?bookId=$bookId")
        )
}

/**
 * Imágenes del widget a partir de la portada: la miniatura (esquinas
 * redondeadas) y el fondo ambiental (la portada reducida, difuminada y
 * oscurecida). Se guardan en memoria mientras la portada no cambie.
 */
private class CoverArt(val thumbnail: Bitmap, val ambient: Bitmap) {
    companion object {
        private const val TAG = "BookTrackerWidget"
        private var cacheKey: String? = null
        private var cached: CoverArt? = null

        fun load(context: Context, path: String?): CoverArt? {
            if (path.isNullOrEmpty()) return null
            val file = File(path)
            if (!file.exists()) return null
            val key = "$path:${file.lastModified()}"
            if (key == cacheKey) return cached

            return try {
                val source = decodeSampled(file, 360) ?: return null
                val density = context.resources.displayMetrics.density
                val art = CoverArt(
                    thumbnail = roundedThumbnail(source, (60 * density).toInt(), (90 * density).toInt(), 8 * density),
                    ambient = ambient(source),
                )
                if (source != art.thumbnail) source.recycle()
                cacheKey = key
                cached = art
                art
            } catch (e: Throwable) {
                Log.w(TAG, "No se pudo preparar la portada del widget", e)
                null
            }
        }

        /** Decodifica reduciendo para no cargar fotos enteras en memoria. */
        private fun decodeSampled(file: File, maxSide: Int): Bitmap? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= maxSide || bounds.outHeight / (sample * 2) >= maxSide) sample *= 2
            return BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
        }

        /** Recorta al formato de portada (2:3) y redondea las esquinas. */
        private fun roundedThumbnail(src: Bitmap, width: Int, height: Int, radius: Float): Bitmap {
            val scale = maxOf(width / src.width.toFloat(), height / src.height.toFloat())
            val scaledW = (src.width * scale).toInt().coerceAtLeast(width)
            val scaledH = (src.height * scale).toInt().coerceAtLeast(height)
            val scaled = Bitmap.createScaledBitmap(src, scaledW, scaledH, true)

            val out = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radius, radius, paint)
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            canvas.drawBitmap(scaled, (width - scaledW) / 2f, (height - scaledH) / 2f, paint)
            if (scaled != src) scaled.recycle()
            return out
        }

        /**
         * Fondo ambiental: la portada a 40×40 px, difuminada (desenfoque de
         * caja en 3 pasadas), más saturada y oscura. El ImageView la amplía
         * con filtrado, lo que suaviza aún más el resultado.
         */
        private fun ambient(src: Bitmap): Bitmap {
            val size = 40
            val small = Bitmap.createScaledBitmap(src, size, size, true)
            val pixels = IntArray(size * size)
            small.getPixels(pixels, 0, size, 0, 0, size, size)
            repeat(3) { boxBlur(pixels, size, size, 3) }

            val blurred = Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888)
            val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val matrix = ColorMatrix().apply { setSaturation(1.35f) }
            matrix.postConcat(ColorMatrix(floatArrayOf(
                0.62f, 0f, 0f, 0f, 0f,
                0f, 0.62f, 0f, 0f, 0f,
                0f, 0f, 0.62f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f,
            )))
            Canvas(out).drawBitmap(blurred, 0f, 0f, Paint().apply { colorFilter = ColorMatrixColorFilter(matrix) })
            small.recycle()
            blurred.recycle()
            return out
        }

        /** Desenfoque de caja separable (horizontal + vertical), en el sitio. */
        private fun boxBlur(px: IntArray, w: Int, h: Int, r: Int) {
            val tmp = IntArray(px.size)
            fun pass(src: IntArray, dst: IntArray, horizontal: Boolean) {
                val outer = if (horizontal) h else w
                val inner = if (horizontal) w else h
                for (o in 0 until outer) {
                    for (i in 0 until inner) {
                        var a = 0; var red = 0; var g = 0; var b = 0; var n = 0
                        for (k in -r..r) {
                            val j = (i + k).coerceIn(0, inner - 1)
                            val c = if (horizontal) src[o * w + j] else src[j * w + o]
                            a += c ushr 24; red += (c shr 16) and 0xFF; g += (c shr 8) and 0xFF; b += c and 0xFF; n++
                        }
                        val idx = if (horizontal) o * w + i else i * w + o
                        dst[idx] = ((a / n) shl 24) or ((red / n) shl 16) or ((g / n) shl 8) or (b / n)
                    }
                }
            }
            pass(px, tmp, horizontal = true)
            pass(tmp, px, horizontal = false)
        }
    }
}
