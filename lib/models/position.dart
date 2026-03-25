class PilotPosition {
  final double lat;
  final double lon;
  final int altitude; // feet
  final int speed; // knots
  final double heading; // degrees true
  final double accuracy; // meters
  final int timestamp; // unix seconds

  PilotPosition({
    required this.lat,
    required this.lon,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'timestamp': timestamp,
      };

  /// Convert from geolocator Position to PilotPosition.
  /// Geolocator gives: lat/lon in degrees, altitude in meters, speed in m/s, heading in degrees.
  factory PilotPosition.fromGeolocator({
    required double lat,
    required double lon,
    required double altitudeMeters,
    required double speedMps,
    required double heading,
    required double accuracy,
  }) {
    return PilotPosition(
      lat: lat,
      lon: lon,
      altitude: (altitudeMeters * 3.28084).round(), // meters to feet
      speed: (speedMps * 1.94384).round(), // m/s to knots
      heading: heading,
      accuracy: accuracy,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
