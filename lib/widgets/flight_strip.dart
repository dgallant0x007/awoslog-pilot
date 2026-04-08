import 'package:flutter/material.dart';
import '../models/flight_data.dart';

class FlightStrip extends StatelessWidget {
  final FlightData data;

  const FlightStrip({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1628),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          _item('GS', '${data.groundSpeedKt.round()}',
              const Color(0xFF5588AA), const Color(0xFF4FC3F7)),
          _item('ALT', '${data.altitudeFt.round()}',
              const Color(0xFF5588AA), const Color(0xFF4FC3F7)),
          _item('DA',
              data.densityAltitude != null ? '${data.densityAltitude}' : '--',
              const Color(0xFFAA8855), const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _item(String label, String value, Color labelColor, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 1)),
          Text(value,
              style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                  height: 1.0,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
