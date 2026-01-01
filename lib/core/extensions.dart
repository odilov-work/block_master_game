import 'package:flutter/material.dart';

extension ColorX on Color {
  Color withOpacityX(double opacity) => withValues(alpha: opacity);
}
