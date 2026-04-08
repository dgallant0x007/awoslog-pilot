import 'dart:async';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/aircraft.dart';
import '../models/flight_data.dart';
import '../models/position.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import '../services/barometer_service.dart';
import '../services/gps_service.dart';
import '../utils/math_utils.dart';
import '../utils/traffic_utils.dart';
import '../widgets/flight_strip.dart';
import '../widgets/traffic_list.dart';
import '../widgets/station_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> with WidgetsBindingObserver {
  final _api = ApiService(baseUrl: Config.apiBaseUrl);
  final _gps = GpsService(minInterval: const Duration(seconds: 1));
  final _baro = BarometerService();

  FlightData _flightData = FlightData.empty;
  double? _baroInHg;
  List<Port> _ports = [];
  Map<String, LatestMetar> _metarMap = {};
  List<Aircraft> _rawAircraft = [];

  List<TrafficTarget> _targets = [];
  List<Station> _stations = [];
  bool _trafficLoaded = false;
  bool _stationsLoaded = false;

  StreamSubscription<double>? _baroSub;
  Timer? _trafficTimer;
  Timer? _stationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchStations();
      _fetchTraffic();
    }
  }

  Future<void> _init() async {
    WakelockPlus.enable();

    final hasPermission = await _gps.requestPermission();
    if (!hasPermission) return;

    await _baro.start();
    _baroSub = _baro.stream.listen((inHg) {
      _baroInHg = inHg;
    });

    _gps.start(onPosition: _onGpsPosition);

    _ports = await _api.fetchPorts();
    await _fetchStations();
    await _fetchTraffic();

    _stationTimer =
        Timer.periodic(Config.stationPollRate, (_) => _fetchStations());
    _scheduleTrafficPoll();
  }

  void _onGpsPosition(PilotPosition pos) {
    final gps = FlightData(
      groundSpeedKt: pos.speed.toDouble(),
      trackDeg: pos.heading,
      altitudeFt: pos.altitude.toDouble(),
      lat: pos.lat,
      lon: pos.lon,
    );
    setState(() {
      _flightData = _computeDA(gps);
      _recomputeTraffic();
      _recomputeStations();
    });
  }

  void _scheduleTrafficPoll() {
    final hasCloseTraffic = _targets.isNotEmpty &&
        _targets.first.distanceNm < Config.trafficFastThresholdNm;
    final rate =
        hasCloseTraffic ? Config.trafficPollFast : Config.trafficPollSlow;

    _trafficTimer?.cancel();
    _trafficTimer = Timer(rate, () async {
      await _fetchTraffic();
      _scheduleTrafficPoll();
    });
  }

  Future<void> _fetchTraffic() async {
    if (_flightData.lat == 0 && _flightData.lon == 0) return;
    _rawAircraft = await _api.fetchAircraft(
      _flightData.lat,
      _flightData.lon,
      Config.trafficRadiusNm,
    );
    _trafficLoaded = true;
    _recomputeTraffic();
    if (mounted) setState(() {});
  }

  Future<void> _fetchStations() async {
    final metars = await _api.fetchLatest();
    _metarMap = {for (final m in metars) m.station: m};
    _stationsLoaded = true;
    _recomputeStations();
    // Recompute DA in case station data arrived after GPS
    if (_flightData.lat != 0 || _flightData.lon != 0) {
      _flightData = _computeDA(_flightData);
    }
    if (mounted) setState(() {});
  }

  FlightData _computeDA(FlightData gps) {
    if (_metarMap.isEmpty) return gps;

    // Find nearest station with temp data
    double nearestDist = double.infinity;
    LatestMetar? nearestMetar;
    Port? nearestPort;
    for (final port in _ports) {
      final d = haversineNm(gps.lat, gps.lon, port.lat, port.lon);
      final metar = _metarMap[port.id];
      if (d < nearestDist && metar != null && metar.tempC != 0) {
        nearestDist = d;
        nearestMetar = metar;
        nearestPort = port;
      }
    }

    if (nearestMetar == null || nearestPort == null) return gps;

    int da;
    if (_baroInHg != null) {
      // Best: phone barometer + station temp
      da = densityAltitude(_baroInHg!, nearestMetar.tempC.toDouble());
    } else if (nearestMetar.barometer > 0) {
      // Fallback: station altimeter setting + GPS altitude + station temp
      da = stationDensityAltitude(
        gps.altitudeFt.round(),
        nearestMetar.barometer,
        nearestMetar.tempC.toDouble(),
      );
    } else {
      return gps;
    }

    return FlightData(
      groundSpeedKt: gps.groundSpeedKt,
      trackDeg: gps.trackDeg,
      altitudeFt: gps.altitudeFt,
      lat: gps.lat,
      lon: gps.lon,
      densityAltitude: da,
    );
  }

  void _recomputeTraffic() {
    if (_flightData.lat == 0 && _flightData.lon == 0) return;
    _targets = processTraffic(
      aircraft: _rawAircraft,
      myLat: _flightData.lat,
      myLon: _flightData.lon,
      myAltFt: _flightData.altitudeFt,
      myTrackDeg: _flightData.trackDeg,
    );
  }

  void _recomputeStations() {
    if ((_flightData.lat == 0 && _flightData.lon == 0) || _ports.isEmpty) {
      return;
    }

    final merged = <Station>[];
    for (final port in _ports) {
      final metar = _metarMap[port.id];
      if (metar == null) continue;

      final dist = haversineNm(
          _flightData.lat, _flightData.lon, port.lat, port.lon);
      final hasDa = metar.barometer > 0 && metar.tempC != 0;
      final da = hasDa
          ? stationDensityAltitude(
              port.elevation, metar.barometer, metar.tempC.toDouble())
          : null;

      merged.add(Station.fromPortAndMetar(port, metar).withDistanceAndDA(
        distanceNm: dist,
        densityAltitude: da,
      ));
    }

    merged.sort((a, b) => a.distanceNm.compareTo(b.distanceNm));
    _stations = merged.take(Config.nearestStationCount).toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _baroSub?.cancel();
    _trafficTimer?.cancel();
    _stationTimer?.cancel();
    _gps.stop();
    _baro.dispose();
    super.dispose();
  }

  bool get _hasGps => _flightData.lat != 0 || _flightData.lon != 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasGps) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Acquiring GPS...',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5588AA),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            FlightStrip(data: _flightData),
            Container(height: 2, color: const Color(0xFF1A3A5C)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: TrafficList(targets: _targets, loaded: _trafficLoaded),
            ),
            Container(height: 2, color: const Color(0xFF1A3A5C)),
            Expanded(
              child: StationList(stations: _stations, loaded: _stationsLoaded),
            ),
          ],
        ),
      ),
    );
  }
}
