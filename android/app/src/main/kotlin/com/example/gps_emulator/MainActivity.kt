package com.example.gps_emulator

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.gps_emulator/mock_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startMockLocation" -> {
                      val lat = (call.argument<Number>("latitude") ?: 0).toDouble()
                      val lng = (call.argument<Number>("longitude") ?: 0).toDouble()

                      val speed = (call.argument<Number>("speed") ?: 0).toFloat()
                      
                      val bearing = (call.argument<Number>("bearing") ?: 0).toFloat()
                      
                      val accuracy = (call.argument<Number>("accuracy") ?: 3).toFloat()
                      
                      val interval = (call.argument<Number>("interval") ?: 1000).toLong()

                        val intent = Intent(this, MockLocationService::class.java).apply {
                            action = MockLocationService.ACTION_START
                            putExtra(MockLocationService.EXTRA_LAT, lat)
                            putExtra(MockLocationService.EXTRA_LNG, lng)
                            putExtra(MockLocationService.EXTRA_SPEED, speed)
                            putExtra(MockLocationService.EXTRA_BEARING, bearing)
                            putExtra(MockLocationService.EXTRA_ACCURACY, accuracy)
                            putExtra(MockLocationService.EXTRA_INTERVAL, interval)
                        }
                        startForegroundService(intent)
                        result.success(true)
                    }

                    "stopMockLocation" -> {
                        val intent = Intent(this, MockLocationService::class.java).apply {
                            action = MockLocationService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    }

                    "updateLocation" -> {
                        val lat = call.argument<Double>("latitude") ?: 0.0
                        val lng = call.argument<Double>("longitude") ?: 0.0
                        val speed = call.argument<Double>("speed")?.toFloat() ?: 0f
                        val bearing = call.argument<Double>("bearing")?.toFloat() ?: 0f

                        val intent = Intent(this, MockLocationService::class.java).apply {
                            action = MockLocationService.ACTION_UPDATE
                            putExtra(MockLocationService.EXTRA_LAT, lat)
                            putExtra(MockLocationService.EXTRA_LNG, lng)
                            putExtra(MockLocationService.EXTRA_SPEED, speed)
                            putExtra(MockLocationService.EXTRA_BEARING, bearing)
                        }
                        startService(intent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}