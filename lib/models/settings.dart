import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum TrackingMode { perFlight, tailNumber }

class AppSettings {
  String tail;
  String pilot;
  TrackingMode mode;

  AppSettings({
    this.tail = '',
    this.pilot = '',
    this.mode = TrackingMode.perFlight,
  });

  /// Generate a UUID track ID. Always a UUID for the push API.
  String generateTrackId() {
    return const Uuid().v4();
  }

  /// Get the share URL based on mode.
  /// Per-flight: uses the UUID (one-time link).
  /// Tail number: uses the N-number (persistent link).
  String shareUrl(String trackId) {
    if (mode == TrackingMode.tailNumber) {
      return 'http://awoslog.com/track/${tail.toUpperCase().trim()}';
    }
    return 'http://awoslog.com/track/$trackId';
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tail', tail);
    await prefs.setString('pilot', pilot);
    await prefs.setString('mode', mode == TrackingMode.perFlight ? 'perFlight' : 'tailNumber');
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('mode') ?? 'perFlight';
    return AppSettings(
      tail: prefs.getString('tail') ?? '',
      pilot: prefs.getString('pilot') ?? '',
      mode: modeStr == 'tailNumber' ? TrackingMode.tailNumber : TrackingMode.perFlight,
    );
  }
}
