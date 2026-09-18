import 'package:flutter/material.dart';
import '../core/services/app_services.dart';
import '../core/theme/app_theme.dart';
import '../models/audio_state.dart';
import '../services/audio_service.dart';

/// Simple normal/slow toggle — kept to two speeds so it never competes for
/// attention with the main play button. Persists on the shared AudioService
/// until changed again, per screen.
class AudioSpeedControl extends StatelessWidget {
  static const _speeds = [1.0, 0.75];

  final AudioService? audioService;

  const AudioSpeedControl({super.key, this.audioService});

  @override
  Widget build(BuildContext context) {
    final service = audioService ?? appServices.audio;
    return StreamBuilder<AudioState>(
      stream: service.stateStream,
      initialData: service.state,
      builder: (context, snapshot) {
        final current = snapshot.data?.speed ?? 1.0;
        return Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 8,
          children: _speeds.map((speed) => _chip(context, service, speed, speed == current)).toList(),
        );
      },
    );
  }

  Widget _chip(BuildContext context, AudioService service, double speed, bool selected) {
    final label = speed == 1.0 ? 'Normal' : 'Slow';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        label: speed == 1.0 ? 'Normal speed' : 'Slow down audio',
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => service.setSpeed(speed),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(color: selected ? AppColors.primary : AppColors.textSecondary, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
