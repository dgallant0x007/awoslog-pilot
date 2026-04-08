class Config {
  static const String apiBaseUrl = 'https://awoslog.com';

  // Poll rates
  static const Duration trafficPollFast = Duration(seconds: 3);
  static const Duration trafficPollSlow = Duration(seconds: 8);
  static const Duration stationPollRate = Duration(seconds: 60);
  static const double trafficFastThresholdNm = 5.0;

  // Filters
  static const double trafficRadiusNm = 50.0;
  static const double trafficAltitudeFilterFt = 10000.0;
  static const double trafficMaxAltitudeFt = 18000.0;
  static const int nearestStationCount = 25;
}
