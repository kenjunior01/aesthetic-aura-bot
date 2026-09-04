/// stagger_in.dart — entrada escalonada: cada bloco desliza e acende em
/// sequência, como instrumentos a serem ligados um a um.
library;

import 'package:flutter/material.dart';

class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 70),
  });

  final Widget child;
  final int index;
  final Duration baseDelay;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final delayMs = widget.baseDelay.inMilliseconds * widget.index.clamp(0, 8);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = Tween(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween(begin: 22.0, end: 0.0).animate(curved);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
