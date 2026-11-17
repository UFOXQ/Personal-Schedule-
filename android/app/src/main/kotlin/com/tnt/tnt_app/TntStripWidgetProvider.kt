package com.tnt.tnt_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * 4x1 桌面小组件：显示 Dart 侧画好的「地铁线路图」式时间条位图。
 *
 * 图由 `StripController` 画好（RGBA 字节 -> base64）写进 HomeWidget 偏好，
 * 这里只负责解码成 Bitmap 贴到 RemoteViews 上。
 */
class TntStripWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val bitmap = decodeBitmap(widgetData)
        val fallbackSummary = runCatching {
            widgetData.getString("tnt_strip_payload", null)?.let {
                buildStripSummary(JSONObject(it), currentMinute(JSONObject(it)))
            }
        }.getOrNull()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.tnt_strip_widget)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.tnt_strip_widget_bar, bitmap)
            } else {
                views.setImageViewResource(
                    R.id.tnt_strip_widget_bar,
                    R.drawable.ic_stat_tnt,
                )
            }
            views.setContentDescription(
                R.id.tnt_strip_widget_bar,
                fallbackSummary ?: context.getString(R.string.tnt_strip_widget_description),
            )

            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.tnt_strip_widget_root, pending)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun decodeBitmap(widgetData: SharedPreferences): Bitmap? {
        val encoded = widgetData.getString("tnt_strip_png", null) ?: return null
        return runCatching {
            val png = Base64.decode(encoded, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(png, 0, png.size)
        }.getOrNull()
    }

    private fun currentMinute(data: JSONObject): Int =
        data.optInt("now", java.util.Calendar.getInstance().let {
            it.get(java.util.Calendar.HOUR_OF_DAY) * 60 + it.get(java.util.Calendar.MINUTE)
        })
}
