import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class BarometerService {
  StreamSubscription<BarometerEvent>? _subscription;
  final _controller = StreamController<double>.broadcast();

  /// Stream of barometric pressure in inHg.
  Stream<double> get stream => _controller.stream;

  Future<void> start() async {
    try {
      _subscription = barometerEventStream().listen((event) {
        // event.pressure is in hPa, convert to inHg
        _controller.add(event.pressure / 33.8639);
      });
    } catch (_) {
      // Barometer not available on this device
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
