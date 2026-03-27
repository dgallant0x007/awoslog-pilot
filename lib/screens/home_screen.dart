import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/settings.dart';
import '../models/position.dart';
import '../services/gps_service.dart';
import '../services/buffer_service.dart';
import '../services/push_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tailController = TextEditingController();
  final _pilotController = TextEditingController();
  final _notifyPhoneController = TextEditingController();

  late AppSettings _settings;
  late BufferService _buffer;
  late GpsService _gps;
  final Battery _battery = Battery();
  PushService? _push;

  bool _loaded = false;
  bool _tracking = false;
  String _trackId = '';
  PilotPosition? _lastPos;
  int _buffered = 0;
  String _pushStatus = '';
  bool _pushOk = true;
  DateTime? _trackingStart;
  String _elapsed = '00:00';
  Timer? _elapsedTimer;
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _buffer = BufferService();
    _gps = GpsService();
    _init();
  }

  Future<void> _init() async {
    await _buffer.init();
    await NotificationService.init();
    _settings = await AppSettings.load();
    _tailController.text = _settings.tail;
    _pilotController.text = _settings.pilot;
    _notifyPhoneController.text = _settings.notifyPhone;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _stopTracking();
    _tailController.dispose();
    _pilotController.dispose();
    _notifyPhoneController.dispose();
    _buffer.close();
    super.dispose();
  }

  Future<void> _startTracking() async {
    // Validate.
    final tail = _tailController.text.trim().toUpperCase();
    if (tail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a tail number (N-number)')),
      );
      return;
    }

    // Save settings.
    _settings.tail = tail;
    _settings.pilot = _pilotController.text.trim();
    _settings.notifyPhone = _notifyPhoneController.text.trim();
    await _settings.save();

    // Request GPS permission.
    final ok = await _gps.requestPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
      return;
    }

    // Generate track ID.
    _trackId = _settings.generateTrackId();

    // Clear buffer from previous session.
    await _buffer.clearAll();

    // Request notification permission.
    await NotificationService.requestPermission();

    // Start GPS.
    _gps.start(onPosition: (pos) async {
      await _buffer.insert(pos);
      final count = await _buffer.unpushedCount();
      if (mounted) {
        setState(() {
          _lastPos = pos;
          _buffered = count;
        });
      }
    });

    // Start push service.
    _push = PushService(
      buffer: _buffer,
      getTrackId: () => _trackId,
      getTail: () => _settings.tail,
      getPilot: () => _settings.pilot,
      getMode: () => _settings.mode == TrackingMode.perFlight ? 'per-flight' : 'tail-number',
      getBattery: () => _battery.batteryLevel,
      onPushResult: (success, count) {
        if (mounted) {
          setState(() {
            _pushOk = success;
            if (count > 0) {
              _pushStatus = success
                  ? 'Pushed $count positions'
                  : 'Push failed — buffering';
            }
          });
          // Update buffered count.
          _buffer.unpushedCount().then((c) {
            if (mounted) setState(() => _buffered = c);
          });
        }
      },
    );
    _push!.start();

    _trackingStart = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_trackingStart != null && mounted) {
        final d = DateTime.now().difference(_trackingStart!);
        setState(() {
          _elapsed = '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });

    setState(() => _tracking = true);
  }

  Future<void> _stopTracking() async {
    await _push?.close();
    _gps.stop();
    _push?.stop();
    _push = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    final tail = _settings.tail;
    final phone = _settings.notifyPhone;
    setState(() {
      _tracking = false;
      _lastPos = null;
      _pushStatus = '';
      _trackingStart = null;
      _elapsed = '00:00';
      _showQr = false;
    });

    // Offer to send landed SMS if a notify number is configured.
    if (phone.isNotEmpty && mounted) {
      final send = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Send landed notification?'),
          content: Text('Send "Landed OK" to $phone?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      );
      if (send == true) {
        final uri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': 'Landed OK \u2014 $tail'},
        );
        launchUrl(uri);
      }
    }
  }

  String get _shareUrl => _settings.shareUrl(_trackId);

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  void _shareUrlAction() {
    Share.share('Track my flight: $_shareUrl');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AWOSLOG Pilot Tracker'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tail number
            TextField(
              controller: _tailController,
              enabled: !_tracking,
              decoration: const InputDecoration(
                labelText: 'Tail Number',
                hintText: 'N12345',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),

            // Pilot name
            TextField(
              controller: _pilotController,
              enabled: !_tracking,
              decoration: const InputDecoration(
                labelText: 'Pilot Name',
                hintText: 'Dave',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Tracking mode
            DropdownButtonFormField<TrackingMode>(
              value: _settings.mode,
              decoration: const InputDecoration(
                labelText: 'Sharing Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TrackingMode.perFlight,
                  child: Text('Per-flight (unique link each time)'),
                ),
                DropdownMenuItem(
                  value: TrackingMode.tailNumber,
                  child: Text('Tail number (same link always)'),
                ),
              ],
              onChanged: _tracking
                  ? null
                  : (v) {
                      if (v != null) {
                        setState(() => _settings.mode = v);
                        _settings.save();
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Notify on landing phone number
            TextField(
              controller: _notifyPhoneController,
              enabled: !_tracking,
              decoration: const InputDecoration(
                labelText: 'Notify on Landing (optional)',
                hintText: 'Phone number(s), comma separated',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),

            // Start / Stop button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _tracking ? _stopTracking : _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _tracking ? Colors.red.shade700 : const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _tracking ? 'STOP TRACKING' : 'START TRACKING',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Share URL (only when tracking)
            if (_tracking) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Share this link:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      _shareUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyUrl,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareUrlAction,
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _showQr = !_showQr),
                          child: const Icon(Icons.qr_code, size: 18),
                        ),
                      ],
                    ),
                    if (_showQr) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: QrImageView(
                          data: _shareUrl,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Status (only when tracking)
            if (_tracking) ...[
              const SizedBox(height: 20),
              _statusCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final pos = _lastPos;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: _pushOk ? const Color(0xFF1565C0) : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                _pushOk ? 'Tracking Active' : 'Network Issue — Buffering',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _pushOk ? const Color(0xFF1565C0) : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _statusRow('Flight Time', _elapsed),
          if (pos != null) ...[
            _statusRow('Position', '${pos.lat.toStringAsFixed(4)}, ${pos.lon.toStringAsFixed(4)}'),
            _statusRow('Altitude', '${pos.altitude} ft'),
            _statusRow('Speed', '${pos.speed} kt'),
            _statusRow('Heading', '${pos.heading.round()}°'),
          ] else
            _statusRow('GPS', 'Waiting for fix...'),
          _statusRow('Buffered', '$_buffered positions'),
          if (_pushStatus.isNotEmpty) _statusRow('Last push', _pushStatus),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
