import 'package:flutter/material.dart';

class AppPressable extends StatefulWidget {
  const AppPressable({
    required this.child,
    this.onTap,
    this.pressedOffset = const Offset(3, 3),
    this.duration = const Duration(milliseconds: 70),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Offset pressedOffset;
  final Duration duration;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _pressed ? widget.pressedOffset.dx : 0,
          _pressed ? widget.pressedOffset.dy : 0,
          0,
        ),
        transformAlignment: Alignment.topLeft,
        child: widget.child,
      ),
    );
  }
}
