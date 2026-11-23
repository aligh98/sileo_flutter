import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'types.dart';

/// Renders the Pill + Body silhouette as a real-time refractive Apple-style
/// Liquid Glass surface using `liquid_glass_easy`'s single-pass GPU
/// [LiquidGlassBlender].
///
/// Uses the in-shader blur path (`useEngineBlur: false`) so `FlutterFragCoord`
/// stays in exact screen-space coordinates on Impeller across Flutter 3.38+
/// without `ImageFilter.compose` crop-origin drift or rectangular blur bleed.
class SileoLiquidGlassSurface extends StatelessWidget {
  /// Creates a refractive liquid glass surface matching the Sileo toast geometry.
  const SileoLiquidGlassSurface({
    super.key,
    required this.width,
    required this.pillHeight,
    required this.pillX,
    required this.pillWidth,
    required this.bodyHeight,
    required this.roundness,
    required this.expandDownward,
    required this.ambientBrightness,
    required this.opacity,
    this.glassOptions = const SileoGlassOptions(),
  });

  /// Full width of the expanded toast card.
  final double width;

  /// Collapsed header pill height.
  final double pillHeight;

  /// Animated horizontal origin of the pill.
  final double pillX;

  /// Animated width of the pill.
  final double pillWidth;

  /// Animated height of the expanded body below or above the pill.
  final double bodyHeight;

  /// Corner roundness in logical pixels.
  final double roundness;

  /// Whether the body expands downward from the pill (`true`) or upward (`false`).
  final bool expandDownward;

  /// Brightness of the surrounding app surface used to pick default glass tint
  /// and rim highlights.
  final Brightness ambientBrightness;

  /// Optical reveal factor (`0..1`) that smoothly ramps refraction, blur, tint,
  /// and rim intensity directly in-shader without an isolating `Opacity` layer.
  final double opacity;

  /// Custom liquid glass material tuning.
  final SileoGlassOptions glassOptions;

  static const double _rimBleedMargin = 4.0;

  @override
  Widget build(BuildContext context) {
    final safeOpacity = opacity.clamp(0.0, 1.0).toDouble();
    final safeW = math.max(pillHeight, width);
    final safePillW = pillWidth.clamp(math.min(pillHeight, safeW), safeW).toDouble();
    final safePillX = pillX.clamp(0.0, math.max(0.0, safeW - safePillW)).toDouble();
    final safeBodyH = math.max(0.0, bodyHeight);
    final totalH = pillHeight + safeBodyH;
    final safeR = roundness.clamp(0.0, math.min(pillHeight / 2, safeW / 2)).toDouble();

    if (safeOpacity <= 0.01) {
      return SizedBox(width: safeW, height: totalH);
    }

    // Smoothstep width emergence aligned with the analytic solid morph.
    const double attachDeadzone = 1.0;
    final mergeH = math.max(52.0, safeR * 3.4);
    final u = ((safeBodyH - attachDeadzone) / math.max(1.0, mergeH - attachDeadzone))
        .clamp(0.0, 1.0)
        .toDouble();
    final widthT = u * u * (3.0 - 2.0 * u);

    final pillTop = expandDownward ? 0.0 : safeBodyH;

    final bodyLeft = ui.lerpDouble(safePillX, 0.0, widthT)!;
    final bodyRight = ui.lerpDouble(safePillX + safePillW, safeW, widthT)!;
    final bodyW = math.max(pillHeight, bodyRight - bodyLeft);

    final double bodyLensTop;
    final double bodyLensH;
    if (expandDownward) {
      bodyLensTop = ui.lerpDouble(0.0, pillHeight, u)!;
      bodyLensH = math.max(pillHeight, totalH - bodyLensTop);
    } else {
      bodyLensTop = 0.0;
      final bodyLensBottom = ui.lerpDouble(totalH, safeBodyH, u)!;
      bodyLensH = math.max(pillHeight, bodyLensBottom);
    }

    // Ramp GPU metaball smoothness only after the body clears the pill interior
    // so the collapsed pill keeps exact dimensions with zero smin bloat.
    final bridgeT = ((safeBodyH - 14.0) / 30.0).clamp(0.0, 1.0).toDouble();
    final bridgeSmooth = bridgeT * bridgeT * (3.0 - 2.0 * bridgeT);
    final targetSmoothness =
        glassOptions.blendSmoothness ?? (safeR * 1.75).clamp(16.0, 44.0).toDouble();
    final effectiveSmoothness = bridgeSmooth <= 0.001 ? 0.0 : targetSmoothness * bridgeSmooth;

    final isDarkBg = ambientBrightness == Brightness.dark;
    final defaultTint = isDarkBg ? const Color(0xA413131A) : const Color(0xA6FFFFFF);
    final baseTint = glassOptions.tintColor ?? defaultTint;
    final tint = baseTint.withValues(alpha: baseTint.a * safeOpacity);

    final specIntensity =
        (glassOptions.specularIntensity ?? (isDarkBg ? 1.05 : 1.25)) * safeOpacity;
    final specular = LiquidGlassLight.specular(
      thickness: 3.6,
      sharpness: 0.58,
      intensity: specIntensity,
      color: isDarkBg ? const Color(0xAAFFFFFF) : const Color(0xDDFFFFFF),
    );
    final glow = LiquidGlassLight.glow(
      thickness: 7.5,
      intensity: (isDarkBg ? 0.38 : 0.50) * safeOpacity,
      color: isDarkBg ? const Color(0x40FFFFFF) : const Color(0x70FFFFFF),
    );

    final shape = LiquidGlassShape.continuousRoundedRectangle(cornerRadius: safeR);
    final style = LiquidGlassStyle(
      shape: shape,
      color: tint,
      blur: glassOptions.blur * safeOpacity,
      refractionIndex: ui.lerpDouble(1.0, glassOptions.refractionIndex, safeOpacity)!,
      refractionWidth: glassOptions.refractionWidth,
      dispersion: glassOptions.dispersion * safeOpacity,
      saturation: ui.lerpDouble(1.0, glassOptions.saturation, safeOpacity)!,
      magnification: ui.lerpDouble(1.0, glassOptions.magnification, safeOpacity)!,
      specular: specular,
      glow: glow,
      liteGlass: glassOptions.liteGlass,
    );

    return IgnorePointer(
      child: SizedBox(
        width: safeW,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: -_rimBleedMargin,
              top: -_rimBleedMargin,
              width: safeW + _rimBleedMargin * 2,
              height: totalH + _rimBleedMargin * 2,
              child: LiquidGlassBlender(
                smoothness: effectiveSmoothness,
                style: style,
                // Keep blur in-shader so Flutter 3.38 Impeller never hits
                // ImageFilter.compose crop-origin drift or rectangular blur bleed.
                useEngineBlur: false,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left: safePillX + _rimBleedMargin,
                      top: pillTop + _rimBleedMargin,
                      width: safePillW,
                      height: pillHeight,
                      child: LiquidGlassLens(style: style, child: const SizedBox.expand()),
                    ),
                    Positioned(
                      left: bodyLeft + _rimBleedMargin,
                      top: bodyLensTop + _rimBleedMargin,
                      width: bodyW,
                      height: bodyLensH,
                      child: LiquidGlassLens(style: style, child: const SizedBox.expand()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns whether the current Flutter engine supports Impeller shader backdrop
/// filters for live Liquid Glass refraction.
bool get isLiquidGlassShaderSupported => ui.ImageFilter.isShaderFilterSupported;

/// Pre-loads the fragment programs required for [SileoSurfaceStyle.liquidGlass].
Future<void> warmUpSileoLiquidGlassShaders() async {
  try {
    await LiquidGlassShaders.ensureLoaded(isLiquidGlassShaderSupported);
  } catch (_) {
    // Gracefully ignore when shaders are unavailable (e.g., headless tests).
  }
}
