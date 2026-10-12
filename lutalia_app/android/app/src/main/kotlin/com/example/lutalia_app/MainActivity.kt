package com.example.lutalia_app

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.aggregate.AggregationResultGroupedByPeriod
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.metadata.DataOrigin
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.LocalDateTime
import java.time.Period
import java.time.ZoneId
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Hosts the Health Connect permission sheet.
 *
 * Must stay a FlutterFragmentActivity: the `health` plugin casts the host to
 * ComponentActivity to register its launcher, and that cast fails on a plain
 * FlutterActivity. Even then the plugin's launcher is frequently null when a
 * request arrives ("Permission launcher not found"), so the contract is also
 * registered here in onCreate — registerForActivityResult is only legal before
 * the activity is STARTED.
 *
 * Sleep is still read through the plugin. Steps are aggregated here because
 * the plugin cannot filter by source app (see [readDailySteps]).
 */
class MainActivity : FlutterFragmentActivity() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private var permissionLauncher: ActivityResultLauncher<Set<String>>? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        permissionLauncher =
            registerForActivityResult(
                PermissionController.createRequestPermissionResultContract()
            ) { granted: Set<String> ->
                val result = pendingPermissionResult
                pendingPermissionResult = null
                result?.success(granted.toList())
            }
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        pendingPermissionResult?.success(emptyList<String>())
        pendingPermissionResult = null
        scope.cancel()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HEALTH_PERMISSION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAuthorization" -> {
                    val permissions =
                        call.argument<List<String>>("permissions") ?: emptyList()
                    requestPermissions(permissions, result)
                }

                "getGrantedPermissions" -> scope.launch {
                    result.success(readGrantedPermissions())
                }

                "readDailySteps" -> {
                    val start = call.argument<Number>("start")?.toLong()
                    val end = call.argument<Number>("end")?.toLong()
                    val preferred =
                        call.argument<List<String>>("preferredSources") ?: emptyList()
                    if (start == null || end == null || end <= start) {
                        result.error("BAD_ARGS", "start/end missing or empty range", null)
                    } else {
                        scope.launch { result.success(readDailySteps(start, end, preferred)) }
                    }
                }

                "getAvailability" -> result.success(readAvailability())
                "openPermissions" -> result.success(openHealthConnectSettings())
                "installProvider" -> result.success(installHealthProvider())
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermissions(permissions: List<String>, result: MethodChannel.Result) {
        if (permissions.isEmpty()) {
            result.success(emptyList<String>())
            return
        }
        val launcher = permissionLauncher
        if (launcher == null) {
            Log.e(HEALTH_LOG_TAG, "request: no launcher registered")
            result.error("NO_LAUNCHER", "Permission launcher not registered", null)
            return
        }
        // A second request would orphan the first result.
        pendingPermissionResult?.success(emptyList<String>())
        pendingPermissionResult = result
        try {
            launcher.launch(permissions.toSet())
        } catch (e: Exception) {
            // No sheet can appear. Report an error instead of an empty set,
            // which Dart would read as "user refused".
            Log.e(HEALTH_LOG_TAG, "request: launch failed", e)
            pendingPermissionResult = null
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    /**
     * A failed read is reported as a failure, never as an empty grant set:
     * "could not ask" and "nothing allowed" need different UI.
     */
    private suspend fun readGrantedPermissions(): Map<String, Any> = try {
        val granted = withContext(Dispatchers.IO) {
            HealthConnectClient.getOrCreate(applicationContext)
                .permissionController
                .getGrantedPermissions()
                .toList()
        }
        mapOf("ok" to true, "granted" to granted)
    } catch (e: Exception) {
        Log.e(HEALTH_LOG_TAG, "getGrantedPermissions failed", e)
        mapOf(
            "ok" to false,
            "error" to (e.message ?: e.javaClass.name),
            "type" to e.javaClass.name
        )
    }

    /**
     * Steps per local calendar day in [startMs, endMs).
     *
     * Health Connect only de-duplicates records that overlap in time, so a
     * phone and a watch (or Google Fit next to Samsung Health) logging the same
     * walk in differently sliced records are added together. For every
     * [preferred] app that contributed, its own per-day total is returned too,
     * so Dart can use the number the user actually sees in that app.
     */
    private suspend fun readDailySteps(
        startMs: Long,
        endMs: Long,
        preferred: List<String>
    ): Map<String, Any> = try {
        withContext(Dispatchers.IO) {
            val client = HealthConnectClient.getOrCreate(applicationContext)
            val zone = ZoneId.systemDefault()
            val range = TimeRangeFilter.between(
                LocalDateTime.ofInstant(Instant.ofEpochMilli(startMs), zone),
                LocalDateTime.ofInstant(Instant.ofEpochMilli(endMs), zone)
            )

            suspend fun perDay(origins: Set<DataOrigin>): List<AggregationResultGroupedByPeriod> =
                client.aggregateGroupByPeriod(
                    AggregateGroupByPeriodRequest(
                        metrics = setOf(StepsRecord.COUNT_TOTAL),
                        timeRangeFilter = range,
                        timeRangeSlicer = Period.ofDays(1),
                        dataOriginFilter = origins
                    )
                )

            fun dayKey(group: AggregationResultGroupedByPeriod) =
                group.startTime.toLocalDate().toString()

            val all = perDay(emptySet())
            val contributing = all
                .flatMap { group -> group.result.dataOrigins.map { it.packageName } }
                .toSet()

            val bySourcePerDay = mutableMapOf<String, MutableMap<String, Long>>()
            for (pkg in preferred) {
                if (pkg !in contributing) continue
                for (group in perDay(setOf(DataOrigin(pkg)))) {
                    bySourcePerDay.getOrPut(dayKey(group)) { mutableMapOf() }[pkg] =
                        group.result[StepsRecord.COUNT_TOTAL] ?: 0L
                }
            }

            val days = all.map { group ->
                mapOf(
                    "date" to dayKey(group),
                    "total" to (group.result[StepsRecord.COUNT_TOTAL] ?: 0L),
                    "sources" to group.result.dataOrigins.map { it.packageName },
                    "bySource" to (bySourcePerDay[dayKey(group)] ?: emptyMap<String, Long>())
                )
            }
            mapOf("ok" to true, "days" to days)
        }
    } catch (e: Exception) {
        Log.e(HEALTH_LOG_TAG, "readDailySteps failed", e)
        mapOf("ok" to false, "error" to (e.message ?: e.javaClass.name))
    }

    /**
     * getSdkStatus needs the provider in <queries>, otherwise package
     * visibility hides it. The raw package check is reported alongside so a
     * missing app (install) can be told apart from a broken Play services
     * install (installing again would not help).
     */
    private fun readAvailability(): Map<String, Any> {
        val status = try {
            HealthConnectClient.getSdkStatus(applicationContext, PROVIDER_PACKAGE)
        } catch (_: Exception) {
            SDK_STATUS_UNKNOWN
        }
        return mapOf(
            "sdkStatus" to status,
            "providerInstalled" to isProviderInstalled(),
            "providerPackage" to PROVIDER_PACKAGE
        )
    }

    private fun isProviderInstalled(): Boolean = try {
        packageManager.getPackageInfo(PROVIDER_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    } catch (_: Exception) {
        false
    }

    private fun installHealthProvider(): Boolean {
        val candidates = listOf(
            Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$PROVIDER_PACKAGE"))
                .setPackage("com.android.vending"),
            Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=$PROVIDER_PACKAGE")
            )
        )
        return startFirst(candidates)
    }

    private fun openHealthConnectSettings(): Boolean {
        val candidates = listOf(
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        )
        return startFirst(candidates)
    }

    private fun startFirst(candidates: List<Intent>): Boolean {
        for (intent in candidates) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // Try the next route.
            }
        }
        return false
    }

    companion object {
        const val HEALTH_PERMISSION_CHANNEL = "com.example.lutalia_app/health_permissions"
        const val PROVIDER_PACKAGE = "com.google.android.apps.healthdata"
        const val SDK_STATUS_UNKNOWN = -1
        const val HEALTH_LOG_TAG = "LutaliaHealth"
    }
}
