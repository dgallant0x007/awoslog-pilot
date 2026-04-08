import 'package:flutter/material.dart';
import '../models/station.dart';
import '../utils/math_utils.dart';

class StationList extends StatelessWidget {
  final List<Station> stations;

  const StationList({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 2),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATIONS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5588AA),
                      letterSpacing: 1.5)),
              Text('nearest 25',
                  style: TextStyle(fontSize: 9, color: Color(0xFF444444))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: stations.length,
            itemBuilder: (context, index) => _stationRow(stations[index]),
          ),
        ),
      ],
    );
  }

  Widget _stationRow(Station station) {
    final category = flightCategory(station.ceiling, station.visibility);
    final dotColor = switch (category) {
      FlightCategory.vfr => const Color(0xFF4CAF50),
      FlightCategory.mvfr => const Color(0xFFFF9800),
      FlightCategory.ifr => const Color(0xFFF44336),
      FlightCategory.lifr => const Color(0xFFE040FB),
    };
    const opacity = 1.0;
    final distStr = station.distanceNm < 10
        ? station.distanceNm.toStringAsFixed(1)
        : station.distanceNm.toStringAsFixed(0);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF141414))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(station.id,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'monospace')),
                  const SizedBox(width: 6),
                  Text('${distStr}nm',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF666666))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(station.windDisplay,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'monospace')),
                Text('DA ${station.densityAltitude}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFAAAAAA))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
