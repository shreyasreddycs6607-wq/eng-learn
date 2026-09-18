/// idle <-> listening -> processing -> recognized is the normal cycle.
/// unavailable/permissionDenied/error are terminal for that attempt but
/// never for the app — the UI always has a Listen+repeat fallback.
enum SpeechRecognitionState {
  unavailable,
  idle,
  requestingPermission,
  listening,
  processing,
  recognized,
  permissionDenied,
  error,
}
