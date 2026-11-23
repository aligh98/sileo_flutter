import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'types.dart';

/// Renders the built-in vector icon corresponding to a [SileoState].
///
/// Icons are custom-painted directly on a 24x24 logical grid with rounded
/// stroke caps and joins (matching Sileo's bundled Lucide SVGs), requiring no
/// icon font assets.
class SileoStateIcon extends StatelessWidget {
  /// Creates a state icon for [state] tinted with [color].
  const SileoStateIcon({super.key, required this.state, required this.color, this.size = 16.0});

  /// Semantic toast state determining the icon glyph.
  final SileoState state;

  /// Stroke color of the icon.
  final Color color;

  /// Square width and height in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (state == SileoState.loading) {
      return _SileoSpinningLoader(color: color, size: size);
    }

    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final glyph = CustomPaint(
      size: Size.square(size),
      painter: _SileoIconPainter(state: state, color: color),
    );

    if (state == SileoState.action && isRtl) {
      return Transform.flip(flipX: true, child: glyph);
    }
    return glyph;
  }
}

class _SileoSpinningLoader extends StatefulWidget {
  const _SileoSpinningLoader({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_SileoSpinningLoader> createState() => _SileoSpinningLoaderState();
}

class _SileoSpinningLoaderState extends State<_SileoSpinningLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SileoIconPainter(state: SileoState.loading, color: widget.color),
      ),
    );
  }
}

class _SileoIconPainter extends CustomPainter {
  const _SileoIconPainter({required this.state, required this.color});

  final SileoState state;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (state) {
      case SileoState.success:
        // Check: M20 6 L9 17 L4 12
        final path = Path()
          ..moveTo(20 * s, 6 * s)
          ..lineTo(9 * s, 17 * s)
          ..lineTo(4 * s, 12 * s);
        canvas.drawPath(path, paint);

      case SileoState.error:
        // X: M18 6 L6 18, M6 6 L18 18
        canvas.drawLine(Offset(18 * s, 6 * s), Offset(6 * s, 18 * s), paint);
        canvas.drawLine(Offset(6 * s, 6 * s), Offset(18 * s, 18 * s), paint);

      case SileoState.warning:
        // CircleAlert: circle(12,12,10), line(12,8 -> 12,12), dot(12,16)
        canvas.drawCircle(Offset(12 * s, 12 * s), 10 * s, paint);
        canvas.drawLine(Offset(12 * s, 8 * s), Offset(12 * s, 12 * s), paint);
        canvas.drawLine(Offset(12 * s, 16 * s), Offset(12.01 * s, 16 * s), paint);

      case SileoState.info:
        // LifeBuoy: outer circle(12,12,10), inner circle(12,12,4), 4 spokes
        canvas.drawCircle(Offset(12 * s, 12 * s), 10 * s, paint);
        canvas.drawCircle(Offset(12 * s, 12 * s), 4 * s, paint);
        canvas.drawLine(Offset(4.93 * s, 4.93 * s), Offset(9.17 * s, 9.17 * s), paint);
        canvas.drawLine(Offset(14.83 * s, 9.17 * s), Offset(19.07 * s, 4.93 * s), paint);
        canvas.drawLine(Offset(14.83 * s, 14.83 * s), Offset(19.07 * s, 19.07 * s), paint);
        canvas.drawLine(Offset(9.17 * s, 14.83 * s), Offset(4.93 * s, 19.07 * s), paint);

      case SileoState.action:
        // ArrowRight: M5 12 H19, M12 5 L19 12 L12 19
        canvas.drawLine(Offset(5 * s, 12 * s), Offset(19 * s, 12 * s), paint);
        final head = Path()
          ..moveTo(12 * s, 5 * s)
          ..lineTo(19 * s, 12 * s)
          ..lineTo(12 * s, 19 * s);
        canvas.drawPath(head, paint);

      case SileoState.loading:
        // LoaderCircle: M21 12a9 9 0 1 1-6.219-8.56 (~288° arc)
        final rect = Rect.fromCircle(center: Offset(12 * s, 12 * s), radius: 9 * s);
        canvas.drawArc(rect, 0, math.pi * 1.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(_SileoIconPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.color != color;
  }
}
