package com.burnoutbuster

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.burnoutbuster/digital_wellbeing"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getUsageStats") {
                val stats = getUsageStats()
                if (stats.isNotEmpty()) {
                    result.success(stats)
                } else {
                    result.error("UNAVAILABLE", "Usage stats not available.", null)
                }
            } else if (call.method == "requestPermission") {
                if (!hasUsageStatsPermission()) {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.success(true)
                }
            } else if (call.method == "hasPermission") {
                result.success(hasUsageStatsPermission())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, 
            android.os.Process.myUid(), packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val startTime = calendar.timeInMillis

        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val statsList = mutableListOf<Map<String, Any>>()
        for (stat in queryUsageStats) {
            if (stat.totalTimeInForeground > 0) {
                val map = mapOf(
                    "packageName" to stat.packageName,
                    "totalTime" to stat.totalTimeInForeground
                )
                statsList.add(map)
            }
        }
        return statsList
    }
}
