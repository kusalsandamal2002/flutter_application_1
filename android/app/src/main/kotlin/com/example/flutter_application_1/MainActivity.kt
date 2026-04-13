package com.example.flutter_application_1

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "laugfs.smart_tracker/system_tones"

    private var activeRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "getAlarmTones" -> {
                    result.success(queryTones(RingtoneManager.TYPE_ALARM))
                }

                "getNotificationTones" -> {
                    result.success(queryTones(RingtoneManager.TYPE_NOTIFICATION))
                }

                "getDefaultAlarmTone" -> {
                    result.success(getDefaultTone(RingtoneManager.TYPE_ALARM))
                }

                "getDefaultNotificationTone" -> {
                    result.success(getDefaultTone(RingtoneManager.TYPE_NOTIFICATION))
                }

                "playTone" -> {
                    val uri = call.argument<String>("uri")

                    if (uri.isNullOrBlank()) {
                        result.error("INVALID_URI", "Tone URI is missing.", null)
                        return@setMethodCallHandler
                    }

                    val played = playTone(uri)

                    if (played) {
                        result.success(true)
                    } else {
                        result.error("PLAY_FAILED", "Unable to play selected tone.", null)
                    }
                }

                "stopTone" -> {
                    stopTone()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        stopTone()
        super.onDestroy()
    }

    private fun queryTones(type: Int): List<Map<String, String>> {
        val ringtoneManager = RingtoneManager(applicationContext)
        ringtoneManager.setType(type)

        val cursor = ringtoneManager.cursor ?: return emptyList()
        val items = mutableListOf<Map<String, String>>()
        val seenUris = mutableSetOf<String>()

        cursor.use { c ->
            while (c.moveToNext()) {
                val position = c.position
                val uri = ringtoneManager.getRingtoneUri(position) ?: continue
                val title =
                    c.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: "Unknown tone"
                val uriString = uri.toString()

                if (seenUris.add(uriString)) {
                    items.add(
                        mapOf(
                            "title" to title,
                            "uri" to uriString
                        )
                    )
                }
            }
        }

        return items
    }

    private fun getDefaultTone(type: Int): Map<String, String>? {
        val uri = RingtoneManager.getDefaultUri(type) ?: return null
        val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
        val title = ringtone?.getTitle(applicationContext) ?: "Default tone"

        return mapOf(
            "title" to title,
            "uri" to uri.toString()
        )
    }

    private fun playTone(uriString: String): Boolean {
        stopTone()

        val uri = try {
            Uri.parse(uriString)
        } catch (e: Exception) {
            null
        } ?: return false

        val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            ?: return false

        try {
            // 🔥 IMPORTANT FIX
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                ringtone.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM) // 🔊 force alarm type
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone.isLooping = true
            }

            ringtone.play()
            activeRingtone = ringtone

            return true

        } catch (e: Exception) {
            return false
        }
    }

    private fun stopTone() {
        activeRingtone?.stop()
        activeRingtone = null
    }
}