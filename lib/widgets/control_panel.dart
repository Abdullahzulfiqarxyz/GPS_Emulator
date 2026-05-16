// lib/widgets/control_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gps_provider.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onStartStop;
  const ControlPanel({super.key, required this.onStartStop});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GpsProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF5111827),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Speed slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: provider.speedKmh.clamp(0.0, 120.0),
                      min: 0,
                      max: 120,
                      onChanged: provider.setSpeed,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${provider.speedKmh.round()} km/h',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick speed buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 8),
                ...[0, 5, 30, 60, 90, 120].map((spd) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => provider.setSpeed(spd.toDouble()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: provider.speedKmh.round() == spd
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: provider.speedKmh.round() == spd
                              ? theme.colorScheme.primary.withOpacity(0.5)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        spd == 0 ? 'Stop' : '${spd}k',
                        style: TextStyle(
                          color: provider.speedKmh.round() == spd
                              ? theme.colorScheme.primary
                              : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main start/stop button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: provider.isActive
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252).withOpacity(0.15),
                        foregroundColor: const Color(0xFFFF5252),
                        side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onStartStop,
                      icon: const Icon(Icons.stop_circle_outlined, size: 20),
                      label: Text(
                        provider.state == EmulatorState.routeSimulation
                            ? 'STOP ROUTE'
                            : 'STOP SPOOFING',
                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onStartStop,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text(
                        'START SPOOFING',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ),
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.explore,
                  label: '${provider.bearing.round()}°',
                  hint: 'Bearing',
                ),
                _InfoChip(
                  icon: Icons.radar,
                  label: '±${provider.accuracy.round()}m',
                  hint: 'Accuracy',
                ),
                _InfoChip(
                  icon: Icons.timer,
                  label: '${provider.updateIntervalMs}ms',
                  hint: 'Interval',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
