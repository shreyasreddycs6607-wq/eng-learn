enum AudioPlaybackStatus { idle, loading, playing, paused, completed, error }

/// Strongly-typed playback state for [AudioService] — no `dynamic`/maps.
/// One instance describes the single shared player's current session.
class AudioState {
  final AudioPlaybackStatus status;
  final String? currentAsset;
  final Duration position;
  final Duration duration;
  final double speed;

  const AudioState({
    required this.status,
    this.currentAsset,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  const AudioState.idle({double speed = 1.0}) : this(status: AudioPlaybackStatus.idle, speed: speed);

  bool get isActive => status == AudioPlaybackStatus.playing || status == AudioPlaybackStatus.paused;

  AudioState copyWith({
    AudioPlaybackStatus? status,
    String? currentAsset,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return AudioState(
      status: status ?? this.status,
      currentAsset: currentAsset ?? this.currentAsset,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }
}
