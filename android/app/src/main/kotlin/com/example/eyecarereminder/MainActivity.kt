package com.example.eyecarereminder

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val NOTIFICATION_PERMISSION_REQUEST = 1001
    private val SERVICE_CHANNEL = "com.example.eyecarereminder/service"
    private val PERMISSION_CHANNEL = "com.example.eyecarereminder/permission"

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        try {
                            // Start foreground service
                            EyeCareService.startService(this)
                            // Save state
                            getSharedPreferences("eye_care_prefs", Context.MODE_PRIVATE)
                                .edit()
                                .putBoolean("is_monitoring", true)
                                .apply()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "stopService" -> {
                        try {
                            // Stop foreground service
                            EyeCareService.stopService(this)
                            // Cancel all work
                            EyeCareWorker.cancelAllWork(this)
                            // Save state
                            getSharedPreferences("eye_care_prefs", Context.MODE_PRIVATE)
                                .edit()
                                .putBoolean("is_monitoring", false)
                                .apply()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "checkStatus" -> {
                        val prefs = getSharedPreferences("eye_care_prefs", Context.MODE_PRIVATE)
                        result.success(prefs.getBoolean("is_monitoring", false))
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkNotificationPermission" -> {
                        result.success(hasNotificationPermission())
                    }

                    "requestNotificationPermission" -> {
                        requestNotificationPermission(result)
                    }

                    "openAppSettings" -> {
                        openNotificationSettings()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (hasNotificationPermission()) {
                result.success(true)
                return
            }

            // Check if we should show rationale
            if (ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                )) {
                // Show rationale to user
                showPermissionRationale(result)
            } else {
                // Request permission directly
                requestPermissionDirectly(result)
            }
        } else {
            result.success(true)
        }
    }

    private fun requestPermissionDirectly(result: MethodChannel.Result) {
        permissionResult = result

        try {
            // Use the activity's requestPermissions method
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST
            )
        } catch (e: Exception) {
            Log.e("Permission", "Error: ${e.message}")
            result.error("ERROR", "Failed to request permission", null)
        }
    }

    private fun showPermissionRationale(result: MethodChannel.Result) {
        // Store result and show a message
        permissionResult = result

        // After showing rationale, request permission
        Handler().postDelayed({
            requestPermissionDirectly(result)
        }, 1500)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        Log.d("Permission", "onRequestPermissionsResult called, requestCode: $requestCode")
        Log.d("Permission", "Permissions: ${permissions.joinToString()}")
        Log.d("Permission", "Grant results: ${grantResults.joinToString()}")

        if (requestCode == NOTIFICATION_PERMISSION_REQUEST) {
            val isGranted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED

            Log.d("Permission", "Permission granted: $isGranted")

            // Send result back to Flutter
            permissionResult?.success(isGranted)
            permissionResult = null
        }
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }

        try {
            startActivity(intent)
        } catch (e: Exception) {
        }
    }
}