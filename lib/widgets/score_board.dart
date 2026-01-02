import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:block_master_game/piece_generator.dart';

class GameHeader extends StatelessWidget {
  final int score;
  final int highScore;
  final int combo;
  final VoidCallback onMenuPressed;

  const GameHeader({
    super.key,
    required this.score,
    required this.highScore,
    required this.combo,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Stats
          _ScoreItem(
            label: 'BEST',
            value: highScore.toString(),
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFFD700),
            isSmall: true,
          ),

          _ScoreItem(
            label: 'SCORE',
            value: score.toString(),
            icon: Icons.stars_rounded,
            color: GameConstants.accentColor,
          ),

          GestureDetector(
            onTap: onMenuPressed,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacityX(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacityX(0.1),
                  width: 1,
                ),
              ),
              child: Icon(Icons.menu_rounded, color: Colors.white, size: 24.sp),
            ),
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
  final bool isSmall;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: isSmall ? 14.sp : 18.sp),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.parse(value)),
              duration: const Duration(milliseconds: 500),
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 16.sp : 24.sp,
                    fontWeight: isSmall ? FontWeight.w500 : FontWeight.bold,
                    shadows: [
                      Shadow(color: color.withOpacityX(0.5), blurRadius: 8),
                    ],
                  ),
                );
              },
            ),
          ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(20.r),
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
            Icon(Icons.local_fire_department, color: Colors.white, size: 20.sp),
            SizedBox(width: 4.w),
            Text(
              'x${widget.combo}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
