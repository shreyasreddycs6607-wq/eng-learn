import 'package:flutter/material.dart';
import '../core/services/app_services.dart';
import '../core/theme/app_theme.dart';
import '../models/audio_state.dart';
import '../services/audio_service.dart';

/// The one reusable audio control used everywhere in the app — vocabulary
/// cards, sentence patterns, listening/speaking exercises. Renders nothing
/// when [audioPath] is null (no audio configured is valid, never an error).
/// Reacts to the shared AudioService's state stream so it always reflects
/// whether *this* clip specifically is the one currently loading/playing.
class AudioPlayerButton extends StatelessWidget {
  final String? audioPath;

  /// Spoken description used in the semantic label and, when [showLabel] is
  /// true, as visible text next to the icon (e.g. "English", "Telugu explanation").
  final String label;
  final bool showLabel;
  final double size;

  /// Defaults to the shared app-wide player; tests inject a fake here
  /// instead of touching the global appServices singleton.
  final AudioService? audioService;

  const AudioPlayerButton({
    super.key,
    required this.audioPath,
    required this.label,
    this.showLabel = false,
    this.size = 72,
    this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    final path = audioPath;
    if (path == null) return const SizedBox.shrink();
    final service = audioService ?? appServices.audio;

    return StreamBuilder<AudioState>(
      stream: service.stateStream,
      initialData: service.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const AudioState.idle();
        final isMine = state.currentAsset == path;
        final status = isMine ? state.status : AudioPlaybackStatus.idle;
        return showLabel
            ? _buildPill(context, service, path, status)
            : _buildCircle(context, service, path, status);
      },
    );
  }

  (IconData, String) _iconAndAction(AudioPlaybackStatus status) {
    return switch (status) {
      AudioPlaybackStatus.idle => (Icons.volume_up_rounded, 'Play $label'),
      AudioPlaybackStatus.loading => (Icons.hourglass_top_rounded, 'Loading $label'),
      AudioPlaybackStatus.playing => (Icons.pause_rounded, 'Pause $label'),
      AudioPlaybackStatus.paused => (Icons.play_arrow_rounded, 'Resume $label'),
      AudioPlaybackStatus.completed => (Icons.replay_rounded, 'Replay $label'),
      AudioPlaybackStatus.error => (Icons.refresh_rounded, 'Couldn\'t play $label — tap to retry'),
    };
  }

  Future<void> _handleTap(AudioService service, String path, AudioPlaybackStatus status) async {
    switch (status) {
      case AudioPlaybackStatus.playing:
        await service.pause();
      case AudioPlaybackStatus.paused:
        await service.resume();
      case AudioPlaybackStatus.completed:
        await service.replay();
      case AudioPlaybackStatus.idle:
      case AudioPlaybackStatus.error:
        await service.play(path);
      case AudioPlaybackStatus.loading:
        break;
    }
  }

  Widget _buildCircle(BuildContext context, AudioService service, String path, AudioPlaybackStatus status) {
    final (icon, semanticLabel) = _iconAndAction(status);
    final color = status == AudioPlaybackStatus.error ? AppColors.incorrect : AppColors.primary;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: status == AudioPlaybackStatus.loading ? null : () => _handleTap(service, path, status),
          child: Padding(
            padding: EdgeInsets.all(size / 4),
            child: status == AudioPlaybackStatus.loading
                ? SizedBox(
                    width: size / 2,
                    height: size / 2,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(icon, size: size / 2, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, AudioService service, String path, AudioPlaybackStatus status) {
    final (icon, semanticLabel) = _iconAndAction(status);
    final color = status == AudioPlaybackStatus.error ? AppColors.incorrect : AppColors.textSecondary;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: status == AudioPlaybackStatus.loading ? null : () => _handleTap(service, path, status),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              status == AudioPlaybackStatus.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                status == AudioPlaybackStatus.error ? 'Couldn\'t play audio' : label,
                style: TextStyle(fontSize: 15, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
