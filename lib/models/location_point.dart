// lib/models/location_point.dart

class LocationPoint {
  final double latitude;
  final double longitude;
  final String? label;
  final DateTime? timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.label,
    this.timestamp,
  });

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    String? label,
    DateTime? timestamp,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
    'timestamp': timestamp?.toIso8601String(),
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    label: json['label'] as String?,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : null,
  );

  @override
  String toString() => 'LocationPoint($latitude, $longitude)';
}


class RouteSimulation {
  final String name;
  final List<LocationPoint> waypoints;
  final double speedKmh;
  final bool loop;

  const RouteSimulation({
    required this.name,
    required this.waypoints,
    this.speedKmh = 30.0,
    this.loop = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'waypoints': waypoints.map((w) => w.toJson()).toList(),
    'speedKmh': speedKmh,
    'loop': loop,
  };

  factory RouteSimulation.fromJson(Map<String, dynamic> json) => RouteSimulation(
    name: json['name'] as String,
    waypoints: (json['waypoints'] as List)
        .map((w) => LocationPoint.fromJson(w as Map<String, dynamic>))
        .toList(),
    speedKmh: (json['speedKmh'] as num).toDouble(),
    loop: json['loop'] as bool? ?? false,
  );
}
