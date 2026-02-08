package com.burnoutbuster.burnout_buster

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.os.Process
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.burnoutbuster/digital_wellbeing"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getUsageStats") {
                val stats = getUsageStats()
                result.success(stats)
            } else if (call.method == "requestPermission") {
                requestPermission()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis

        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val statsList = mutableListOf<Map<String, Any>>()

        for (u in queryUsageStats) {
             // Only include apps with significant usage (> 1 minute) to reduce noise
            if (u.totalTimeInForeground > 60000) {
                val map = mapOf(
                    "packageName" to u.packageName,
                    "totalTime" to u.totalTimeInForeground
                )
                statsList.add(map)
            }
        }
        return statsList
    }
}
