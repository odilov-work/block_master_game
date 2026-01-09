import 'package:block_master_game/core/extensions.dart';
import 'package:block_master_game/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GameMenuDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameMenuDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<GameMenuDialog> createState() => _GameMenuDialogState();
}

class _GameMenuDialogState extends State<GameMenuDialog> {
  bool _soundEnabled = true;
  bool _tipsEnabled = false;

  @override
  void initState() {
    super.initState();
    _soundEnabled = LocalStorageService.getSoundEnabled();
    _tipsEnabled = LocalStorageService.getMoveAnalysisEnabled();
  }

  void _toggleSound() {
    HapticFeedback.lightImpact();
    setState(() {
      _soundEnabled = !_soundEnabled;
      LocalStorageService.saveSoundEnabled(_soundEnabled);
    });
  }

  void _toggleTips() {
    HapticFeedback.lightImpact();
    setState(() {
      _tipsEnabled = !_tipsEnabled;
      LocalStorageService.saveMoveAnalysisEnabled(_tipsEnabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E).withOpacityX(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: const Color(0xFF6C5CE7).withOpacityX(0.5),
          width: 2,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: const Color(0xFF6C5CE7).withOpacityX(0.8),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            // Sound Toggle
            _buildMenuOption(
              icon: _soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: 'SOUND',
              onTap: _toggleSound,
              isToggle: true,
              isActive: _soundEnabled,
            ),
            SizedBox(height: 16.h),

            // Move Tips Toggle
            _buildMenuOption(
              icon: _tipsEnabled
                  ? Icons.lightbulb_rounded
                  : Icons.lightbulb_outline_rounded,
              label: 'TIPS',
              onTap: _toggleTips,
              isToggle: true,
              isActive: _tipsEnabled,
            ),
            SizedBox(height: 16.h),

            // Restart
            _buildMenuOption(
              icon: Icons.refresh_rounded,
              label: 'RESTART',
              onTap: widget.onRestart,
            ),
            SizedBox(height: 16.h),

            // Home
            _buildMenuOption(
              icon: Icons.home_rounded,
              label: 'HOME',
              onTap: widget.onHome,
            ),
            SizedBox(height: 32.h),

            // Resume Button
            GestureDetector(
              onTap: widget.onResume,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00FFFF)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacityX(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'RESUME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isToggle = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacityX(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isToggle && isActive
                ? const Color(0xFF00FFFF).withOpacityX(0.5)
                : Colors.white.withOpacityX(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isToggle && isActive
                  ? const Color(0xFF00FFFF)
                  : Colors.white,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                color: isToggle && isActive
                    ? const Color(0xFF00FFFF)
                    : Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (!isToggle)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacityX(0.3),
                size: 16.sp,
              ),
          ],
        ),
      ),
    );
  }
}
