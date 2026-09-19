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
    final service = audioService ?? appServices.audio;
    final path = audioPath;
    // No path, or no recording bundled for it (yet): show nothing, not a broken button.
    if (path == null || !service.isBundled(path)) return const SizedBox.shrink();

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
    final failed = status == AudioPlaybackStatus.error;
    final background = failed ? AppColors.incorrectSoft : AppColors.primary;
    final foreground = failed ? AppColors.incorrect : Colors.white;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: failed
              ? null
              : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: status == AudioPlaybackStatus.loading ? null : () => _handleTap(service, path, status),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: status == AudioPlaybackStatus.loading
                    ? SizedBox(
                        width: size / 2.4,
                        height: size / 2.4,
                        child: CircularProgressIndicator(strokeWidth: 3, color: foreground),
                      )
                    : Icon(icon, size: size * 0.5, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, AudioService service, String path, AudioPlaybackStatus status) {
    final (icon, semanticLabel) = _iconAndAction(status);
    final failed = status == AudioPlaybackStatus.error;
    final color = failed ? AppColors.incorrect : AppColors.primary;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: failed ? AppColors.incorrectSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: status == AudioPlaybackStatus.loading ? null : () => _handleTap(service, path, status),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                status == AudioPlaybackStatus.loading
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: color))
                    : Icon(icon, size: 24, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    failed ? "Couldn't play audio" : label,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
