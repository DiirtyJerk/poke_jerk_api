import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shared shimmer box
// ---------------------------------------------------------------------------

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double opacity;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulse mixin — shared animation controller logic
// ---------------------------------------------------------------------------

mixin _PulseMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController pulseCtrl;
  late final Animation<double> pulse;

  void initPulse() {
    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    pulse = Tween(begin: 0.35, end: 0.75)
        .animate(CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut));
  }

  void disposePulse() => pulseCtrl.dispose();
}

// ---------------------------------------------------------------------------
// PokedexListSkeleton — 3-column grid of card skeletons
// ---------------------------------------------------------------------------

class PokedexListSkeleton extends StatefulWidget {
  const PokedexListSkeleton({super.key});

  @override
  State<PokedexListSkeleton> createState() => _PokedexListSkeletonState();
}

class _PokedexListSkeletonState extends State<PokedexListSkeleton>
    with SingleTickerProviderStateMixin, _PulseMixin {
  @override
  void initState() {
    super.initState();
    initPulse();
  }

  @override
  void dispose() {
    disposePulse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemCount: 18,
        itemBuilder: (_, _) => _PokemonCardSkeleton(opacity: pulse.value),
      ),
    );
  }
}

class _PokemonCardSkeleton extends StatelessWidget {
  final double opacity;
  const _PokemonCardSkeleton({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pokedex number
            Align(
              alignment: Alignment.topLeft,
              child: ShimmerBox(width: 32, height: 11, opacity: opacity),
            ),
            // Sprite area
            Expanded(
              child: Center(
                child: ShimmerBox(
                  width: 64,
                  height: 64,
                  borderRadius: 32,
                  opacity: opacity * 0.6,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Name
            ShimmerBox(width: 70, height: 13, opacity: opacity),
            const SizedBox(height: 6),
            // Type chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 38, height: 16, borderRadius: 8, opacity: opacity),
                const SizedBox(width: 4),
                ShimmerBox(width: 38, height: 16, borderRadius: 8, opacity: opacity),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ItemsListSkeleton — ListTile-like rows
// ---------------------------------------------------------------------------

class ItemsListSkeleton extends StatefulWidget {
  const ItemsListSkeleton({super.key});

  @override
  State<ItemsListSkeleton> createState() => _ItemsListSkeletonState();
}

class _ItemsListSkeletonState extends State<ItemsListSkeleton>
    with SingleTickerProviderStateMixin, _PulseMixin {
  @override
  void initState() {
    super.initState();
    initPulse();
  }

  @override
  void dispose() {
    disposePulse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 14,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, _) => _ItemTileSkeleton(opacity: pulse.value),
      ),
    );
  }
}

class _ItemTileSkeleton extends StatelessWidget {
  final double opacity;
  const _ItemTileSkeleton({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ShimmerBox(width: 36, height: 36, borderRadius: 18, opacity: opacity),
      title: ShimmerBox(width: 120, height: 14, opacity: opacity),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ShimmerBox(width: 80, height: 11, opacity: opacity * 0.7),
      ),
      trailing: ShimmerBox(width: 44, height: 14, opacity: opacity * 0.6),
    );
  }
}

// ---------------------------------------------------------------------------
// MovesListSkeleton — Card rows matching move card layout
// ---------------------------------------------------------------------------

class MovesListSkeleton extends StatefulWidget {
  const MovesListSkeleton({super.key});

  @override
  State<MovesListSkeleton> createState() => _MovesListSkeletonState();
}

class _MovesListSkeletonState extends State<MovesListSkeleton>
    with SingleTickerProviderStateMixin, _PulseMixin {
  @override
  void initState() {
    super.initState();
    initPulse();
  }

  @override
  void dispose() {
    disposePulse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 12,
        itemBuilder: (_, _) => _MoveCardSkeleton(opacity: pulse.value),
      ),
    );
  }
}

class _MoveCardSkeleton extends StatelessWidget {
  final double opacity;
  const _MoveCardSkeleton({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Damage class icon placeholder
            ShimmerBox(width: 16, height: 16, borderRadius: 4, opacity: opacity * 0.5),
            const SizedBox(width: 20),
            // Name + type row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 100, height: 13, opacity: opacity),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      ShimmerBox(width: 50, height: 16, borderRadius: 8, opacity: opacity),
                      const SizedBox(width: 8),
                      ShimmerBox(width: 56, height: 11, opacity: opacity * 0.6),
                    ],
                  ),
                ],
              ),
            ),
            // Stat badges
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statBadgeSkeleton(opacity),
                const SizedBox(width: 10),
                _statBadgeSkeleton(opacity),
                const SizedBox(width: 10),
                _statBadgeSkeleton(opacity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadgeSkeleton(double opacity) {
    return Column(
      children: [
        ShimmerBox(width: 28, height: 9, opacity: opacity * 0.5),
        const SizedBox(height: 2),
        ShimmerBox(width: 22, height: 12, opacity: opacity),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// LocationsListSkeleton — Region headers + location tile entries
// ---------------------------------------------------------------------------

class LocationsListSkeleton extends StatefulWidget {
  const LocationsListSkeleton({super.key});

  @override
  State<LocationsListSkeleton> createState() => _LocationsListSkeletonState();
}

class _LocationsListSkeletonState extends State<LocationsListSkeleton>
    with SingleTickerProviderStateMixin, _PulseMixin {
  @override
  void initState() {
    super.initState();
    initPulse();
  }

  @override
  void dispose() {
    disposePulse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          _regionSkeleton(pulse.value, 5),
          const SizedBox(height: 8),
          _regionSkeleton(pulse.value, 4),
          const SizedBox(height: 8),
          _regionSkeleton(pulse.value, 3),
        ],
      ),
    );
  }

  Widget _regionSkeleton(double opacity, int tileCount) {
    return Column(
      children: [
        // Region header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ShimmerBox(width: 18, height: 18, borderRadius: 9, opacity: opacity * 0.5),
              const SizedBox(width: 8),
              ShimmerBox(width: 80, height: 14, opacity: opacity),
              const Spacer(),
              ShimmerBox(width: 16, height: 12, opacity: opacity * 0.5),
              const SizedBox(width: 4),
              ShimmerBox(width: 18, height: 18, borderRadius: 9, opacity: opacity * 0.3),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Location tiles
        ...List.generate(tileCount, (_) => _locationTileSkeleton(opacity)),
      ],
    );
  }

  Widget _locationTileSkeleton(double opacity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: ShimmerBox(width: 18, height: 18, borderRadius: 4, opacity: opacity * 0.5),
          ),
        ),
        title: ShimmerBox(width: 110, height: 13, opacity: opacity),
        trailing: ShimmerBox(width: 18, height: 18, borderRadius: 9, opacity: opacity * 0.3),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}
