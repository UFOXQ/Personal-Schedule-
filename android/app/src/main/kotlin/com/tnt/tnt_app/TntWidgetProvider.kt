package com.tnt.tnt_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 桌面小组件：把「今天还剩哪些方块」画成一张深色卡片。
 *
 * 数据由 Dart 侧 `HomeWidgetBridge` 通过 HomeWidget 写入 SharedPreferences，
 * 键名见 `lib/platform/widgets/home_widget_bridge.dart`（tnt_widget_title / tnt_widget_body）。
 */
class TntWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("tnt_widget_title", "TNT") ?: "TNT"
        val body = widgetData.getString("tnt_widget_body", "今天还没排东西") ?: "今天还没排东西"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.tnt_widget)
            views.setTextViewText(R.id.tnt_widget_title, title)
            views.setTextViewText(R.id.tnt_widget_body, body)

            // 整张卡片可点，点开回到 app
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.tnt_widget_root, pending)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
