package com.personalapp.personal_finance

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertsChannel()
    }

    /**
     * Kênh thông báo "alerts" cho cảnh báo chi tiêu (FCM gửi kèm channel_id = alerts;
     * manifest đặt làm kênh mặc định). Tạo lại nhiều lần không sao: Android giữ cài đặt người dùng.
     */
    private fun createAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel =
            NotificationChannel(ALERTS_CHANNEL_ID, "Cảnh báo chi tiêu", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Cảnh báo quan trọng về số dư và mục tiêu chi tiêu"
            }
        manager.createNotificationChannel(channel)
    }

    private companion object {
        const val ALERTS_CHANNEL_ID = "alerts"
    }
}
