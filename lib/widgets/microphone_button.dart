import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/speaking_controller.dart';

/// The reusable microphone control for speaking practice. Communicates
/// state through both icon and text — never color alone.
class MicrophoneButton extends StatelessWidget {
  final SpeakingUiState state;
  final VoidCallback onTap;

  const MicrophoneButton({super.key, required this.state, required this.onTap});

  (IconData, Color, String) get _visual => switch (state) {
        SpeakingUiState.listening => (Icons.fiber_manual_record_rounded, AppColors.incorrect, 'Listening...'),
        SpeakingUiState.processing => (Icons.hourglass_top_rounded, AppColors.textSecondary, 'Checking...'),
        SpeakingUiState.requestingPermission => (Icons.mic_rounded, AppColors.textSecondary, 'Requesting permission...'),
        _ => (Icons.mic_rounded, AppColors.primary, 'Tap to speak'),
      };

  bool get _tappable =>
      state == SpeakingUiState.idle || state == SpeakingUiState.unavailable || state == SpeakingUiState.permissionDenied;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _visual;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: state == SpeakingUiState.listening ? 'Listening, tap to stop' : 'Tap to speak',
          button: true,
          child: GestureDetector(
            onTap: _tappable || state == SpeakingUiState.listening ? onTap : null,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
