package com.bondoolai.bondoolai_steps

import android.content.Intent
import android.net.Uri
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.Period

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val stepPermissions = setOf(HealthPermission.getReadPermission(StepsRecord::class))
    private val permissionContract = PermissionController.createRequestPermissionResultContract()
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "bondoolai/share").setMethodCallHandler { call, result ->
            if (call.method == "shareText") {
                val text = call.argument<String>("text") ?: ""
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                startActivity(Intent.createChooser(send, "Найзаа урих"))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, "bondoolai/health").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(healthStatus())
                "hasPermission" -> scope.launch {
                    try {
                        result.success(hasStepPermission())
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestPermission" -> requestStepPermission(result)
                "dailySteps" -> {
                    val days = call.argument<Int>("days") ?: 30
                    scope.launch {
                        try {
                            result.success(dailySteps(days))
                        } catch (e: Exception) {
                            result.error("health_error", e.message, null)
                        }
                    }
                }
                "openInstall" -> {
                    openHealthConnectInstall()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun healthStatus(): String = when (HealthConnectClient.getSdkStatus(this)) {
        HealthConnectClient.SDK_AVAILABLE -> "available"
        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "needs_install"
        else -> "unavailable"
    }

    private suspend fun hasStepPermission(): Boolean {
        if (HealthConnectClient.getSdkStatus(this) != HealthConnectClient.SDK_AVAILABLE) return false
        val granted = HealthConnectClient.getOrCreate(this).permissionController.getGrantedPermissions()
        return granted.containsAll(stepPermissions)
    }

    private fun requestStepPermission(result: MethodChannel.Result) {
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        try {
            startActivityForResult(permissionContract.createIntent(this, stepPermissions), REQUEST_HEALTH_PERMISSIONS)
        } catch (e: Exception) {
            pendingPermissionResult = null
            result.success(false)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_HEALTH_PERMISSIONS) return
        val granted = permissionContract.parseResult(resultCode, data)
        pendingPermissionResult?.success(granted.containsAll(stepPermissions))
        pendingPermissionResult = null
    }

    /** Total steps per local day ("yyyy-MM-dd" -> steps) for the last [days] days. */
    private suspend fun dailySteps(days: Int): Map<String, Int> {
        val client = HealthConnectClient.getOrCreate(this)
        val today = LocalDate.now()
        val response = client.aggregateGroupByPeriod(
            AggregateGroupByPeriodRequest(
                metrics = setOf(StepsRecord.COUNT_TOTAL),
                timeRangeFilter = TimeRangeFilter.between(
                    today.minusDays((days - 1).toLong()).atStartOfDay(),
                    today.plusDays(1).atStartOfDay(),
                ),
                timeRangeSlicer = Period.ofDays(1),
            )
        )
        return response.associate { group ->
            group.startTime.toLocalDate().toString() to (group.result[StepsRecord.COUNT_TOTAL] ?: 0L).toInt()
        }
    }

    private fun openHealthConnectInstall() {
        val uri = Uri.parse("market://details?id=com.google.android.apps.healthdata&url=healthconnect%3A%2F%2Fonboarding")
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage("com.android.vending")
            putExtra("overlay", true)
            putExtra("callerId", packageName)
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata"))
            )
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private companion object {
        const val REQUEST_HEALTH_PERMISSIONS = 4201
    }
}
