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

  /// Generate the appropriate track ID based on mode.
  String generateTrackId() {
    if (mode == TrackingMode.tailNumber) {
      return tail.toUpperCase().trim();
    }
    return const Uuid().v4();
  }

  /// Get the share URL for a given track ID.
  String shareUrl(String trackId) {
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
