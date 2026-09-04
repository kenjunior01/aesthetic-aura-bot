/// tilt_card.dart — o cartão responde à mão como um objeto físico:
/// perspectiva real, o mesmo gesto do TiltCard/AuraRadar do web (max 5°).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  const TiltCard({super.key, required this.child, this.maxDegrees = 5});

  final Widget child;
  final double maxDegrees;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with TickerProviderStateMixin {
  late final AnimationController _anim;
  Offset _target = Offset.zero; // -1..1
  Offset _current = Offset.zero;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 90),
        )..addListener(() {
          setState(() => _current = Offset.lerp(_current, _target, 0.28)!);
        });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _update(Offset local, Size size) {
    _target = Offset(
      (local.dx / size.width) * 2 - 1,
      (local.dy / size.height) * 2 - 1,
    );
    _anim.forward(from: 0);
  }

  void _reset() {
    _target = Offset.zero;
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition, context.size ?? Size.zero),
      onPanUpdate: (d) => _update(d.localPosition, context.size ?? Size.zero),
      onPanCancel: _reset,
      onPanEnd: (_) => _reset(),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // perspectiva
          ..rotateX(_current.dy * widget.maxDegrees * math.pi / 180)
          ..rotateY(-_current.dx * widget.maxDegrees * math.pi / 180),
        child: widget.child,
      ),
    );
  }
}
