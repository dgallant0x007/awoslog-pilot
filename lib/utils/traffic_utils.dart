import '../models/aircraft.dart';
import '../config.dart';
import 'math_utils.dart';

class TrafficTarget {
  final int clock;
  final double distanceNm;
  final int relativeAltFt;

  const TrafficTarget({
    required this.clock,
    required this.distanceNm,
    required this.relativeAltFt,
  });

  String get _altLabel {
    if (relativeAltFt.abs() < 100) return 'level';
    final sign = relativeAltFt > 0 ? '+' : '';
    // Round to nearest 100 for readability
    final rounded = (relativeAltFt / 100).round() * 100;
    return '$sign$rounded';
  }

  String get display {
    return '$clock:00 @ ${distanceNm.toStringAsFixed(0)}NM $_altLabel';
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
    if (ac.altitude > Config.trafficMaxAltitudeFt) continue;

    final relAlt = ac.altitude - myAltFt.round();
    if (relAlt.abs() > Config.trafficAltitudeFilterFt) continue;

    final dist = haversineNm(myLat, myLon, ac.lat, ac.lon);
    if (dist > Config.trafficRadiusNm) continue;

    final bear = bearing(myLat, myLon, ac.lat, ac.lon);
    final clock = clockPosition(myTrackDeg, bear);

    targets.add(TrafficTarget(
      clock: clock,
      distanceNm: dist,
      relativeAltFt: relAlt,
    ));
  }

  targets.sort((a, b) => a.distanceNm.compareTo(b.distanceNm));
  return targets;
}
