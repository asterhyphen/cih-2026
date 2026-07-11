import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedPageWrapper extends StatelessWidget {
  const AnimatedPageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fade(begin: 0.0, end: 1.0, duration: 280.ms)
        .slide(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
          duration: 280.ms,
        );
  }
}
