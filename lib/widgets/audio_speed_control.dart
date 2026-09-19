import 'package:flutter/material.dart';
import '../core/services/app_services.dart';
import '../core/theme/app_theme.dart';
import '../models/audio_state.dart';
import '../services/audio_service.dart';

/// Normal / Slow as a small segmented control — two speeds only, so it never
/// competes with the main play button. The choice stays on the shared
/// AudioService until changed again.
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
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(26)),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: _speeds.map((speed) => _segment(service, speed, speed == current)).toList(),
          ),
        );
      },
    );
  }

  Widget _segment(AudioService service, double speed, bool selected) {
    final label = speed == 1.0 ? 'Normal' : 'Slow';
    return Semantics(
      label: speed == 1.0 ? 'Normal speed' : 'Slow down audio',
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => service.setSpeed(speed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          // widthFactor/heightFactor keep the segment as wide as its label
          // (a plain alignment would stretch it across the whole row).
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
