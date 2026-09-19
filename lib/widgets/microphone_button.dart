import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/speaking_controller.dart';

/// The reusable microphone control for speaking practice. Communicates state
/// through icon, text AND a soft pulsing ring while listening — never colour alone.
class MicrophoneButton extends StatefulWidget {
  final SpeakingUiState state;
  final VoidCallback onTap;

  const MicrophoneButton({super.key, required this.state, required this.onTap});

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  bool get _listening => widget.state == SpeakingUiState.listening;

  @override
  void initState() {
    super.initState();
    if (_listening) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The animation only ever runs while actually listening.
    if (_listening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  (IconData, Color, String) get _visual => switch (widget.state) {
        SpeakingUiState.listening => (Icons.stop_rounded, AppColors.incorrect, 'Listening...'),
        SpeakingUiState.processing => (Icons.hourglass_top_rounded, AppColors.textSecondary, 'Checking...'),
        SpeakingUiState.requestingPermission => (Icons.mic_rounded, AppColors.textSecondary, 'Requesting permission...'),
        _ => (Icons.mic_rounded, AppColors.primary, 'Tap to speak'),
      };

  bool get _tappable =>
      widget.state == SpeakingUiState.idle ||
      widget.state == SpeakingUiState.unavailable ||
      widget.state == SpeakingUiState.permissionDenied ||
      widget.state == SpeakingUiState.listening;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _visual;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: _listening ? 'Listening, tap to stop' : 'Tap to speak',
          button: true,
          child: GestureDetector(
            onTap: _tappable ? widget.onTap : null,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_listening)
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => Container(
                        width: 104 + 44 * _pulse.value,
                        height: 104 + 44 * _pulse.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.16 * (1 - _pulse.value) + 0.06),
                        ),
                      ),
                    ),
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
