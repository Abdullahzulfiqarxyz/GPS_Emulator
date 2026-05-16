// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Mock Location'),

          _SettingsCard(children: [
            _SliderTile(
              icon: Icons.radar,
              title: 'GPS Accuracy',
              subtitle: 'Simulated accuracy radius',
              value: provider.accuracy,
              min: 1,
              max: 50,
              unit: 'm',
              onChanged: provider.setAccuracy,
            ),
            const Divider(color: Colors.white12, height: 1),
            _SliderTile(
              icon: Icons.timer_outlined,
              title: 'Update Interval',
              subtitle: 'How often location is pushed',
              value: provider.updateIntervalMs.toDouble(),
              min: 100,
              max: 5000,
              unit: 'ms',
              onChanged: (v) => provider.setUpdateInterval(v.round()),
            ),
            const Divider(color: Colors.white12, height: 1),
            _SliderTile(
              icon: Icons.explore_outlined,
              title: 'Bearing',
              subtitle: 'Direction of travel (0° = North)',
              value: provider.bearing,
              min: 0,
              max: 359,
              unit: '°',
              onChanged: provider.setBearing,
            ),
          ]),

          const SizedBox(height: 24),
          _SectionHeader('How To Use'),

          _SettingsCard(children: [
            _InfoTile(
              step: '1',
              title: 'Enable Developer Options',
              body: 'Go to Settings → About Phone → tap Build Number 7 times to enable Developer Options.',
            ),
            const Divider(color: Colors.white12, height: 1),
            _InfoTile(
              step: '2',
              title: 'Set Mock Location App',
              body: 'Go to Settings → Developer Options → Mock Location App → Select "GPS Emulator".',
            ),
            const Divider(color: Colors.white12, height: 1),
            _InfoTile(
              step: '3',
              title: 'Pick Your Location',
              body: 'Tap anywhere on the map in the Map tab, or enter coordinates manually.',
            ),
            const Divider(color: Colors.white12, height: 1),
            _InfoTile(
              step: '4',
              title: 'Start Spoofing',
              body: 'Press the green START SPOOFING button. Your device will report the fake location to all apps.',
            ),
          ]),

          const SizedBox(height: 24),
          _SectionHeader('About'),

          _SettingsCard(children: [
            _AboutTile(
              icon: Icons.gps_fixed,
              title: 'GPS Emulator',
              subtitle: 'Version 1.0.0',
            ),
            const Divider(color: Colors.white12, height: 1),
            _AboutTile(
              icon: Icons.info_outline,
              title: 'Mock Location API',
              subtitle: 'Android LocationManager.setTestProviderLocation',
            ),
            const Divider(color: Colors.white12, height: 1),
            _AboutTile(
              icon: Icons.map_outlined,
              title: 'Map Provider',
              subtitle: 'OpenStreetMap (No API key needed)',
            ),
          ]),

          const SizedBox(height: 32),

          // Warning card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Notice',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'GPS spoofing may violate terms of service of apps that use location. Use responsibly and only for testing, development, or privacy purposes.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: children),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String step;
  final String title;
  final String body;

  const _InfoTile({required this.step, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
