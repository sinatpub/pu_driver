package com.tara.driver_application

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This ensures the channel is created as soon as the app starts
        createBookingNotificationChannel()
    }

    // DD-58: Dart starts and stops [OnlineService] with the driver's online
    // state (`lib/services/online_service.dart`).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A new engine is a new Dart side: it says again if a trip is running.
        OnlineService.onTrip = false
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pu_taxi_driver/online_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> try {
                        result.success(
                            OnlineService.start(
                                this,
                                call.argument<String>("title") ?: "",
                                call.argument<String>("text") ?: "",
                                call.argument<String>("offlineUrl"),
                                call.argument<String>("token"),
                            )
                        )
                    } catch (e: Exception) {
                        // Android does not start a service for an app that is
                        // not in front; Dart tries again when it is.
                        result.error("not_started", e.javaClass.simpleName, null)
                    }
                    "stop" -> {
                        OnlineService.stop(this)
                        result.success(null)
                    }
                    "setOnTrip" -> {
                        OnlineService.onTrip = call.arguments == true
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Back on the home ends the app on Android 11 and older; Flutter dies
    // with it, as when the app is cleared from the recent apps.
    override fun onDestroy() {
        if (isFinishing) OnlineService.appClosed()
        super.onDestroy()
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