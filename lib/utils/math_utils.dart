import 'dart:math';

const double _nmPerRadian = 3440.065;
const double _deg2rad = pi / 180.0;
const double _rad2deg = 180.0 / pi;

/// Great-circle distance in nautical miles between two lat/lon points.
double haversineNm(double lat1, double lon1, double lat2, double lon2) {
  final dLat = (lat2 - lat1) * _deg2rad;
  final dLon = (lon2 - lon1) * _deg2rad;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * _deg2rad) * cos(lat2 * _deg2rad) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return c * _nmPerRadian;
}

/// Initial bearing in degrees (0-360) from point 1 to point 2.
double bearing(double lat1, double lon1, double lat2, double lon2) {
  final dLon = (lon2 - lon1) * _deg2rad;
  final y = sin(dLon) * cos(lat2 * _deg2rad);
  final x = cos(lat1 * _deg2rad) * sin(lat2 * _deg2rad) -
      sin(lat1 * _deg2rad) * cos(lat2 * _deg2rad) * cos(dLon);
  return (atan2(y, x) * _rad2deg + 360) % 360;
}

/// Convert absolute bearing to clock position (1-12) relative to track.
int clockPosition(double trackDeg, double bearingDeg) {
  final relative = (bearingDeg - trackDeg + 360) % 360;
  final hour = ((relative + 15) % 360) ~/ 30;
  return hour == 0 ? 12 : hour;
}

/// Pressure altitude in feet from barometric pressure in inHg.
double pressureAltitude(double pressureInHg) {
  return (29.92 - pressureInHg) * 1000;
}

/// Density altitude in feet from phone barometer station pressure.
/// Phone barometer gives station pressure (actual pressure at your location),
/// so pressureAltitude() alone gives your pressure altitude — do NOT add GPS alt.
int densityAltitude(double stationPressureInHg, double tempC) {
  final pa = pressureAltitude(stationPressureInHg);
  final isaTemp = 15.0 - (pa * 2.0 / 1000.0);
  return (pa + 120.0 * (tempC - isaTemp)).round();
}

/// Density altitude at a station using its elevation, pressure, and temperature.
int stationDensityAltitude(int elevationFt, double pressureInHg, double tempC) {
  if (pressureInHg <= 0) return elevationFt;
  final pa = pressureAltitude(pressureInHg) + elevationFt;
  final isaTemp = 15.0 - (pa * 2.0 / 1000.0);
  return (pa + 120.0 * (tempC - isaTemp)).round();
}

enum FlightCategory { vfr, mvfr, ifr, lifr }

/// FAA flight category from ceiling (ft AGL) and visibility (statute miles).
FlightCategory flightCategory(int ceiling, double visibility) {
  if (ceiling < 500 || visibility < 1.0) return FlightCategory.lifr;
  if (ceiling < 1000 || visibility < 3.0) return FlightCategory.ifr;
  if (ceiling <= 3000 || visibility <= 5.0) return FlightCategory.mvfr;
  return FlightCategory.vfr;
}
