enum AircraftSource { network, adsb }

class Aircraft {
  final String icao24;
  final String callsign;
  final double lat;
  final double lon;
  final int altitude;
  final int velocity;
  final double heading;
  final bool onGround;
  final String type;
  final String category;
  final String reg;
  final AircraftSource source;

  const Aircraft({
    required this.icao24,
    required this.callsign,
    required this.lat,
    required this.lon,
    required this.altitude,
    required this.velocity,
    required this.heading,
    required this.onGround,
    required this.type,
    required this.category,
    required this.reg,
    this.source = AircraftSource.network,
  });

  factory Aircraft.fromJson(Map<String, dynamic> json) {
    final src = json['source'] as String?;
    final isAdsb = src != null && (src.startsWith('beast-') || src.startsWith('stratux-'));
    return Aircraft(
      icao24: (json['icao24'] ?? json['hex']) as String? ?? '',
      callsign: json['callsign'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toInt() ?? 0,
      velocity: ((json['velocity'] ?? json['speed']) as num?)?.toInt() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      onGround: json['on_ground'] as bool? ?? false,
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      reg: json['reg'] as String? ?? '',
      source: isAdsb ? AircraftSource.adsb : AircraftSource.network,
    );
  }
}
