package com.tara.driver_application

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * Runs while the driver is online (DD-58).
 *
 * A foreground service, so Android keeps the app's process, its network and
 * its GPS while the screen is off or another app is in front: the socket that
 * brings ride requests lives in that process. The driver sees it as the
 * permanent "You're online" notification.
 *
 * When the driver clears the app from the recent apps, the Flutter side dies
 * with the screen and can no longer hear a request. This service is still
 * alive at that moment, so it tells the backend the driver is offline and then
 * stops. It does not do that during a trip: the trip goes on, and the driver
 * opens the app again to finish it.
 *
 * Dart starts and stops it through [MainActivity]'s method channel
 * (`lib/services/online_service.dart`).
 */
class OnlineService : Service() {

    private var offlineUrl: String? = null
    private var token: String? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var leaving = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            // Never restarted without its data (START_NOT_STICKY); if it is,
            // there is nothing to run for.
            stopSelf()
            return START_NOT_STICKY
        }
        offlineUrl = intent.getStringExtra(EXTRA_OFFLINE_URL)
        token = intent.getStringExtra(EXTRA_TOKEN)
        leaving = false

        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(
                    intent.getStringExtra(EXTRA_TITLE) ?: "",
                    intent.getStringExtra(EXTRA_TEXT) ?: "",
                ),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                } else {
                    0
                },
            )
        } catch (e: Exception) {
            // Android refuses a location service without the location
            // permission, or one started from the background. The driver is
            // online without it then, as before DD-58.
            Log.w(TAG, "not started in the foreground: ${e.javaClass.simpleName}")
            stopSelf()
            return START_NOT_STICKY
        }

        holdWakeLock()
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        leave()
    }

    /**
     * The app's screen is gone and Flutter with it: cleared from the recent
     * apps, or closed with Back on an Android that ends the app for that.
     * Both can arrive for one closing; the second does nothing.
     */
    private fun leave() {
        if (leaving) return
        leaving = true
        val url = offlineUrl
        val bearer = token
        if (onTrip || url == null || bearer == null) {
            stopNow()
            return
        }
        // Still in the foreground while this runs, so the process lives long
        // enough for the call to be answered.
        thread(name = "online-service-offline") {
            try {
                Log.i(TAG, "app cleared, offline call answered ${postOffline(url, bearer)}")
            } catch (e: Exception) {
                Log.w(TAG, "app cleared, offline call failed: ${e.javaClass.simpleName}")
            }
            Handler(Looper.getMainLooper()).post { stopNow() }
        }
    }

    override fun onDestroy() {
        if (running === this) running = null
        releaseWakeLock()
        super.onDestroy()
    }

    /** `POST /taxi-driver/set-status` with `{"status": 0}`, as the app sends it. */
    private fun postOffline(url: String, bearer: String): Int {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.connectTimeout = CALL_TIMEOUT_MS
            connection.readTimeout = CALL_TIMEOUT_MS
            connection.doOutput = true
            connection.setRequestProperty("Authorization", "Bearer $bearer")
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.outputStream.use { it.write("{\"status\":0}".toByteArray()) }
            return connection.responseCode
        } finally {
            connection.disconnect()
        }
    }

    private fun stopNow() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(title: String, text: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Low importance: it is always there, so it must not ring.
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Online status", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val open = packageManager.getLaunchIntentForPackage(packageName)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
        if (open != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    this, 0, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            )
        }
        return builder.build()
    }

    /** The screen may be off for hours; the socket's own timers need the CPU. */
    private fun holdWakeLock() {
        if (wakeLock?.isHeld == true) return
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "pu_taxi_driver:online").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    companion object {
        private const val TAG = "OnlineService"
        private const val CHANNEL_ID = "online_status"
        private const val NOTIFICATION_ID = 5801
        private const val CALL_TIMEOUT_MS = 8000

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val EXTRA_OFFLINE_URL = "offlineUrl"
        private const val EXTRA_TOKEN = "token"

        /** Set by Dart; read when the app is cleared. */
        @Volatile
        var onTrip: Boolean = false

        @Volatile
        private var running: OnlineService? = null

        /** [MainActivity] is finishing. Nothing to do when the driver is offline. */
        fun appClosed() {
            running?.leave()
        }

        /**
         * False when Android would refuse the service: a location service
         * needs the location permission. Throws when the app is not in front.
         */
        fun start(
            context: Context,
            title: String,
            text: String,
            offlineUrl: String?,
            token: String?,
        ): Boolean {
            val fine = ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_FINE_LOCATION
            )
            val coarse = ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_COARSE_LOCATION
            )
            if (fine != PackageManager.PERMISSION_GRANTED &&
                coarse != PackageManager.PERMISSION_GRANTED
            ) {
                return false
            }
            // `startService`, not `startForegroundService`: the app is in
            // front when the driver goes online, and this way a refused
            // `startForeground` is a log line instead of a crash.
            context.startService(
                Intent(context, OnlineService::class.java)
                    .putExtra(EXTRA_TITLE, title)
                    .putExtra(EXTRA_TEXT, text)
                    .putExtra(EXTRA_OFFLINE_URL, offlineUrl)
                    .putExtra(EXTRA_TOKEN, token)
            )
            return true
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, OnlineService::class.java))
        }
    }
}
