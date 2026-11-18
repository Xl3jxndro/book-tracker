package com.jabc.booktracker

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
// Desde google_mobile_ads 8 la interfaz es independiente (antes GoogleMobileAdsPlugin.NativeAdFactory)
import io.flutter.plugins.googlemobileads.NativeAdFactory

class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        // Inflamos el diseño XML que creaste en res/layout
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.list_tile_native_ad, null) as NativeAdView

        // 1. Título (Headline)
        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        // 2. Cuerpo/Descripción (Body)
        val body = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body == null) {
            body.visibility = View.INVISIBLE
        } else {
            body.visibility = View.VISIBLE
            body.text = nativeAd.body
        }
        adView.bodyView = body

        // 3. Imagen/Icono
        // Nota: Asegúrate de que en tu XML el ID sea 'ad_app_icon'
        val icon = adView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd.icon == null) {
            icon.visibility = View.GONE
        } else {
            icon.setImageDrawable(nativeAd.icon?.drawable)
            icon.visibility = View.VISIBLE
        }
        adView.iconView = icon

        // Muy importante: Registrar el objeto nativeAd en la vista
        adView.setNativeAd(nativeAd)

        return adView
    }
}