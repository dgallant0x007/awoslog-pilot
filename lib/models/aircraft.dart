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
  });

  factory Aircraft.fromJson(Map<String, dynamic> json) {
    return Aircraft(
      icao24: json['icao24'] as String? ?? '',
      callsign: json['callsign'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      altitude: json['altitude'] as int? ?? 0,
      velocity: json['velocity'] as int? ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      onGround: json['on_ground'] as bool? ?? false,
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      reg: json['reg'] as String? ?? '',
    );
  }
}
