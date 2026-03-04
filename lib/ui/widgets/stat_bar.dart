import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/stat.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';

class StatBar extends StatelessWidget {
  final Stat stat;
  final int value;
  final String language;
  static const int _maxStat = 255;

  const StatBar({
    super.key,
    required this.stat,
    required this.value,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorBuilder.getStatColor(stat.identifier);
    final ratio = (value / _maxStat).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              stat.getTranslation(language),
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
