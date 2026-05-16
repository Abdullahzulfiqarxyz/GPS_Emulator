// lib/widgets/coordinate_input_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';

class CoordinateInputSheet extends StatefulWidget {
  const CoordinateInputSheet({super.key});

  @override
  State<CoordinateInputSheet> createState() => _CoordinateInputSheetState();
}

class _CoordinateInputSheetState extends State<CoordinateInputSheet> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _labelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Popular preset locations
  static const _presets = [
    ('New York', 40.7128, -74.0060),
    ('London', 51.5074, -0.1278),
    ('Tokyo', 35.6762, 139.6503),
    ('Paris', 48.8566, 2.3522),
    ('Sydney', -33.8688, 151.2093),
    ('Dubai', 25.2048, 55.2708),
    ('Singapore', 1.3521, 103.8198),
    ('Los Angeles', 34.0522, -118.2437),
  ];

  @override
  void initState() {
    super.initState();
    final loc = context.read<GpsProvider>().currentLocation;
    _latController.text = loc.latitude.toStringAsFixed(6);
    _lngController.text = loc.longitude.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;

    context.read<GpsProvider>().setLocation(
      lat,
      lng,
      label: _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Set Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter coordinates or pick a preset city',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Preset city chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final preset = _presets[i];
                return GestureDetector(
                  onTap: () {
                    _latController.text = preset.$2.toStringAsFixed(6);
                    _lngController.text = preset.$3.toStringAsFixed(6);
                    _labelController.text = preset.$1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      preset.$1,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '37.7749',
                          prefixIcon: Icon(Icons.swap_vert, size: 18),
                        ),
                        validator: (v) {
                          final d = double.tryParse(v?.trim() ?? '');
                          if (d == null) return 'Invalid';
                          if (d < -90 || d > 90) return '-90 to 90';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '-122.4194',
                          prefixIcon: Icon(Icons.swap_horiz, size: 18),
                        ),
                        validator: (v) {
                          final d = double.tryParse(v?.trim() ?? '');
                          if (d == null) return 'Invalid';
                          if (d < -180 || d > 180) return '-180 to 180';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'My secret location',
                    prefixIcon: Icon(Icons.label_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('SET LOCATION'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
