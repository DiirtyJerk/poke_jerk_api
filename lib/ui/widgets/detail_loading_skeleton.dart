import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Pokéball dessinée en CustomPaint (deux demi-cercles + bande centrale + cercle)
class PokeBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, r - paint.strokeWidth / 2, paint);
    canvas.drawLine(Offset(0, r), Offset(size.width, r), paint);
    canvas.drawCircle(center, r * 0.22, paint);
  }

  @override
  bool shouldRepaint(PokeBallPainter old) => false;
}

class DetailLoadingSkeleton extends StatefulWidget {
  final int pokemonId;
  const DetailLoadingSkeleton({super.key, required this.pokemonId});

  @override
  State<DetailLoadingSkeleton> createState() => _DetailLoadingSkeletonState();
}

class _DetailLoadingSkeletonState extends State<DetailLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.2, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bar(double? width, double height, double opacity, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFF78909C);
    const greyDark = Color(0xFF546E7A);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: grey,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [greyDark, grey],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Opacity(
                        opacity: 0.1,
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: CustomPaint(painter: PokeBallPainter()),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              CachedNetworkImage(
                                imageUrl:
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${widget.pokemonId}.png',
                                height: 140,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => const SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white38, strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, _, _) => const Icon(
                                    Icons.catching_pokemon,
                                    size: 64,
                                    color: Colors.white38),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) => Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _bar(60, 11, _pulse.value),
                                  const SizedBox(height: 7),
                                  _bar(130, 20, _pulse.value),
                                  const SizedBox(height: 5),
                                  _bar(85, 10, _pulse.value),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _bar(52, 22, _pulse.value, radius: 11),
                                    const SizedBox(width: 6),
                                    _bar(52, 22, _pulse.value, radius: 11),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SkeletonTabBarDelegate(
              TabBar(
                tabs: const [Tab(text: ''), Tab(text: ''), Tab(text: ''), Tab(text: '')],
                labelColor: Colors.transparent,
                unselectedLabelColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                dividerColor: const Color(0xFFEEEEEE),
              ),
            ),
          ),
        ],
        body: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    _bar(76, 13, _pulse.value, radius: 6),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _bar(
                        null,
                        13,
                        _pulse.value * (0.4 + i * 0.1).clamp(0.0, 1.0),
                        radius: 6,
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),
      ),
    ));
  }
}

class _SkeletonTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SkeletonTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 2 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SkeletonTabBarDelegate oldDelegate) => false;
}
