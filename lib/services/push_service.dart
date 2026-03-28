import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/position.dart';
import 'buffer_service.dart';

class PushService {
  static const _pushUrl = 'https://awoslog.com/api/pilot/push';
  static const _closeUrl = 'https://awoslog.com/api/pilot/close';
  static const _pushInterval = Duration(seconds: 10);
  static const _appVersion = '1.3.1';

  final BufferService _buffer;
  final String Function() _getTrackId;
  final String Function() _getTail;
  final String Function() _getPilot;
  final String Function() _getMode;
  final Future<int> Function() _getBattery;
  final void Function(bool success, int count) _onPushResult;

  Timer? _timer;
  bool _pushing = false;
  DateTime? _lastPush;
  int _lastBattery = 0;

  PushService({
    required BufferService buffer,
    required String Function() getTrackId,
    required String Function() getTail,
    required String Function() getPilot,
    required String Function() getMode,
    required Future<int> Function() getBattery,
    required void Function(bool success, int count) onPushResult,
  })  : _buffer = buffer,
        _getTrackId = getTrackId,
        _getTail = getTail,
        _getPilot = getPilot,
        _getMode = getMode,
        _getBattery = getBattery,
        _onPushResult = onPushResult;

  DateTime? get lastPush => _lastPush;

  void start() {
    stop();
    // Push immediately, then on interval.
    _pushNow();
    _timer = Timer.periodic(_pushInterval, (_) => _pushNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pushNow() async {
    if (_pushing) return;
    _pushing = true;

    try {
      final positions = await _buffer.getUnpushed(limit: 500);
      if (positions.isEmpty) {
        _onPushResult(true, 0);
        return;
      }

      try { _lastBattery = await _getBattery(); } catch (_) {}

      final success = await _push(positions);
      if (success) {
        await _buffer.markPushed(positions);
        _lastPush = DateTime.now();
        await _buffer.cleanup();
      }
      _onPushResult(success, positions.length);
    } catch (_) {
      _onPushResult(false, 0);
    } finally {
      _pushing = false;
    }
  }

  Future<bool> _push(List<PilotPosition> positions) async {
    try {
      final body = jsonEncode({
        'track_id': _getTrackId(),
        'tail': _getTail(),
        'pilot': _getPilot(),
        'mode': _getMode(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': _appVersion,
        'battery': _lastBattery,
        'positions': positions.map((p) => p.toJson()).toList(),
      });

      debugPrint('PUSH: sending ${positions.length} positions to $_pushUrl');
      debugPrint('PUSH: track_id=${_getTrackId()} tail=${_getTail()}');

      final response = await http
          .post(
            Uri.parse(_pushUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('PUSH: response ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PUSH: error $e');
      return false;
    }
  }

  Future<void> close() async {
    try {
      final body = jsonEncode({
        'track_id': _getTrackId(),
        'tail': _getTail(),
      });
      debugPrint('CLOSE: sending close for track_id=${_getTrackId()}');
      await http
          .post(
            Uri.parse(_closeUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('CLOSE: error $e');
    }
  }
}
