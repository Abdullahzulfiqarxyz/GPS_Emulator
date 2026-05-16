// lib/providers/gps_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_point.dart';
import '../services/mock_location_service.dart';

enum EmulatorState { idle, active, routeSimulation }

class GpsProvider extends ChangeNotifier {
  final MockLocationService _service = MockLocationService();

  EmulatorState _state = EmulatorState.idle;
  LocationPoint _currentLocation = const LocationPoint(
    latitude: 37.7749,
    longitude: -122.4194,
    label: 'San Francisco, CA',
  );
  double _speedKmh = 0.0;
  double _bearing = 0.0;
  double _accuracy = 3.0;
  int _updateIntervalMs = 1000;

  // Route simulation
  RouteSimulation? _activeRoute;
  int _routeProgress = 0;
  List<LocationPoint> _routeWaypoints = [];

  // Saved locations
  List<LocationPoint> _savedLocations = [];
  List<RouteSimulation> _savedRoutes = [];

  // Stream subscription
  StreamSubscription<LocationPoint>? _locationSub;

  // Getters
  EmulatorState get state => _state;
  LocationPoint get currentLocation => _currentLocation;
  double get speedKmh => _speedKmh;
  double get bearing => _bearing;
  double get accuracy => _accuracy;
  int get updateIntervalMs => _updateIntervalMs;
  RouteSimulation? get activeRoute => _activeRoute;
  int get routeProgress => _routeProgress;
  List<LocationPoint> get routeWaypoints => _routeWaypoints;
  List<LocationPoint> get savedLocations => _savedLocations;
  List<RouteSimulation> get savedRoutes => _savedRoutes;
  bool get isActive => _state != EmulatorState.idle;

  GpsProvider() {
    _loadSavedData();
    _locationSub = _service.locationStream.listen((point) {
      _currentLocation = point;
      notifyListeners();
    });
  }

  // ─── Location Control ───────────────────────────────────────────────────────

  Future<void> startMockLocation() async {
    final success = await _service.startMockLocation(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      speedMs: _speedKmh / 3.6,
      bearing: _bearing,
      accuracy: _accuracy,
      intervalMs: _updateIntervalMs,
    );

    if (success) {
      _state = EmulatorState.active;
      notifyListeners();
    }
  }

  Future<void> stopMockLocation() async {
    await _service.stopMockLocation();
    _state = EmulatorState.idle;
    _activeRoute = null;
    _routeProgress = 0;
    notifyListeners();
  }

  Future<void> setLocation(double lat, double lng, {String? label}) async {
    _currentLocation = LocationPoint(
      latitude: lat,
      longitude: lng,
      label: label,
    );

    if (_state == EmulatorState.active) {
      await _service.updateLocation(
        latitude: lat,
        longitude: lng,
        speedMs: _speedKmh / 3.6,
        bearing: _bearing,
      );
    }

    notifyListeners();
  }

  void setSpeed(double kmh) {
    _speedKmh = kmh.clamp(0.0, 300.0);
    notifyListeners();
  }

  void setBearing(double degrees) {
    _bearing = degrees % 360;
    notifyListeners();
  }

  void setAccuracy(double meters) {
    _accuracy = meters.clamp(1.0, 100.0);
    notifyListeners();
  }

  void setUpdateInterval(int ms) {
    _updateIntervalMs = ms.clamp(100, 5000);
    notifyListeners();
  }

  // ─── Route Simulation ───────────────────────────────────────────────────────

  void addWaypoint(LocationPoint point) {
    _routeWaypoints = [..._routeWaypoints, point];
    notifyListeners();
  }

  void removeWaypoint(int index) {
    final list = [..._routeWaypoints];
    list.removeAt(index);
    _routeWaypoints = list;
    notifyListeners();
  }

  void clearWaypoints() {
    _routeWaypoints = [];
    notifyListeners();
  }

  Future<void> startRouteSimulation({double? speedKmh, bool loop = false}) async {
    if (_routeWaypoints.length < 2) return;

    final route = RouteSimulation(
      name: 'Custom Route',
      waypoints: _routeWaypoints,
      speedKmh: speedKmh ?? _speedKmh.clamp(1.0, 200.0),
      loop: loop,
    );

    _activeRoute = route;
    _state = EmulatorState.routeSimulation;
    _routeProgress = 0;
    notifyListeners();

    await _service.startRouteSimulation(
      route: route,
      onLocationUpdate: (point) {
        _currentLocation = point;
        _routeProgress++;
        notifyListeners();
      },
      onRouteComplete: () {
        _state = EmulatorState.idle;
        _activeRoute = null;
        notifyListeners();
      },
    );
  }

  // ─── Saved Locations ────────────────────────────────────────────────────────

  Future<void> saveCurrentLocation(String label) async {
    final point = _currentLocation.copyWith(
      label: label,
      timestamp: DateTime.now(),
    );
    _savedLocations = [..._savedLocations, point];
    await _persistSavedLocations();
    notifyListeners();
  }

  Future<void> deleteSavedLocation(int index) async {
    final list = [..._savedLocations];
    list.removeAt(index);
    _savedLocations = list;
    await _persistSavedLocations();
    notifyListeners();
  }

  Future<void> loadSavedLocation(LocationPoint point) async {
    await setLocation(point.latitude, point.longitude, label: point.label);
  }

  // ─── Saved Routes ───────────────────────────────────────────────────────────

  Future<void> saveCurrentRoute(String name) async {
    if (_routeWaypoints.length < 2) return;
    final route = RouteSimulation(
      name: name,
      waypoints: _routeWaypoints,
      speedKmh: _speedKmh.clamp(1.0, 200.0),
    );
    _savedRoutes = [..._savedRoutes, route];
    await _persistSavedRoutes();
    notifyListeners();
  }

  Future<void> loadRoute(RouteSimulation route) async {
    _routeWaypoints = [...route.waypoints];
    notifyListeners();
  }

  Future<void> deleteSavedRoute(int index) async {
    final list = [..._savedRoutes];
    list.removeAt(index);
    _savedRoutes = list;
    await _persistSavedRoutes();
    notifyListeners();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final locJson = prefs.getString('saved_locations');
    if (locJson != null) {
      final List list = jsonDecode(locJson);
      _savedLocations = list
          .map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final routeJson = prefs.getString('saved_routes');
    if (routeJson != null) {
      final List list = jsonDecode(routeJson);
      _savedRoutes = list
          .map((e) => RouteSimulation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Load last used location
    final lastLat = prefs.getDouble('last_lat');
    final lastLng = prefs.getDouble('last_lng');
    if (lastLat != null && lastLng != null) {
      _currentLocation = LocationPoint(latitude: lastLat, longitude: lastLng);
    }

    notifyListeners();
  }

  Future<void> _persistSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_locations',
      jsonEncode(_savedLocations.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _persistSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'saved_routes',
      jsonEncode(_savedRoutes.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _persistLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', _currentLocation.latitude);
    await prefs.setDouble('last_lng', _currentLocation.longitude);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _service.dispose();
    _persistLastLocation();
    super.dispose();
  }
}
