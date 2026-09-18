import 'package:flutter/widgets.dart';

/// One place that stops a fast double tap from firing an action twice (two
/// navigations, a skipped lesson card, a double submit). The first tap goes
/// through; another within [window] is ignored. Screens still guard their own
/// state — this is the shared safety net under every primary/secondary button.
mixin TapThrottle<T extends StatefulWidget> on State<T> {
  static const window = Duration(milliseconds: 600);
  DateTime? _lastTap;

  VoidCallback? throttled(VoidCallback? onPressed) {
    if (onPressed == null) return null;
    return () {
      final now = DateTime.now();
      final last = _lastTap;
      if (last != null && now.difference(last) < window) return;
      _lastTap = now;
      onPressed();
    };
  }
}
