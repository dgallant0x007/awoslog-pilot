import 'package:flutter_test/flutter_test.dart';
import 'package:awoslog_pilot/models/aircraft.dart';
import 'package:awoslog_pilot/models/station.dart';

void main() {
  group('Aircraft', () {
    test('parses from JSON', () {
      final json = {
        'icao24': 'a0c0f6',
        'callsign': 'N12345',
        'lat': 38.8249,
        'lon': -105.8928,
        'altitude': 8500,
        'velocity': 95,
        'heading': 247.0,
        'on_ground': false,
        'type': 'PA18',
        'category': 'A1',
        'reg': 'N12345',
      };
      final aircraft = Aircraft.fromJson(json);
      expect(aircraft.icao24, 'a0c0f6');
      expect(aircraft.altitude, 8500);
      expect(aircraft.onGround, false);
    });

    test('parses Stratux schema using hex and speed', () {
      // /api/stratux/aircraft uses `hex` (uppercase) and `speed`
      // instead of airplanes.live's `icao24` (lowercase) and `velocity`.
      final json = {
        'hex': 'A0C0F6',
        'callsign': 'N12345',
        'lat': 38.82,
        'lon': -105.89,
        'altitude': 8500,
        'speed': 95,
        'heading': 247.0,
        'reg': 'N12345',
        'type': 'PA18',
        'source': 'beast-bee0003c-a196-0046-bee0-003ca1960046',
      };
      final aircraft = Aircraft.fromJson(json);
      expect(aircraft.icao24, 'A0C0F6');
      expect(aircraft.velocity, 95);
      expect(aircraft.altitude, 8500);
    });

    test('source defaults to network when absent', () {
      final aircraft = Aircraft.fromJson({
        'icao24': 'a0c0f6',
        'lat': 38.0,
        'lon': -105.0,
      });
      expect(aircraft.source, AircraftSource.network);
    });

    test('source is adsb when JSON source field starts with beast or stratux', () {
      final beast = Aircraft.fromJson({
        'hex': 'A0C0F6',
        'lat': 38.0,
        'lon': -105.0,
        'source': 'beast-abc123',
      });
      final stratux = Aircraft.fromJson({
        'hex': 'A0C0F6',
        'lat': 38.0,
        'lon': -105.0,
        'source': 'stratux-xyz',
      });
      expect(beast.source, AircraftSource.adsb);
      expect(stratux.source, AircraftSource.adsb);
    });
  });

  group('Port', () {
    test('parses from JSON', () {
      final json = {
        'id': 'XMEX',
        'city': 'Mexican Mountain',
        'state': 'UT',
        'lat': 38.8249,
        'lon': -105.8928,
        'elevation': 5820,
        'link': '',
        'community': true,
      };
      final port = Port.fromJson(json);
      expect(port.id, 'XMEX');
      expect(port.elevation, 5820);
      expect(port.community, true);
    });

    test('community defaults to false', () {
      final json = {
        'id': 'KHVE',
        'city': 'Hanksville',
        'state': 'UT',
        'lat': 38.4,
        'lon': -110.7,
        'elevation': 4444,
        'link': '',
      };
      final port = Port.fromJson(json);
      expect(port.community, false);
    });
  });

  group('LatestMetar', () {
    test('parses from JSON', () {
      final json = {
        'station': 'XMEX',
        'ceiling': 25000,
        'visibility': 10.0,
        'wind_speed': 8,
        'wind_gust': 0,
        'wind_angle': 270,
        'temp_c': 31,
        'barometer': 26.38,
        'wx': '',
      };
      final metar = LatestMetar.fromJson(json);
      expect(metar.windSpeed, 8);
      expect(metar.tempC, 31);
      expect(metar.barometer, 26.38);
    });
  });

  group('Station windDisplay', () {
    test('shows wind with gust', () {
      final station = Station(
        id: 'XHID', city: '', state: '', lat: 0, lon: 0,
        elevation: 4900, community: true, distanceNm: 8.4,
        ceiling: 25000, visibility: 10.0,
        windSpeed: 14, windGust: 22, windAngle: 190,
        tempC: 28, barometer: 26.31, wx: '',
        densityAltitude: 8400,
      );
      expect(station.windDisplay, '190@14G22');
    });

    test('zero-pads direction to 3 digits', () {
      final station = Station(
        id: 'TEST', city: '', state: '', lat: 0, lon: 0,
        elevation: 5000, community: true, distanceNm: 1.0,
        ceiling: 25000, visibility: 10.0,
        windSpeed: 8, windGust: 0, windAngle: 70,
        tempC: 20, barometer: 29.92, wx: '',
        densityAltitude: 5000,
      );
      expect(station.windDisplay, '070@8');
    });

    test('shows calm when speed is 0', () {
      final station = Station(
        id: 'XMIN', city: '', state: '', lat: 0, lon: 0,
        elevation: 4100, community: true, distanceNm: 14.7,
        ceiling: 25000, visibility: 10.0,
        windSpeed: 0, windGust: 0, windAngle: 0,
        tempC: 26, barometer: 26.44, wx: '',
        densityAltitude: 7200,
      );
      expect(station.windDisplay, 'calm');
    });
  });
}
