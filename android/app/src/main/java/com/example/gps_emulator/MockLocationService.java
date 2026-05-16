package com.example.gps_emulator;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class MockLocationService extends Service {

    private static final String TAG = "MockLocationService";
    private static final String CHANNEL_ID = "gps_emulator_channel";
    private static final int NOTIFICATION_ID = 1001;

    private LocationManager locationManager;
    private Handler handler;
    private Runnable locationRunnable;

    private double currentLat = 0.0;
    private double currentLng = 0.0;
    private float currentSpeed = 0.0f;
    private float currentBearing = 0.0f;
    private float currentAccuracy = 3.0f;
    private boolean isRunning = false;
    private long updateIntervalMs = 1000;

    public static final String ACTION_START  = "ACTION_START_MOCK";
    public static final String ACTION_STOP   = "ACTION_STOP_MOCK";
    public static final String ACTION_UPDATE = "ACTION_UPDATE_LOCATION";

    public static final String EXTRA_LAT      = "extra_lat";
    public static final String EXTRA_LNG      = "extra_lng";
    public static final String EXTRA_SPEED    = "extra_speed";
    public static final String EXTRA_BEARING  = "extra_bearing";
    public static final String EXTRA_ACCURACY = "extra_accuracy";
    public static final String EXTRA_INTERVAL = "extra_interval";

    @Override
    public void onCreate() {
        super.onCreate();
        locationManager = (LocationManager) getSystemService(LOCATION_SERVICE);
        handler = new Handler(Looper.getMainLooper());
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_STICKY;
        String action = intent.getAction();
        if (action == null) action = "";
        switch (action) {
            case ACTION_START:
                currentLat      = intent.getDoubleExtra(EXTRA_LAT, 0.0);
                currentLng      = intent.getDoubleExtra(EXTRA_LNG, 0.0);
                currentSpeed    = intent.getFloatExtra(EXTRA_SPEED, 0.0f);
                currentBearing  = intent.getFloatExtra(EXTRA_BEARING, 0.0f);
                currentAccuracy = intent.getFloatExtra(EXTRA_ACCURACY, 3.0f);
                updateIntervalMs = intent.getLongExtra(EXTRA_INTERVAL, 1000);
                startMockLocation();
                break;
            case ACTION_STOP:
                stopMockLocation();
                break;
            case ACTION_UPDATE:
                currentLat     = intent.getDoubleExtra(EXTRA_LAT, currentLat);
                currentLng     = intent.getDoubleExtra(EXTRA_LNG, currentLng);
                currentSpeed   = intent.getFloatExtra(EXTRA_SPEED, currentSpeed);
                currentBearing = intent.getFloatExtra(EXTRA_BEARING, currentBearing);
                break;
        }
        return START_STICKY;
    }

    private void startMockLocation() {
        if (isRunning) return;
        isRunning = true;
        startForeground(NOTIFICATION_ID, buildNotification("GPS Emulator Active", currentLat + ", " + currentLng));
        try {
            locationManager.addTestProvider(LocationManager.GPS_PROVIDER, false, false, false, false, true, true, true, 0, 5);
            locationManager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, true);
        } catch (Exception e) {
            Log.e(TAG, "GPS provider setup error: " + e.getMessage());
        }
        try {
            locationManager.addTestProvider(LocationManager.NETWORK_PROVIDER, false, false, false, false, true, true, true, 0, 5);
            locationManager.setTestProviderEnabled(LocationManager.NETWORK_PROVIDER, true);
        } catch (Exception e) {
            Log.w(TAG, "Network provider setup: " + e.getMessage());
        }
        locationRunnable = new Runnable() {
            @Override public void run() {
                if (!isRunning) return;
                pushMockLocation(currentLat, currentLng, currentSpeed, currentBearing, currentAccuracy);
                updateNotification("GPS Emulator Active", String.format("%.6f, %.6f", currentLat, currentLng));
                handler.postDelayed(this, updateIntervalMs);
            }
        };
        handler.post(locationRunnable);
    }

    private void pushMockLocation(double lat, double lng, float speed, float bearing, float accuracy) {
        Location loc = new Location(LocationManager.GPS_PROVIDER);
        loc.setLatitude(lat);
        loc.setLongitude(lng);
        loc.setAltitude(50.0);
        loc.setSpeed(speed);
        loc.setBearing(bearing);
        loc.setAccuracy(accuracy);
        loc.setTime(System.currentTimeMillis());
        loc.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            loc.setBearingAccuracyDegrees(1.0f);
            loc.setSpeedAccuracyMetersPerSecond(0.5f);
            loc.setVerticalAccuracyMeters(1.0f);
        }
        try { locationManager.setTestProviderLocation(LocationManager.GPS_PROVIDER, loc); }
        catch (Exception e) { Log.e(TAG, "GPS push error: " + e.getMessage()); }

        try {
            Location netLoc = new Location(LocationManager.NETWORK_PROVIDER);
            netLoc.setLatitude(lat); netLoc.setLongitude(lng); netLoc.setAltitude(50.0);
            netLoc.setAccuracy(accuracy * 3); netLoc.setTime(System.currentTimeMillis());
            netLoc.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());
            locationManager.setTestProviderLocation(LocationManager.NETWORK_PROVIDER, netLoc);
        } catch (Exception e) { Log.w(TAG, "Network push: " + e.getMessage()); }
    }

    private void stopMockLocation() {
        isRunning = false;
        if (locationRunnable != null) handler.removeCallbacks(locationRunnable);
        try { locationManager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, false); locationManager.removeTestProvider(LocationManager.GPS_PROVIDER); } catch (Exception ignored) {}
        try { locationManager.setTestProviderEnabled(LocationManager.NETWORK_PROVIDER, false); locationManager.removeTestProvider(LocationManager.NETWORK_PROVIDER); } catch (Exception ignored) {}
        stopForeground(true);
        stopSelf();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(CHANNEL_ID, "GPS Emulator", NotificationManager.IMPORTANCE_LOW);
            ch.setDescription("GPS Emulator mock location service");
            NotificationManager nm = getSystemService(NotificationManager.class);
            if (nm != null) nm.createNotificationChannel(ch);
        }
    }

    private Notification buildNotification(String title, String content) {
        Intent i = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(this, 0, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        return new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title).setContentText(content)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pi).setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW).build();
    }

    private void updateNotification(String title, String content) {
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (nm != null) nm.notify(NOTIFICATION_ID, buildNotification(title, content));
    }

    @Nullable @Override public IBinder onBind(Intent intent) { return null; }

    @Override public void onDestroy() { stopMockLocation(); super.onDestroy(); }
}
