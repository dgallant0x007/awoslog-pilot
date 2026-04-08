import 'package:flutter/material.dart';
import '../utils/traffic_utils.dart';

class TrafficList extends StatelessWidget {
  final List<TrafficTarget> targets;
  final bool loaded;

  const TrafficList({super.key, required this.targets, this.loaded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 2),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TRAFFIC',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5588AA),
                        letterSpacing: 1.5)),
                Text('50nm \u00B710K',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
              ],
            ),
          ),
          if (targets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(loaded ? 'no traffic' : 'loading...',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF666666))),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final target = targets[index];
                  final isClosest = index == 0;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        target.display,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: isClosest
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4FC3F7),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
