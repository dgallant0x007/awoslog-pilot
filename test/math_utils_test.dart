import 'package:flutter_test/flutter_test.dart';
import 'package:awoslog_pilot/utils/math_utils.dart';

void main() {
  group('haversineNm', () {
    test('same point returns 0', () {
      expect(haversineNm(38.0, -105.0, 38.0, -105.0), 0.0);
    });

    test('known distance Denver to Colorado Springs ~63nm', () {
      final d = haversineNm(39.8561, -104.6737, 38.8058, -104.7005);
      expect(d, closeTo(63.0, 3.0));
    });

    test('1 minute of latitude is about 1nm', () {
      final d = haversineNm(38.0, -105.0, 38.0167, -105.0);
      expect(d, closeTo(1.0, 0.1));
    });
  });

  group('clockPosition', () {
    test('target directly ahead is 12:00', () {
      expect(clockPosition(0.0, 0.0), 12);
    });

    test('target to the right is 3:00', () {
      expect(clockPosition(0.0, 90.0), 3);
    });

    test('target behind is 6:00', () {
      expect(clockPosition(0.0, 180.0), 6);
    });

    test('target to the left is 9:00', () {
      expect(clockPosition(0.0, 270.0), 9);
    });

    test('track 247 with target at same bearing is 12:00', () {
      expect(clockPosition(247.0, 247.0), 12);
    });

    test('wraps around correctly', () {
      expect(clockPosition(350.0, 20.0), 1);
    });
  });

  group('bearing', () {
    test('due north', () {
      expect(bearing(38.0, -105.0, 39.0, -105.0), closeTo(0.0, 1.0));
    });

    test('due east', () {
      expect(bearing(38.0, -105.0, 38.0, -104.0), closeTo(90.0, 5.0));
    });
  });

  group('densityAltitude', () {
    test('standard conditions at sea level', () {
      final da = densityAltitude(29.92, 15.0);
      expect(da, closeTo(0, 200));
    });

    test('hot day at high elevation', () {
      // Station pressure ~23.98 inHg at ~6000 ft
      // PA = (29.92 - 23.98) * 1000 = 5940
      // ISA at 5940 = 15 - 11.88 = 3.12
      // DA = 5940 + 120 * (35 - 3.12) = 5940 + 3826 = 9766
      final da = densityAltitude(23.98, 35.0);
      expect(da, closeTo(9766, 300));
    });
  });

  group('flightCategory', () {
    test('VFR', () {
      expect(flightCategory(5000, 10.0), FlightCategory.vfr);
    });

    test('MVFR by ceiling', () {
      expect(flightCategory(2000, 10.0), FlightCategory.mvfr);
    });

    test('IFR by ceiling', () {
      expect(flightCategory(800, 10.0), FlightCategory.ifr);
    });

    test('LIFR', () {
      expect(flightCategory(200, 0.5), FlightCategory.lifr);
    });
  });
}
