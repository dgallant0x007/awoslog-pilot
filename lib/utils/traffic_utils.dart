import '../models/aircraft.dart';
import '../config.dart';
import 'math_utils.dart';

class TrafficTarget {
  final int clock;
  final double distanceNm;
  final int relativeAltFt;
  final String ident;

  const TrafficTarget({
    required this.clock,
    required this.distanceNm,
    required this.relativeAltFt,
    required this.ident,
  });

  String get _altLabel {
    if (relativeAltFt.abs() < 100) return 'level';
    final sign = relativeAltFt > 0 ? '+' : '';
    // Round to nearest 100 for readability
    final rounded = (relativeAltFt / 100).round() * 100;
    return '$sign$rounded';
  }

  String get display {
    final clockStr = clock.toString().padLeft(2);
    final pos = '$clockStr:00@${distanceNm.toStringAsFixed(0)}NM $_altLabel';
    return ident.isNotEmpty ? '$ident $pos' : pos;
  }
}

List<TrafficTarget> processTraffic({
  required List<Aircraft> aircraft,
  required double myLat,
  required double myLon,
  required double myAltFt,
  required double myTrackDeg,
}) {
  final targets = <TrafficTarget>[];

  for (final ac in aircraft) {
    if (ac.onGround) continue;
    if (ac.lat == 0 && ac.lon == 0) continue;
    if (ac.altitude > Config.trafficMaxAltitudeFt) continue;

    final relAlt = ac.altitude - myAltFt.round();
    if (relAlt.abs() > Config.trafficAltitudeFilterFt) continue;

    final dist = haversineNm(myLat, myLon, ac.lat, ac.lon);
    if (dist > Config.trafficRadiusNm) continue;

    final bear = bearing(myLat, myLon, ac.lat, ac.lon);
    final clock = clockPosition(myTrackDeg, bear);

    // Prefer registration (N-number), fall back to callsign
    final ident = ac.reg.isNotEmpty ? ac.reg : ac.callsign;

    targets.add(TrafficTarget(
      clock: clock,
      distanceNm: dist,
      relativeAltFt: relAlt,
      ident: ident,
    ));
  }

  targets.sort((a, b) => a.distanceNm.compareTo(b.distanceNm));
  return targets;
}

/// Merge network (airplanes.live) and Stratux (local Beast) aircraft lists.
/// Dedupes by uppercase hex; on collision the Stratux entry wins because
/// the local receiver has fresher data than the aggregator API.
List<Aircraft> mergeAircraft({
  required List<Aircraft> network,
  required List<Aircraft> stratux,
}) {
  final byHex = <String, Aircraft>{};
  for (final ac in network) {
    byHex[ac.icao24.toUpperCase()] = ac;
  }
  for (final ac in stratux) {
    byHex[ac.icao24.toUpperCase()] = ac;
  }
  return byHex.values.toList();
}
