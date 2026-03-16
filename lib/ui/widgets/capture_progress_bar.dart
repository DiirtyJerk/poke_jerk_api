import 'package:flutter/material.dart';
import 'package:poke_jerk_api/utils/string_utils.dart';

class CaptureProgressBar extends StatelessWidget {
  final int captured;
  final int total;
  final String language;
  final int filterMode; // 0 = all, 1 = captured, 2 = not captured

  const CaptureProgressBar({
    super.key,
    required this.captured,
    required this.total,
    required this.language,
    this.filterMode = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? captured / total : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);
    final complete = captured == total && total > 0;

    final filterLabel = filterMode == 1
        ? tr(language, 'Capturés', 'Captured')
        : filterMode == 2
            ? tr(language, 'Non capturés', 'Not captured')
            : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: complete
            ? const Color(0xFFE8F5E9)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
            size: 20,
            color: complete ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$captured / $total',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (filterLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: filterMode == 1
                                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              filterLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: filterMode == 1 ? const Color(0xFFE53935) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.grey.shade300,
                    color: complete ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
