class FlightData {
  final double groundSpeedKt;
  final double trackDeg;
  final double altitudeFt;
  final double lat;
  final double lon;
  final int? densityAltitude;

  const FlightData({
    required this.groundSpeedKt,
    required this.trackDeg,
    required this.altitudeFt,
    required this.lat,
    required this.lon,
    this.densityAltitude,
  });

  static const FlightData empty = FlightData(
    groundSpeedKt: 0, trackDeg: 0, altitudeFt: 0, lat: 0, lon: 0,
  );
}
