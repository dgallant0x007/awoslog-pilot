import 'package:flutter_test/flutter_test.dart';
import 'package:awoslog_pilot/models/aircraft.dart';
import 'package:awoslog_pilot/utils/traffic_utils.dart';

Aircraft _makeAircraft({
  required double lat,
  required double lon,
  required int altitude,
  bool onGround = false,
}) {
  return Aircraft(
    icao24: 'test',
    callsign: 'TEST',
    lat: lat,
    lon: lon,
    altitude: altitude,
    velocity: 100,
    heading: 0.0,
    onGround: onGround,
    type: '',
    category: '',
    reg: '',
  );
}

void main() {
  group('TrafficTarget display', () {
    test('formats with N-number and negative altitude delta', () {
      final target =
          TrafficTarget(clock: 2, distanceNm: 3.0, relativeAltFt: -200, ident: 'N335RK');
      expect(target.display, 'N335RK  2:00@3NM -200');
    });

    test('formats with positive altitude delta', () {
      final target =
          TrafficTarget(clock: 12, distanceNm: 8.0, relativeAltFt: 2100, ident: 'N123AB');
      expect(target.display, 'N123AB 12:00@8NM +2100');
    });

    test('formats level traffic without ident', () {
      final target =
          TrafficTarget(clock: 9, distanceNm: 5.0, relativeAltFt: 50, ident: '');
      expect(target.display, ' 9:00@5NM level');
    });

    test('rounds to nearest 100', () {
      final target =
          TrafficTarget(clock: 3, distanceNm: 10.0, relativeAltFt: 4250, ident: 'UAL456');
      expect(target.display, 'UAL456  3:00@10NM +4300');
    });
  });

  group('processTraffic', () {
    test('filters out Class A traffic above 18000', () {
      final aircraft = [
        _makeAircraft(lat: 38.82, lon: -105.89, altitude: 8000),
        _makeAircraft(lat: 38.83, lon: -105.88, altitude: 35000),
      ];
      final targets = processTraffic(
        aircraft: aircraft,
        myLat: 38.8249,
        myLon: -105.8928,
        myAltFt: 7840,
        myTrackDeg: 247.0,
      );
      expect(targets.length, 1);
    });

    test('sorts by distance closest first', () {
      final aircraft = [
        _makeAircraft(lat: 39.0, lon: -105.8, altitude: 8000),
        _makeAircraft(lat: 38.83, lon: -105.89, altitude: 8000),
      ];
      final targets = processTraffic(
        aircraft: aircraft,
        myLat: 38.8249,
        myLon: -105.8928,
        myAltFt: 7840,
        myTrackDeg: 247.0,
      );
      expect(targets.length, 2);
      expect(targets[0].distanceNm, lessThan(targets[1].distanceNm));
    });

    test('excludes on-ground aircraft', () {
      final aircraft = [
        _makeAircraft(lat: 38.83, lon: -105.89, altitude: 0, onGround: true),
      ];
      final targets = processTraffic(
        aircraft: aircraft,
        myLat: 38.8249,
        myLon: -105.8928,
        myAltFt: 7840,
        myTrackDeg: 247.0,
      );
      expect(targets, isEmpty);
    });
  });
}
