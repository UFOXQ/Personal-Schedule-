package com.tnt.tnt_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.widget.RemoteViews
import org.json.JSONObject
import kotlin.math.max

/**
 * 把当天的时间轴做成一条常驻通知：
 * - 通知里画一条「从 00:00 到 24:00」的横条，方块按优先级上色
 * - 一根红线表示「现在」，每分钟自己往前走
 * - 正在做的事写在下方的文字里
 *
 * 用前台服务是为了：应用退到后台、锁屏后通知还在，而且能被系统允许持续更新。
 */
class TimelineStripService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var payload: JSONObject? = null
    private var stripPng: ByteArray? = null

    private val ticker = object : Runnable {
        override fun run() {
            val current = payload
            if (current != null) {
                showNotification(current)
                handler.postDelayed(this, 30_000L)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                handler.removeCallbacks(ticker)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_UPDATE -> {
                val raw = intent.getStringExtra(EXTRA_PAYLOAD)
                if (raw != null) {
                    payload = runCatching { JSONObject(raw) }.getOrNull()
                }
                val png = intent.getByteArrayExtra(EXTRA_PNG)
                if (png != null) stripPng = png
                val current = payload
                if (current == null) {
                    handler.removeCallbacks(ticker)
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                    return START_NOT_STICKY
                }
                showNotification(current)
                handler.removeCallbacks(ticker)
                handler.postDelayed(ticker, 30_000L)
                return START_STICKY
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(ticker)
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "时间条",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "常驻显示今天的时间轴和当前时间"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun showNotification(data: JSONObject) {
        val nowMinute = currentMinute()
        val summary = buildStripSummary(data, nowMinute)
        val bitmap = stripPng?.let { decodeStripPng(it) }
            ?: TimelineStripRenderer.render(data, nowMinute)

        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_tnt)
            .setContentTitle("TNT · 今天")
            .setContentText(summary)
            // 用 BigPicture 而不是自定义 View：自定义大图会把动作按钮那一行挤掉
            .setStyle(
                Notification.BigPictureStyle()
                    .bigPicture(bitmap)
                    .setSummaryText(summary),
            )
            .setContentIntent(open)
            .addAction(
                0,
                "快速记一条",
                PendingIntent.getActivity(
                    this,
                    1,
                    Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("tnt_action", "quickadd")
                    },
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_STATUS)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun currentMinute(): Int {
        val now = java.util.Calendar.getInstance()
        return now.get(java.util.Calendar.HOUR_OF_DAY) * 60 +
            now.get(java.util.Calendar.MINUTE)
    }

    companion object {
        private const val CHANNEL_ID = "tnt_time_strip"
        private const val NOTIFICATION_ID = 0x54535132 // "TSQ2"
        private const val ACTION_UPDATE = "com.tnt.tnt_app.strip.UPDATE"
        private const val ACTION_STOP = "com.tnt.tnt_app.strip.STOP"
        private const val EXTRA_PAYLOAD = "payload"
        private const val EXTRA_PNG = "png"

        fun update(context: Context, payload: String, png: ByteArray? = null) {
            val intent = Intent(context, TimelineStripService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_PAYLOAD, payload)
                if (png != null) putExtra(EXTRA_PNG, png)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, TimelineStripService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}

/** 把时间轴画成一张位图（通知里只能放位图/RemoteViews，不能自己画） */
object TimelineStripRenderer {

    private const val WIDTH = 900
    private const val HEIGHT = 132
    private const val PADDING = 10f

    fun render(data: JSONObject, nowMinute: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(WIDTH, HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#151821")
        }
        val rect = RectF(PADDING, PADDING, WIDTH - PADDING, HEIGHT - PADDING)
        canvas.drawRoundRect(rect, 16f, 16f, background)

        // 每 3 小时的刻度
        val tick = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#242938")
            strokeWidth = 1.5f
        }
        for (hour in 3 until 24 step 3) {
            val x = PADDING + rect.width() * hour / 24f
            canvas.drawLine(x, PADDING + 8f, x, HEIGHT - PADDING - 8f, tick)
        }

        val segments = data.optJSONArray("segments")
        if (segments != null) {
            for (i in 0 until segments.length()) {
                val segment = segments.optJSONObject(i) ?: continue
                val start = segment.optInt("start").coerceIn(0, 1440)
                val duration = max(1, segment.optInt("duration"))
                val left = PADDING + rect.width() * start / 1440f
                val right = PADDING + rect.width() * (start + duration).coerceIn(0, 1440) / 1440f
                val width = max(6f, right - left)

                val top = HEIGHT * 0.34f
                val bottom = HEIGHT * 0.72f
                val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = segment.optInt("color", Color.GRAY.toInt())
                    alpha = 210
                }
                val block = RectF(left, top, left + width, bottom)
                canvas.drawRoundRect(block, 7f, 7f, fill)

                // 左边一条更亮的高亮条，和 App 里的观感一致
                val accent = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = segment.optInt("color", Color.GRAY.toInt())
                }
                canvas.drawRoundRect(
                    RectF(left, top, left + 4f, bottom),
                    3f,
                    3f,
                    accent,
                )

                if (segment.optBoolean("top", false)) {
                    val border = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        style = Paint.Style.STROKE
                        strokeWidth = 2.5f
                        color = Color.parseColor("#FF3B30")
                    }
                    canvas.drawRoundRect(block, 7f, 7f, border)
                }
            }
        }

        // 现在：红竖线 + 顶部小红点
        val nowX = PADDING + rect.width() * (nowMinute.coerceIn(0, 1440)) / 1440f
        val nowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#FF3B30")
            strokeWidth = 3f
        }
        canvas.drawLine(nowX, PADDING + 4f, nowX, HEIGHT - PADDING - 4f, nowPaint)
        canvas.drawCircle(nowX, PADDING + 5f, 6f, nowPaint)
        return bitmap
    }
}

fun buildStripSummary(data: JSONObject, nowMinute: Int): String {
    val segments = data.optJSONArray("segments") ?: return "今天还没有安排"
    var current: JSONObject? = null
    var next: JSONObject? = null
    for (i in 0 until segments.length()) {
        val segment = segments.optJSONObject(i) ?: continue
        val start = segment.optInt("start")
        val duration = max(1, segment.optInt("duration"))
        if (nowMinute in start until (start + duration)) {
            current = segment
            break
        }
        if (start > nowMinute && next == null) next = segment
    }
    val segment = current ?: next
    if (segment == null) return "今天剩下的都做完了"
    val start = segment.optInt("start")
    val title = segment.optString("title")
    val prefix = if (current != null) "现在" else "接下来"
    return "$prefix ${stripClock(start)} · $title"
}

fun stripClock(minute: Int): String {
    val h = (minute / 60) % 24
    val m = minute % 60
    return String.format("%02d:%02d", h, m)
}

/** Dart 侧画好的 PNG 解码成 Bitmap：三端共用一份绘制 */
fun decodeStripPng(png: ByteArray): Bitmap? =
    runCatching { BitmapFactory.decodeByteArray(png, 0, png.size) }.getOrNull()
