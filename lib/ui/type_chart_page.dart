import 'package:flutter/material.dart';
import 'package:poke_jerk_api/model/type_chart.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/ui/uiBuilder/colorbuilder.dart';
import 'package:provider/provider.dart';

class TypeChartPage extends StatefulWidget {
  const TypeChartPage({super.key});

  @override
  State<TypeChartPage> createState() => _TypeChartPageState();
}

class _TypeChartPageState extends State<TypeChartPage> {
  String? _highlightAttacker;
  String? _highlightDefender;

  // Linked scroll controllers for sticky headers
  final _horizontalHeaderCtrl = ScrollController();
  final _horizontalBodyCtrl = ScrollController();
  final _verticalLabelCtrl = ScrollController();
  final _verticalBodyCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync horizontal scroll: header ↔ body
    _horizontalHeaderCtrl.addListener(() {
      if (_horizontalBodyCtrl.hasClients &&
          _horizontalBodyCtrl.offset != _horizontalHeaderCtrl.offset) {
        _horizontalBodyCtrl.jumpTo(_horizontalHeaderCtrl.offset);
      }
    });
    _horizontalBodyCtrl.addListener(() {
      if (_horizontalHeaderCtrl.hasClients &&
          _horizontalHeaderCtrl.offset != _horizontalBodyCtrl.offset) {
        _horizontalHeaderCtrl.jumpTo(_horizontalBodyCtrl.offset);
      }
    });
    // Sync vertical scroll: labels ↔ body
    _verticalLabelCtrl.addListener(() {
      if (_verticalBodyCtrl.hasClients &&
          _verticalBodyCtrl.offset != _verticalLabelCtrl.offset) {
        _verticalBodyCtrl.jumpTo(_verticalLabelCtrl.offset);
      }
    });
    _verticalBodyCtrl.addListener(() {
      if (_verticalLabelCtrl.hasClients &&
          _verticalLabelCtrl.offset != _verticalBodyCtrl.offset) {
        _verticalLabelCtrl.jumpTo(_verticalBodyCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalHeaderCtrl.dispose();
    _horizontalBodyCtrl.dispose();
    _verticalLabelCtrl.dispose();
    _verticalBodyCtrl.dispose();
    super.dispose();
  }

  static const _cellSize = 40.0;
  static const _labelWidth = 80.0;
  static const _headerHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserSettings>().language;
    final types = TypeChart.allTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _Legend(language: language),
        ),
        Expanded(
          child: Column(
            children: [
              // ── Fixed top row: corner + scrollable column headers ──
              SizedBox(
                height: _headerHeight,
                child: Row(
                  children: [
                    // Top-left corner (fixed)
                    _buildCorner(language),
                    // Column headers (scroll horizontally)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalHeaderCtrl,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: types.map((t) => _buildColumnHeader(t, language)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ── Body: fixed row labels + scrollable cells ──
              Expanded(
                child: Row(
                  children: [
                    // Row labels (scroll vertically, fixed horizontally)
                    SizedBox(
                      width: _labelWidth,
                      child: ListView.builder(
                        controller: _verticalLabelCtrl,
                        itemCount: types.length,
                        itemExtent: _cellSize,
                        itemBuilder: (_, i) => _buildRowLabel(types[i], language),
                      ),
                    ),
                    // Cell grid (scroll both directions)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalBodyCtrl,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _cellSize * types.length,
                          child: ListView.builder(
                            controller: _verticalBodyCtrl,
                            itemCount: types.length,
                            itemExtent: _cellSize,
                            itemBuilder: (_, defIdx) {
                              final defender = types[defIdx];
                              final defChart = TypeChart.computeDefenseChart([defender]);
                              final defColor = ColorBuilder.getTypeColorByIdentifier(defender);
                              final isHighlightedRow = _highlightDefender == defender;
                              return Row(
                                children: types.map((attacker) {
                                  final mult = defChart[attacker] ?? 1.0;
                                  final isColHighlighted = _highlightAttacker == attacker;
                                  return Container(
                                    width: _cellSize,
                                    height: _cellSize,
                                    decoration: BoxDecoration(
                                      color: _cellColor(mult),
                                      border: (isColHighlighted || isHighlightedRow)
                                          ? Border.all(
                                              color: (isColHighlighted
                                                      ? ColorBuilder.getTypeColorByIdentifier(attacker)
                                                      : defColor)
                                                  .withValues(alpha: 0.4),
                                              width: 1,
                                            )
                                          : Border.all(
                                              color: Colors.grey.shade100,
                                              width: 0.5,
                                            ),
                                    ),
                                    alignment: Alignment.center,
                                    child: mult != 1.0
                                        ? Text(
                                            _multLabel(mult),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _multTextColor(mult),
                                            ),
                                          )
                                        : null,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(String language) {
    return SizedBox(
      width: _labelWidth,
      height: _headerHeight,
      child: Stack(
        children: [
          Positioned(
            right: 4,
            bottom: 2,
            child: Text(
              language == 'fr' ? 'ATQ →' : 'ATK →',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: Text(
              language == 'fr' ? '↓ DÉF' : '↓ DEF',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String type, String language) {
    final color = ColorBuilder.getTypeColorByIdentifier(type);
    final name = TypeChart.getTypeName(type, language);
    final isHighlighted = _highlightAttacker == type;
    return GestureDetector(
      onTap: () => setState(() {
        _highlightAttacker = _highlightAttacker == type ? null : type;
        _highlightDefender = null;
      }),
      child: SizedBox(
        width: _cellSize,
        height: _headerHeight,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isHighlighted ? color.withValues(alpha: 0.15) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowLabel(String type, String language) {
    final color = ColorBuilder.getTypeColorByIdentifier(type);
    final name = TypeChart.getTypeName(type, language);
    final isHighlighted = _highlightDefender == type;
    return GestureDetector(
      onTap: () => setState(() {
        _highlightDefender = _highlightDefender == type ? null : type;
        _highlightAttacker = null;
      }),
      child: Container(
        width: _labelWidth,
        height: _cellSize,
        decoration: BoxDecoration(
          color: isHighlighted ? color.withValues(alpha: 0.1) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Same color scheme as _MultiplierBadge in stats_tab.dart
  Color _cellColor(double mult) {
    if (mult >= 4.0) return Colors.red.shade600.withValues(alpha: 0.15);
    if (mult >= 2.0) return Colors.orange.shade600.withValues(alpha: 0.15);
    if (mult == 0.0) return Colors.grey.shade600.withValues(alpha: 0.15);
    if (mult <= 0.25) return Colors.teal.shade300.withValues(alpha: 0.15);
    if (mult < 1.0) return Colors.teal.shade400.withValues(alpha: 0.15);
    return Colors.white;
  }

  Color _multTextColor(double mult) {
    if (mult >= 4.0) return Colors.red.shade600;
    if (mult >= 2.0) return Colors.orange.shade700;
    if (mult == 0.0) return Colors.grey.shade600;
    return Colors.teal.shade700;
  }

  String _multLabel(double mult) {
    if (mult == 0.0) return '×0';
    if (mult == 0.25) return '¼';
    if (mult == 0.5) return '½';
    if (mult == 2.0) return '×2';
    if (mult == 4.0) return '×4';
    return '×${mult.toStringAsFixed(mult.truncateToDouble() == mult ? 0 : 1)}';
  }
}

class _Legend extends StatelessWidget {
  final String language;
  const _Legend({required this.language});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        _LegendItem(
          color: Colors.orange.shade600,
          label: language == 'fr' ? '×2 Super efficace' : '×2 Super effective',
        ),
        _LegendItem(
          color: Colors.teal.shade400,
          label: language == 'fr' ? '×½ Peu efficace' : '×½ Not very effective',
        ),
        _LegendItem(
          color: Colors.grey.shade600,
          label: language == 'fr' ? '×0 Aucun effet' : '×0 No effect',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
