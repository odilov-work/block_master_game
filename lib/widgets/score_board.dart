import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';

class ScoreBoard extends StatelessWidget {
  final int score;
  final int highScore;
  final int combo;

  const ScoreBoard({
    super.key,
    required this.score,
    required this.highScore,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScoreItem(
            label: 'OCHKO',
            value: score.toString(),
            icon: Icons.stars_rounded,
            color: GameConstants.accentColor,
          ),
          if (combo > 0) _ComboIndicator(combo: combo),
          _ScoreItem(
            label: 'REKORD',
            value: highScore.toString(),
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFFD700),
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final CrossAxisAlignment alignment;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacityX(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.parse(value)),
          duration: const Duration(milliseconds: 500),
          builder: (context, animatedValue, child) {
            return Text(
              animatedValue.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: color.withOpacityX(0.5), blurRadius: 10),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ComboIndicator extends StatefulWidget {
  final int combo;

  const _ComboIndicator({required this.combo});

  @override
  State<_ComboIndicator> createState() => _ComboIndicatorState();
}

class _ComboIndicatorState extends State<_ComboIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.combo != widget.combo) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacityX(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              'x${widget.combo}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
