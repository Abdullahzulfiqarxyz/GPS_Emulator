// lib/screens/saved_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';
import '../models/location_point.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Saved'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 6),
                  Text('Locations (${provider.savedLocations.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route, size: 16),
                  const SizedBox(width: 6),
                  Text('Routes (${provider.savedRoutes.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LocationsTab(provider: provider),
          _RoutesTab(provider: provider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: const Color(0xFF0A0E1A),
        onPressed: () => _showSaveCurrentDialog(context, provider),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Save Current', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _showSaveCurrentDialog(BuildContext context, GpsProvider provider) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Save Location', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${provider.currentLocation.latitude.toStringAsFixed(6)}, ${provider.currentLocation.longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Label', hintText: 'Home, Work, etc.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.isEmpty ? 'Location' : ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null) {
      await provider.saveCurrentLocation(name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" saved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _LocationsTab extends StatelessWidget {
  final GpsProvider provider;
  const _LocationsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final locs = provider.savedLocations;
    final theme = Theme.of(context);

    if (locs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No saved locations', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to save\nyour current location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: locs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final loc = locs[i];
        return _LocationCard(
          location: loc,
          onTeleport: () async {
            await provider.loadSavedLocation(loc);
            if (!provider.isActive) await provider.startMockLocation();
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Teleported to ${loc.label ?? 'location'}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onDelete: () => provider.deleteSavedLocation(i),
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  final LocationPoint location;
  final VoidCallback onTeleport;
  final VoidCallback onDelete;

  const _LocationCard({
    required this.location,
    required this.onTeleport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          location.label ?? 'Saved Location',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            if (location.timestamp != null)
              Text(
                _formatDate(location.timestamp!),
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onTeleport,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('GO', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _RoutesTab extends StatelessWidget {
  final GpsProvider provider;
  const _RoutesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final routes = provider.savedRoutes;
    final theme = Theme.of(context);

    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No saved routes', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Create a route in the Route tab\nand save it here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final route = routes[i];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.route, color: theme.colorScheme.secondary, size: 22),
            ),
            title: Text(
              route.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              '${route.waypoints.length} waypoints · ${route.speedKmh.round()} km/h${route.loop ? ' · Loop' : ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    await provider.loadRoute(route);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('"${route.name}" loaded into Route tab'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('LOAD', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => provider.deleteSavedRoute(i),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
