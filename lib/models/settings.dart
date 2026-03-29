import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum TrackingMode { perFlight, tailNumber, groupFlight }

class AppSettings {
  String tail;
  String pilot;
  TrackingMode mode;
  String notifyPhone;
  String groupId;

  AppSettings({
    this.tail = '',
    this.pilot = '',
    this.mode = TrackingMode.perFlight,
    this.notifyPhone = '',
    this.groupId = '',
  });

  /// Generate a UUID track ID. Always a UUID for the push API.
  String generateTrackId() {
    return const Uuid().v4();
  }

  /// Get the share URL based on mode.
  String shareUrl(String trackId) {
    if (mode == TrackingMode.groupFlight) {
      return 'https://awoslog.com/track/g/${groupId.trim().toUpperCase()}';
    }
    if (mode == TrackingMode.tailNumber) {
      return 'https://awoslog.com/track/${tail.toUpperCase().trim()}';
    }
    return 'https://awoslog.com/track/$trackId';
  }

  /// Whether this session has a group ID set.
  bool get hasGroup => groupId.trim().isNotEmpty;

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tail', tail);
    await prefs.setString('pilot', pilot);
    await prefs.setString('mode', mode == TrackingMode.perFlight ? 'perFlight' : mode == TrackingMode.tailNumber ? 'tailNumber' : 'groupFlight');
    await prefs.setString('notifyPhone', notifyPhone);
    await prefs.setString('groupId', groupId);
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('mode') ?? 'perFlight';
    final mode = modeStr == 'tailNumber'
        ? TrackingMode.tailNumber
        : modeStr == 'groupFlight'
            ? TrackingMode.groupFlight
            : TrackingMode.perFlight;
    return AppSettings(
      tail: prefs.getString('tail') ?? '',
      pilot: prefs.getString('pilot') ?? '',
      mode: mode,
      notifyPhone: prefs.getString('notifyPhone') ?? '',
      groupId: prefs.getString('groupId') ?? '',
    );
  }
}
