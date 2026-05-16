// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';
import '../models/location_point.dart';
import '../widgets/coordinate_input_sheet.dart';
import '../widgets/control_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) {
    final provider = context.read<GpsProvider>();
    provider.setLocation(latLng.latitude, latLng.longitude);

    // Show snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location set: ${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: const Color(0xFF1A2332),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        action: provider.isActive
            ? null
            : SnackBarAction(
                label: 'START',
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () => provider.startMockLocation(),
              ),
      ),
    );
  }

  void _centerOnLocation() {
    if (!_mapReady) return;
    final provider = context.read<GpsProvider>();
    _mapController.move(
      LatLng(provider.currentLocation.latitude, provider.currentLocation.longitude),
      15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpsProvider>();
    final loc = provider.currentLocation;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(loc.latitude, loc.longitude),
              initialZoom: 13.0,
              onTap: _onMapTap,
              onMapReady: () => setState(() => _mapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gpsemulator.app',
                tileBuilder: _darkTileBuilder,
              ),

              // Route waypoints layer
              if (provider.routeWaypoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: provider.routeWaypoints
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      strokeWidth: 3,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                      isDotted: true,
                    ),
                  ],
                ),

              // Current location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(loc.latitude, loc.longitude),
                    width: 60,
                    height: 60,
                    child: _LocationMarker(
                      isActive: provider.isActive,
                      bearing: provider.bearing,
                    ),
                  ),
                  // Route waypoint markers
                  ...provider.routeWaypoints.asMap().entries.map((e) => Marker(
                    point: LatLng(e.value.latitude, e.value.longitude),
                    width: 32,
                    height: 32,
                    child: _WaypointMarker(index: e.key + 1),
                  )),
                ],
              ),
            ],
          ),

          // Top coordinate display
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: _CoordinateDisplay(location: loc),
          ),

          // Right-side controls
          Positioned(
            right: 12,
            bottom: 200,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _centerOnLocation,
                  tooltip: 'Center',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.add_location_alt,
                  onTap: () => _showCoordinateInput(context),
                  tooltip: 'Enter coords',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.zoom_in,
                  onTap: () {
                    if (_mapReady) {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    }
                  },
                  tooltip: 'Zoom in',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.zoom_out,
                  onTap: () {
                    if (_mapReady) {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    }
                  },
                  tooltip: 'Zoom out',
                ),
              ],
            ),
          ),

          // Bottom control panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ControlPanel(
              onStartStop: () {
                if (provider.isActive) {
                  provider.stopMockLocation();
                } else {
                  provider.startMockLocation();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkTileBuilder(BuildContext context, Widget tile, TileImage tileImage) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.85, 0, 0, 0, 255,
        0, -0.85, 0, 0, 255,
        0, 0, -0.85, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }

  void _showCoordinateInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CoordinateInputSheet(),
    );
  }
}

class _CoordinateDisplay extends StatelessWidget {
  final LocationPoint location;
  const _CoordinateDisplay({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: Theme.of(context).colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.label != null)
                  Text(
                    location.label!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: '${location.latitude}, ${location.longitude}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coordinates copied!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Icon(Icons.copy, size: 16, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _LocationMarker extends StatefulWidget {
  final bool isActive;
  final double bearing;
  const _LocationMarker({required this.isActive, required this.bearing});

  @override
  State<_LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<_LocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? Theme.of(context).colorScheme.primary
        : Colors.white54;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isActive)
              Container(
                width: 60 * _pulse.value,
                height: 60 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15 * _pulse.value),
                  border: Border.all(
                    color: color.withOpacity(0.3 * _pulse.value),
                    width: 1,
                  ),
                ),
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WaypointMarker extends StatelessWidget {
  final int index;
  const _WaypointMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xEE111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white70),
        ),
      ),
    );
  }
}
