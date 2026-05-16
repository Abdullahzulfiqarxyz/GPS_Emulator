// lib/screens/route_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';
import '../models/location_point.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late MapController _mapController;
  double _simSpeed = 30.0;
  bool _loop = false;

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

  void _onMapTap(TapPosition _, LatLng latLng) {
    context.read<GpsProvider>().addWaypoint(
      LocationPoint(latitude: latLng.latitude, longitude: latLng.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpsProvider>();
    final theme = Theme.of(context);
    final waypoints = provider.routeWaypoints;
    final isSimulating = provider.state == EmulatorState.routeSimulation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Route Simulation'),
        actions: [
          if (waypoints.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final name = await _showSaveDialog(context);
                if (name != null && name.isNotEmpty) {
                  await provider.saveCurrentRoute(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Route "$name" saved!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save'),
            ),
          if (waypoints.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2332),
                    title: const Text('Clear Route?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'All waypoints will be removed.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearWaypoints();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear', style: TextStyle(color: Color(0xFFFF5252))),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
            ),
        ],
      ),
      body: Column(
        children: [
          // Map area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: waypoints.isNotEmpty
                        ? LatLng(waypoints.first.latitude, waypoints.first.longitude)
                        : LatLng(
                            provider.currentLocation.latitude,
                            provider.currentLocation.longitude,
                          ),
                    initialZoom: 13,
                    onTap: isSimulating ? null : _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gpsemulator.app',
                      tileBuilder: _darkTileBuilder,
                    ),

                    // Route line
                    if (waypoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: waypoints
                                .map((p) => LatLng(p.latitude, p.longitude))
                                .toList(),
                            strokeWidth: 4,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),

                    // Current location
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            provider.currentLocation.latitude,
                            provider.currentLocation.longitude,
                          ),
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Waypoint markers
                        ...waypoints.asMap().entries.map((e) => Marker(
                          point: LatLng(e.value.latitude, e.value.longitude),
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.key == 0
                                  ? Colors.green
                                  : e.key == waypoints.length - 1
                                      ? const Color(0xFFFF5252)
                                      : theme.colorScheme.secondary,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),

                // Tap hint
                if (!isSimulating && waypoints.isEmpty)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 40,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap on the map to\nadd route waypoints',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add at least 2 points to start',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls
          Container(
            color: const Color(0xFF111827),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waypoints count & route stats
                if (waypoints.isNotEmpty) ...[
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.location_on,
                        label: '${waypoints.length} waypoints',
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        icon: Icons.speed,
                        label: '${_simSpeed.round()} km/h',
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        icon: Icons.loop,
                        label: _loop ? 'Loop ON' : 'Loop OFF',
                        color: _loop ? Colors.orange : Colors.white38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Speed slider
                Row(
                  children: [
                    const Text('Speed:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _simSpeed,
                        min: 1,
                        max: 120,
                        onChanged: (v) => setState(() => _simSpeed = v),
                      ),
                    ),
                    Text(
                      '${_simSpeed.round()} km/h',
                      style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                // Loop toggle
                Row(
                  children: [
                    const Text('Loop route:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                    Switch(
                      value: _loop,
                      onChanged: isSimulating ? null : (v) => setState(() => _loop = v),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Start/Stop button
                SizedBox(
                  width: double.infinity,
                  child: isSimulating
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5252).withOpacity(0.15),
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: provider.stopMockLocation,
                          icon: const Icon(Icons.stop_circle_outlined, size: 20),
                          label: const Text(
                            'STOP SIMULATION',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: waypoints.length >= 2
                              ? () => provider.startRouteSimulation(
                                    speedKmh: _simSpeed,
                                    loop: _loop,
                                  )
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            waypoints.length < 2
                                ? 'ADD ${2 - waypoints.length} MORE POINT${waypoints.length == 1 ? '' : 'S'}'
                                : 'START ROUTE SIMULATION',
                            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkTileBuilder(BuildContext ctx, Widget tile, TileImage img) {
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

  Future<String?> _showSaveDialog(BuildContext context) {
    final ctrl = TextEditingController(text: 'My Route ${DateTime.now().day}/${DateTime.now().month}');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Save Route', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Route name',
            hintText: 'My commute route',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
