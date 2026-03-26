import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import '../models/position.dart';

class GpsService {
  StreamSubscription<Position>? _subscription;
  PilotPosition? _lastPosition;

  PilotPosition? get lastPosition => _lastPosition;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    // Request "always" permission for background tracking.
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void start({required void Function(PilotPosition) onPosition}) {
    stop();

    final LocationSettings settings;

    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'AWOSLOG Pilot Tracker',
          notificationText: 'Tracking your flight',
          enableWakeLock: true,
          notificationChannelName: 'Flight Tracking',
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          setOngoing: true,
        ),
      );
    } else {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.airborne,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((pos) {
      // Skip invalid positions.
      if (pos.latitude == 0 && pos.longitude == 0) return;

      final pilotPos = PilotPosition.fromGeolocator(
        lat: pos.latitude,
        lon: pos.longitude,
        altitudeMeters: pos.altitude,
        speedMps: pos.speed,
        heading: pos.heading,
        accuracy: pos.accuracy,
      );

      _lastPosition = pilotPos;
      onPosition(pilotPos);
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
  }
}
