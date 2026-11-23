import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Standard cubic Bezier handle ratio approximating a 90-degree circular arc.
const double _kArcKappa = 0.5522847498307936;

/// Builds the unified gooey pill-and-body silhouette [Path] in local widget
/// coordinates.
///
/// Uses C1-continuous cubic Bezier S-curves and exact circular quarter-arcs so
/// the body emerges from and absorbs back into the pill like liquid without
/// sharp corners, horizontal slivers, or snapping artifacts at any height.
Path buildSileoGooeyPath({
  required double width,
  required double pillHeight,
  required double pillX,
  required double pillWidth,
  required double bodyHeight,
  required double roundness,
  bool expandDownward = true,
}) {
  final w = width.clamp(1.0, double.infinity).toDouble();
  final h = pillHeight.clamp(1.0, double.infinity).toDouble();
  final wp = pillWidth.clamp(math.min(h, w), w).toDouble();
  final xl = pillX.clamp(0.0, w - wp).toDouble();
  final xr = xl + wp;
  final b = math.max(0.0, bodyHeight);
  final r = roundness.clamp(0.0, math.min(h / 2, w / 2)).toDouble();
  final totalH = h + b;

  final path = _buildDownwardPath(w: w, h: h, xl: xl, xr: xr, wp: wp, b: b, r: r, totalH: totalH);

  if (expandDownward) {
    return path;
  }

  // Mirror vertically within [0, totalH] so upward-expanding toasts place the
  // pill along the bottom edge and expand the card upward.
  final matrix = Float64List.fromList(<double>[
    1,
    0,
    0,
    0,
    0,
    -1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    totalH,
    0,
    1,
  ]);
  return path.transform(matrix);
}

Path _buildDownwardPath({
  required double w,
  required double h,
  required double xl,
  required double xr,
  required double wp,
  required double b,
  required double r,
  required double totalH,
}) {
  // Smooth S-curve width emergence over a generous merge zone so shoulders
  // arrive into the pill with zero velocity and zero visual snap.
  const double attachDeadzone = 2.0;
  final mergeH = math.max(52.0, r * 3.4);
  final rawT = ((b - attachDeadzone) / math.max(1.0, mergeH - attachDeadzone))
      .clamp(0.0, 1.0)
      .toDouble();
  // Cubic smoothstep: zero slope at both t=0 (pill attach) and t=1 (full card).
  final widthT = rawT * rawT * (3.0 - 2.0 * rawT);

  final bL = ui.lerpDouble(xl, 0.0, widthT)!;
  final bR = ui.lerpDouble(xr, w, widthT)!;

  final gapL = xl - bL;
  final gapR = bR - xr;
  final hasLeftStep = gapL > 0.05;
  final hasRightStep = gapR > 0.05;

  final effectiveBL = hasLeftStep ? bL : xl;
  final effectiveBR = hasRightStep ? bR : xr;
  final wb = math.max(1.0, effectiveBR - effectiveBL);

  // Pure pill fast-path when body width matches the pill.
  if (!hasLeftStep && !hasRightStep) {
    final pr = math.min(r, math.min(totalH / 2, wp / 2));
    return Path()..addRRect(RRect.fromLTRBR(xl, 0, xr, totalH, Radius.circular(pr)));
  }

  final rPtl = math.min(r, math.min(h / 2, wp / 2));
  final rPtr = math.min(r, math.min(h / 2, wp / 2));

  // Keep bottom corners consistently rounded (never collapsing to sharp points)
  // throughout the entire merge trajectory.
  final rBot = math.min(r, math.min(totalH / 2, wb / 2));
  final yBotCornerTop = totalH - rBot;

  // Compute the vertical S-curve shoulder span [yStart, yEnd].
  // When expanded (b >= 2*r), this resolves to exact [h - cMax, h + r] centered
  // at y = h, producing exact circular concave and convex arcs. During merge,
  // it smoothly compresses into a C1 elliptical liquid neck.
  final cMaxR = math.min(r, math.max(0.0, h - rPtr));
  final yEndR = math.max(rPtr, math.min(h + r, yBotCornerTop));
  final maxSpanR = math.max(0.0, yEndR - rPtr);
  final desiredSpanR = cMaxR + r;
  final spanR = math.min(desiredSpanR, maxSpanR);
  final yStartR = r <= 0.0 ? h : (yEndR - spanR);
  final yMidR = r <= 0.0 ? h : (yStartR + yEndR) / 2.0;
  final ryR = r <= 0.0 ? 0.0 : (yEndR - yStartR) / 2.0;
  final rxR = math.min(ryR, gapR / 2.0);

  final cMaxL = math.min(r, math.max(0.0, h - rPtl));
  final yEndL = math.max(rPtl, math.min(h + r, yBotCornerTop));
  final maxSpanL = math.max(0.0, yEndL - rPtl);
  final desiredSpanL = cMaxL + r;
  final spanL = math.min(desiredSpanL, maxSpanL);
  final yStartL = r <= 0.0 ? h : (yEndL - spanL);
  final yMidL = r <= 0.0 ? h : (yStartL + yEndL) / 2.0;
  final ryL = r <= 0.0 ? 0.0 : (yEndL - yStartL) / 2.0;
  final rxL = math.min(ryL, gapL / 2.0);

  final path = Path()
    ..moveTo(xl + rPtl, 0)
    ..lineTo(xr - rPtr, 0);

  // Pill top-right convex corner.
  _arcIfNeeded(path, Offset(xr, rPtr), rPtr, clockwise: true);

  // Right wall and C1 liquid shoulder.
  if (hasRightStep) {
    path.lineTo(xr, yStartR);
    if (rxR > 0.01 && ryR > 0.01) {
      // Concave neck bend: vertical down from pill -> horizontal right onto bridge.
      path.cubicTo(
        xr,
        yStartR + ryR * _kArcKappa,
        xr + rxR * (1.0 - _kArcKappa),
        yMidR,
        xr + rxR,
        yMidR,
      );
      if (effectiveBR - rxR > xr + rxR + 0.01) {
        path.lineTo(effectiveBR - rxR, yMidR);
      }
      // Convex body shoulder: horizontal right from bridge -> vertical down onto body.
      path.cubicTo(
        effectiveBR - rxR * (1.0 - _kArcKappa),
        yMidR,
        effectiveBR,
        yEndR - ryR * _kArcKappa,
        effectiveBR,
        yEndR,
      );
    } else {
      path
        ..lineTo(xr, yMidR)
        ..lineTo(effectiveBR, yMidR);
    }
  }
  path.lineTo(effectiveBR, yBotCornerTop);

  // Body bottom-right convex corner.
  _arcIfNeeded(path, Offset(effectiveBR - rBot, totalH), rBot, clockwise: true);

  // Bottom edge.
  path.lineTo(effectiveBL + rBot, totalH);

  // Body bottom-left convex corner.
  _arcIfNeeded(path, Offset(effectiveBL, yBotCornerTop), rBot, clockwise: true);

  // Left wall and C1 liquid shoulder (exact mirror of right side).
  if (hasLeftStep) {
    path.lineTo(effectiveBL, yEndL);
    if (rxL > 0.01 && ryL > 0.01) {
      // Convex body shoulder: vertical up from body -> horizontal right onto bridge.
      path.cubicTo(
        effectiveBL,
        yEndL - ryL * _kArcKappa,
        effectiveBL + rxL * (1.0 - _kArcKappa),
        yMidL,
        effectiveBL + rxL,
        yMidL,
      );
      if (xl - rxL > effectiveBL + rxL + 0.01) {
        path.lineTo(xl - rxL, yMidL);
      }
      // Concave neck bend: horizontal right from bridge -> vertical up onto pill.
      path.cubicTo(
        xl - rxL * (1.0 - _kArcKappa),
        yMidL,
        xl,
        yStartL + ryL * _kArcKappa,
        xl,
        yStartL,
      );
    } else {
      path
        ..lineTo(effectiveBL, yMidL)
        ..lineTo(xl, yMidL);
    }
  }
  path.lineTo(xl, rPtl);

  // Pill top-left convex corner.
  _arcIfNeeded(path, Offset(xl + rPtl, 0), rPtl, clockwise: true);

  path.close();
  return path;
}

void _arcIfNeeded(Path path, Offset endPoint, double radius, {required bool clockwise}) {
  if (radius > 0.01) {
    path.arcToPoint(endPoint, radius: Radius.circular(radius), clockwise: clockwise);
  } else {
    path.lineTo(endPoint.dx, endPoint.dy);
  }
}

/// Renders the analytic gooey morphing silhouette for a Sileo toast.
class SileoGooeyPainter extends CustomPainter {
  /// Creates a painter for the unified pill and body shape.
  const SileoGooeyPainter({
    required this.pillHeight,
    required this.pillX,
    required this.pillWidth,
    required this.bodyHeight,
    required this.roundness,
    required this.fill,
    required this.expandDownward,
    this.elevation = 0.0,
    this.border,
    this.cachedPath,
  });

  /// Height of the collapsed header pill.
  final double pillHeight;

  /// Horizontal origin of the pill within the canvas width.
  final double pillX;

  /// Width of the header pill.
  final double pillWidth;

  /// Current animated height of the expanded body below or above the pill.
  final double bodyHeight;

  /// Corner radius and concave neck fillet radius.
  final double roundness;

  /// Solid surface fill color.
  final Color fill;

  /// Whether the body expands downward from the pill.
  final bool expandDownward;

  /// Optional drop shadow elevation behind the silhouette.
  final double elevation;

  /// Optional hairline stroke drawn around the silhouette perimeter.
  final BorderSide? border;

  /// Optional precomputed [Path] to avoid recomputing geometry when shared with
  /// a clipper in the same frame.
  final Path? cachedPath;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        cachedPath ??
        buildSileoGooeyPath(
          width: size.width,
          pillHeight: pillHeight,
          pillX: pillX,
          pillWidth: pillWidth,
          bodyHeight: bodyHeight,
          roundness: roundness,
          expandDownward: expandDownward,
        );

    if (elevation > 0.0) {
      final isLightSurface = fill.computeLuminance() > 0.5;
      final shadowAlpha = isLightSurface ? 0.14 : 0.22;
      final shadowPaint = Paint()
        ..color = Color.fromRGBO(0, 0, 0, shadowAlpha)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation * 1.5);

      canvas.save();
      canvas.translate(0, elevation * 0.5);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    final borderSide = border;
    if (borderSide != null && borderSide.style == BorderStyle.solid && borderSide.width > 0) {
      final strokePaint = Paint()
        ..color = borderSide.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderSide.width
        ..isAntiAlias = true;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(SileoGooeyPainter oldDelegate) {
    return oldDelegate.pillHeight != pillHeight ||
        oldDelegate.pillX != pillX ||
        oldDelegate.pillWidth != pillWidth ||
        oldDelegate.bodyHeight != bodyHeight ||
        oldDelegate.roundness != roundness ||
        oldDelegate.fill != fill ||
        oldDelegate.expandDownward != expandDownward ||
        oldDelegate.elevation != elevation ||
        oldDelegate.border != border;
  }
}
