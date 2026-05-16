// lib/services/mock_location_service.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../models/location_point.dart';

class MockLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.gps_emulator/mock_location',
  );

  bool _isActive = false;
  LocationPoint? _currentLocation;
  Timer? _routeTimer;
  StreamController<LocationPoint>? _locationStreamController;

  bool get isActive => _isActive;
  LocationPoint? get currentLocation => _currentLocation;

  Stream<LocationPoint> get locationStream {
    _locationStreamController ??= StreamController<LocationPoint>.broadcast();
    return _locationStreamController!.stream;
  }

  Future<bool> startMockLocation({
    required double latitude,
    required double longitude,
    double speedMs = 0.0,
    double bearing = 0.0,
    double accuracy = 3.0,
    int intervalMs = 1000,
  }) async {
    try {
      await _channel.invokeMethod('startMockLocation', {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speedMs,
        'bearing': bearing,
        'accuracy': accuracy,
        'interval': intervalMs,
      });
    } catch (e) {
      // ignore channel errors - still update dart state
    }
    _isActive = true;
    _currentLocation = LocationPoint(latitude: latitude, longitude: longitude);
    _locationStreamController?.add(_currentLocation!);
    return true;
  }

  Future<void> stopMockLocation() async {
    try {
      await _channel.invokeMethod('stopMockLocation');
    } catch (e) {
      // ignore
    }
    _isActive = false;
    _routeTimer?.cancel();
    _routeTimer = null;
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double speedMs = 0.0,
    double bearing = 0.0,
  }) async {
    if (!_isActive) return;
    try {
      await _channel.invokeMethod('updateLocation', {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speedMs,
        'bearing': bearing,
      });
    } catch (e) {
      // ignore
    }
    _currentLocation = LocationPoint(latitude: latitude, longitude: longitude);
    _locationStreamController?.add(_currentLocation!);
  }

  Future<void> startRouteSimulation({
    required RouteSimulation route,
    Function(LocationPoint)? onLocationUpdate,
    Function()? onRouteComplete,
  }) async {
    if (route.waypoints.length < 2) return;

    _routeTimer?.cancel();

    await startMockLocation(
      latitude: route.waypoints.first.latitude,
      longitude: route.waypoints.first.longitude,
      speedMs: route.speedKmh / 3.6,
    );

    final interpolated = _interpolateRoute(route);
    int index = 0;

    _routeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      if (index >= interpolated.length) {
        if (route.loop) {
          index = 0;
        } else {
          timer.cancel();
          _isActive = false;
          stopMockLocation();
          onRouteComplete?.call();
          return;
        }
      }

      final point = interpolated[index];
      _currentLocation = point;
      _locationStreamController?.add(point);
      onLocationUpdate?.call(point);

      updateLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        speedMs: route.speedKmh / 3.6,
      );

      index++;
    });
  }

  List<LocationPoint> _interpolateRoute(RouteSimulation route) {
    final result = <LocationPoint>[];
    final speedMs = route.speedKmh / 3.6;
    const intervalSec = 0.5;
    final stepMeters = speedMs * intervalSec;

    for (int i = 0; i < route.waypoints.length - 1; i++) {
      final from = route.waypoints[i];
      final to = route.waypoints[i + 1];
      final dist = _haversineDistance(from, to);
      final steps = (dist / stepMeters).ceil().clamp(1, 10000);

      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        result.add(
          LocationPoint(
            latitude: from.latitude + (to.latitude - from.latitude) * t,
            longitude: from.longitude + (to.longitude - from.longitude) * t,
          ),
        );
      }
    }
    result.add(route.waypoints.last);
    return result;
  }

  double calculateBearing(LocationPoint from, LocationPoint to) {
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLng = _toRad(to.longitude - from.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (_toDeg(math.atan2(y, x)) + 360) % 360;
  }

  double _haversineDistance(LocationPoint a, LocationPoint b) {
    const R = 6371000.0;
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
  double _toDeg(double rad) => rad * 180.0 / math.pi;

  void dispose() {
    _routeTimer?.cancel();
    _locationStreamController?.close();
  }
}
