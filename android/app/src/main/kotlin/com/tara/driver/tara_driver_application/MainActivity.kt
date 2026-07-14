package com.tara.driver_application

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This ensures the channel is created as soon as the app starts
        createBookingNotificationChannel()
    }

    private fun createBookingNotificationChannel() {
        // Notification channels are only required for Android Oreo (8.0) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            // 1. Define the Channel ID (Must match the one in AndroidManifest.xml)
            val channelId = "booking_channel"
            val channelName = "Booking Notifications"

            // 2. Point to your specific sound file: res/raw/booking_sound.wav
            val soundUri = Uri.parse("android.resource://$packageName/${R.raw.booking_sound}")

            // 3. Configure the audio attributes for a notification
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            // 4. Create the channel with High Importance (so it pops up and plays sound)
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(soundUri, audioAttributes)
                description = "Custom sound for taxi bookings"
                enableVibration(true)
            }

            // 5. Register the channel with the system
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}