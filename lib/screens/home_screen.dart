import 'package:block_master_game/core/extensions.dart';
import 'package:block_master_game/screens/game_screen.dart';
import 'package:block_master_game/services/local_storage_service.dart';
import 'package:block_master_game/widgets/background_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _soundEnabled = LocalStorageService.getSoundEnabled();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSound() {
    HapticFeedback.lightImpact();
    setState(() {
      _soundEnabled = !_soundEnabled;
      LocalStorageService.saveSoundEnabled(_soundEnabled);
    });
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highScore = LocalStorageService.getHighScore();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar with settings
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildIconButton(
                        icon: _soundEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        onTap: _toggleSound,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Game Title with neon effect
                _buildGameTitle(),

                SizedBox(height: 50.h),

                // High Score
                _buildHighScore(highScore),

                const Spacer(),

                // Play Button
                _buildPlayButton(),

                SizedBox(height: 60.h),

                // Footer
                Text(
                  'BLOCK MASTER',
                  style: TextStyle(
                    color: Colors.white.withOpacityX(0.3),
                    fontSize: 12.sp,
                    letterSpacing: 4,
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withOpacityX(0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withOpacityX(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacityX(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24.sp),
      ),
    );
  }

  Widget _buildGameTitle() {
    return Column(
      children: [
        // Neon glow text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00FFFF), Color(0xFF6C5CE7), Color(0xFFFF00CC)],
          ).createShader(bounds),
          child: Text(
            'BLOCK',
            style: TextStyle(
              fontSize: 60.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFFF).withOpacityX(0.8),
                  blurRadius: 20,
                ),
                Shadow(
                  color: const Color(0xFF6C5CE7).withOpacityX(0.6),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ),
        Text(
          'MASTER',
          style: TextStyle(
            fontSize: 48.sp,
            fontWeight: FontWeight.w300,
            color: Colors.white.withOpacityX(0.9),
            letterSpacing: 16,
            shadows: [
              Shadow(
                color: const Color(0xFFFF00CC).withOpacityX(0.5),
                blurRadius: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighScore(int highScore) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacityX(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacityX(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: const Color(0xFFFFD700),
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            highScore.toString(),
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withOpacityX(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _startGame,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 16.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF00FFFF)],
            ),
            borderRadius: BorderRadius.circular(300.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacityX(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacityX(0.3),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32.sp),
              SizedBox(width: 8.w),
              Text(
                "PLAY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
