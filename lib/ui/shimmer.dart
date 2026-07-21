import 'package:flutter/material.dart';

/// Skeleton loading placeholder — a rounded box with a sweeping highlight.
/// Extracted from the UniMatch animation kit so the skeleton components are
/// self-contained.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  final double width, height, borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _anim.value * 2, 0),
              end: Alignment(1.0 + _anim.value * 2, 0),
              colors: const [
                Color(0xFFE8EDF5),
                Color(0xFFF5F8FF),
                Color(0xFFE8EDF5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
}
