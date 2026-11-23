import 'dart:async';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sileo_flutter/sileo_flutter.dart';

void main() {
  runApp(const SileoPlaygroundApp());
}

class SileoPlaygroundApp extends StatefulWidget {
  const SileoPlaygroundApp({super.key});

  @override
  State<SileoPlaygroundApp> createState() => _SileoPlaygroundAppState();
}

class _SileoPlaygroundAppState extends State<SileoPlaygroundApp> {
  bool _darkMode = false;
  bool _isRtl = false;
  SileoPosition _position = SileoPosition.topCenter;
  SileoStackBehavior _stackBehavior = SileoStackBehavior.morph;
  SileoSurfaceStyle _surfaceStyle = SileoSurfaceStyle.solid;
  double _roundness = SileoDefaults.roundness;

  @override
  Widget build(BuildContext context) {
    final bg = _darkMode ? const Color(0xFF0B0B0F) : const Color(0xFFF5F6FA);
    final fg = _darkMode ? const Color(0xFFF4F4F5) : const Color(0xFF141416);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sileo Flutter Playground',
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
        fontFamily: 'Vazirmatn',
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B7FFF),
          brightness: _darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            child: SileoToaster(
              position: _position,
              stackBehavior: _stackBehavior,
              surfaceStyle: _surfaceStyle,
              warmUpLiquidGlass: true,
              themeMode: _darkMode ? SileoThemeMode.dark : SileoThemeMode.light,
              options: SileoOptions(roundness: _roundness),
              child: child!,
            ),
          ),
        );
      },
      home: _PlaygroundHome(
        darkMode: _darkMode,
        isRtl: _isRtl,
        position: _position,
        stackBehavior: _stackBehavior,
        surfaceStyle: _surfaceStyle,
        roundness: _roundness,
        foreground: fg,
        onDarkModeChanged: (v) => setState(() => _darkMode = v),
        onRtlChanged: (v) => setState(() => _isRtl = v),
        onPositionChanged: (v) => setState(() => _position = v),
        onStackBehaviorChanged: (v) => setState(() => _stackBehavior = v),
        onSurfaceStyleChanged: (v) => setState(() => _surfaceStyle = v),
        onRoundnessChanged: (v) => setState(() => _roundness = v),
      ),
    );
  }
}

class _PlaygroundHome extends StatelessWidget {
  const _PlaygroundHome({
    required this.darkMode,
    required this.isRtl,
    required this.position,
    required this.stackBehavior,
    required this.surfaceStyle,
    required this.roundness,
    required this.foreground,
    required this.onDarkModeChanged,
    required this.onRtlChanged,
    required this.onPositionChanged,
    required this.onStackBehaviorChanged,
    required this.onSurfaceStyleChanged,
    required this.onRoundnessChanged,
  });

  final bool darkMode;
  final bool isRtl;
  final SileoPosition position;
  final SileoStackBehavior stackBehavior;
  final SileoSurfaceStyle surfaceStyle;
  final double roundness;
  final Color foreground;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onRtlChanged;
  final ValueChanged<SileoPosition> onPositionChanged;
  final ValueChanged<SileoStackBehavior> onStackBehaviorChanged;
  final ValueChanged<SileoSurfaceStyle> onSurfaceStyleChanged;
  final ValueChanged<double> onRoundnessChanged;

  static const Map<SileoPosition, String> _positionLabels =
      <SileoPosition, String>{
        SileoPosition.topLeft: 'top-left',
        SileoPosition.topCenter: 'top-center',
        SileoPosition.topRight: 'top-right',
        SileoPosition.bottomLeft: 'bottom-left',
        SileoPosition.bottomCenter: 'bottom-center',
        SileoPosition.bottomRight: 'bottom-right',
      };

  bool get _isLiquidGlass => surfaceStyle == SileoSurfaceStyle.liquidGlass;

  void _fireFlightFuture() {
    unawaited(
      Sileo.future<String>(
        Future<String>.delayed(
          const Duration(milliseconds: 2200),
          () => 'EC2QW4',
        ),
        SileoFutureOptions<String>(
          position: position,
          loading: const SileoOptions(title: 'Booking Flight'),
          successBuilder: (pnr) => SileoOptions(
            title: 'Booking Confirmed',
            descriptionWidget: _FlightCard(
              pnr: pnr,
              isDarkApp: darkMode,
              isLiquidGlass: _isLiquidGlass,
            ),
            button: SileoButton(
              title: 'View Details',
              onPressed: () {
                Sileo.success(title: 'Boarding Pass Ready', position: position);
              },
            ),
          ),
          error: const SileoOptions(
            title: 'Booking Failed',
            description: 'Unable to confirm your seat. Please try again.',
          ),
        ),
      ),
    );
  }

  void _firePersianToast() {
    Sileo.success(
      title: 'تغییرات ذخیره شد',
      description:
          'تنظیمات حساب کاربری شما با موفقیت در سرور ثبت و همگام‌سازی شد.',
      position: position,
      button: SileoButton(
        title: 'مشاهده جزئیات',
        onPressed: () {
          Sileo.info(
            title: 'همگام‌سازی کامل شد',
            description:
                'تمام دستگاه‌های متصل شما به آخرین نسخه به‌روزرسانی شدند.',
            position: position,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = darkMode
        ? const Color(0xFF16161C).withValues(alpha: _isLiquidGlass ? 0.82 : 1.0)
        : Colors.white.withValues(alpha: _isLiquidGlass ? 0.86 : 1.0);
    final border = darkMode ? Colors.white12 : Colors.black12;
    final muted = foreground.withValues(alpha: 0.58);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Rich ambient backdrop visible behind the top & bottom viewports so
          // Liquid Glass refraction, chromatic dispersion, and specular rims pop.
          Positioned.fill(
            child: IgnorePointer(
              child: _RefractionShowcaseBackdrop(
                darkMode: darkMode,
                vivid: _isLiquidGlass,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          text: 'Sileo',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.4,
                            color: foreground,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: '.',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLiquidGlass
                            ? 'Real-time GPU refractive Liquid Glass + Sileo spring physics.'
                            : 'Physics-based, 120Hz gooey morphing toasts for Flutter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: muted),
                      ),
                      const SizedBox(height: 28),

                      // Controls card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: <Widget>[
                                for (final entry in _positionLabels.entries)
                                  _ChipButton(
                                    label: entry.value,
                                    selected: position == entry.key,
                                    darkMode: darkMode,
                                    onTap: () => onPositionChanged(entry.key),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: border, height: 1),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: <Widget>[
                                _ChipButton(
                                  label: _isLiquidGlass
                                      ? 'Surface: Liquid Glass'
                                      : 'Surface: Solid',
                                  selected: _isLiquidGlass,
                                  darkMode: darkMode,
                                  onTap: () => onSurfaceStyleChanged(
                                    _isLiquidGlass
                                        ? SileoSurfaceStyle.solid
                                        : SileoSurfaceStyle.liquidGlass,
                                  ),
                                ),
                                _ChipButton(
                                  label: darkMode
                                      ? 'Theme: Dark'
                                      : 'Theme: Light',
                                  selected: false,
                                  darkMode: darkMode,
                                  onTap: () => onDarkModeChanged(!darkMode),
                                ),
                                _ChipButton(
                                  label:
                                      stackBehavior == SileoStackBehavior.morph
                                      ? 'Mode: Morph'
                                      : 'Mode: Stack',
                                  selected: false,
                                  darkMode: darkMode,
                                  onTap: () => onStackBehaviorChanged(
                                    stackBehavior == SileoStackBehavior.morph
                                        ? SileoStackBehavior.stack
                                        : SileoStackBehavior.morph,
                                  ),
                                ),
                                _ChipButton(
                                  label: isRtl
                                      ? 'Direction: RTL'
                                      : 'Direction: LTR',
                                  selected: isRtl,
                                  darkMode: darkMode,
                                  onTap: () => onRtlChanged(!isRtl),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Text(
                                  'Roundness (${roundness.round()}px)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: muted,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: roundness,
                                    min: 4,
                                    max: 20,
                                    divisions: 16,
                                    onChanged: onRoundnessChanged,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Toast triggers
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          _ActionPill(
                            label: 'Success',
                            accent: SileoDefaults.successColor,
                            darkMode: darkMode,
                            onTap: () => Sileo.success(
                              title: 'Changes Saved',
                              description:
                                  'Changes saved successfully to the database. Refresh to see updates.',
                              position: position,
                            ),
                          ),
                          _ActionPill(
                            label: 'Error',
                            accent: SileoDefaults.errorColor,
                            darkMode: darkMode,
                            onTap: () => Sileo.error(
                              title: 'Something Went Wrong',
                              description:
                                  "We're having trouble saving your changes. Please try again shortly.",
                              position: position,
                            ),
                          ),
                          _ActionPill(
                            label: 'Warning',
                            accent: SileoDefaults.warningColor,
                            darkMode: darkMode,
                            onTap: () => Sileo.warning(
                              title: 'Storage Almost Full',
                              description:
                                  "You've used 95% of your available storage. Upgrade your plan to continue.",
                              position: position,
                            ),
                          ),
                          _ActionPill(
                            label: 'Info',
                            accent: SileoDefaults.infoColor,
                            darkMode: darkMode,
                            onTap: () => Sileo.info(
                              title: 'New Update Available',
                              description:
                                  'Version 2.0 is ready to install with faster spring physics and RTL support.',
                              position: position,
                            ),
                          ),
                          _ActionPill(
                            label: 'Action',
                            accent: SileoDefaults.actionColor,
                            darkMode: darkMode,
                            onTap: () => Sileo.action(
                              title: 'File Uploaded',
                              description:
                                  'Your file has been uploaded. Share it with your team?',
                              position: position,
                              button: SileoButton(
                                title: 'Share Now',
                                onPressed: () => Sileo.success(
                                  title: 'Link Copied',
                                  position: position,
                                ),
                              ),
                            ),
                          ),
                          _ActionPill(
                            label: 'Flight Future',
                            accent: SileoDefaults.successColor,
                            darkMode: darkMode,
                            onTap: _fireFlightFuture,
                          ),
                          _ActionPill(
                            label: 'Custom Icon',
                            accent: const Color(0xFFA855F7),
                            darkMode: darkMode,
                            onTap: () => Sileo.success(
                              title: 'Deployment Started',
                              icon: const Icon(
                                Icons.rocket_launch_rounded,
                                size: 14,
                              ),
                              description:
                                  'Your Flutter release is rolling out to production.',
                              position: position,
                            ),
                          ),
                          _ActionPill(
                            label: 'فارسی RTL',
                            accent: SileoDefaults.infoColor,
                            darkMode: darkMode,
                            onTap: _firePersianToast,
                          ),
                          _ActionPill(
                            label: 'Clear All',
                            accent: SileoDefaults.loadingColor,
                            darkMode: darkMode,
                            onTap: Sileo.clear,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefractionShowcaseBackdrop extends StatelessWidget {
  const _RefractionShowcaseBackdrop({
    required this.darkMode,
    required this.vivid,
  });

  final bool darkMode;
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final alpha = vivid ? (darkMode ? 0.42 : 0.34) : (darkMode ? 0.10 : 0.08);
    final gridColor = darkMode
        ? Colors.white.withValues(alpha: vivid ? 0.07 : 0.03)
        : Colors.black.withValues(alpha: vivid ? 0.05 : 0.025);

    return CustomPaint(
      painter: _BackdropPainter(
        orbAlpha: alpha,
        gridColor: gridColor,
        vivid: vivid,
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.orbAlpha,
    required this.gridColor,
    required this.vivid,
  });

  final double orbAlpha;
  final Color gridColor;
  final bool vivid;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft ambient color orbs positioned behind top & bottom toast viewports
    // so glass bevel refraction is vividly visible.
    void drawOrb(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: orbAlpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    drawOrb(
      Offset(size.width * 0.22, 90),
      size.width * 0.45,
      const Color(0xFF3B82F6),
    );
    drawOrb(
      Offset(size.width * 0.78, 120),
      size.width * 0.42,
      const Color(0xFFEC4899),
    );
    drawOrb(
      Offset(size.width * 0.50, 70),
      size.width * 0.32,
      const Color(0xFF10B981),
    );

    drawOrb(
      Offset(size.width * 0.25, size.height - 90),
      size.width * 0.44,
      const Color(0xFFF59E0B),
    );
    drawOrb(
      Offset(size.width * 0.76, size.height - 100),
      size.width * 0.46,
      const Color(0xFF8B5CF6),
    );

    // Fine dot/line grid helps reveal live edge bending through liquid glass.
    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    if (vivid) {
      // Crisp colorful ribbon pills behind top & bottom edges to showcase live lens warp.
      final stripTop = Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF38BDF8),
            Color(0xFFA855F7),
            Color(0xFFF43F5E),
          ],
        ).createShader(Rect.fromLTWH(24, 58, size.width - 48, 18));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24, 62, size.width - 48, 12),
          const Radius.circular(999),
        ),
        stripTop,
      );

      final stripBottom = Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[
                Color(0xFF22C55E),
                Color(0xFFF59E0B),
                Color(0xFF3B82F6),
              ],
            ).createShader(
              Rect.fromLTWH(24, size.height - 78, size.width - 48, 18),
            );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24, size.height - 74, size.width - 48, 12),
          const Radius.circular(999),
        ),
        stripBottom,
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate.orbAlpha != orbAlpha ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.vivid != vivid;
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.darkMode,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool darkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (darkMode ? Colors.white : const Color(0xFF141416))
        : (darkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
    final fg = selected
        ? (darkMode ? Colors.black : Colors.white)
        : (darkMode ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.accent,
    required this.darkMode,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool darkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = darkMode ? const Color(0xFF1C1C21) : Colors.white;
    final fg = darkMode ? Colors.white : const Color(0xFF141416);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: darkMode ? Colors.white12 : Colors.black12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recreates Sileo's signature Flight Booking card with an animated progress wave.
class _FlightCard extends StatefulWidget {
  const _FlightCard({
    required this.pnr,
    required this.isDarkApp,
    required this.isLiquidGlass,
  });

  final String pnr;
  final bool isDarkApp;
  final bool isLiquidGlass;

  @override
  State<_FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<_FlightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solid mode inverts the app theme; liquid glass matches the ambient brightness.
    final lightTextOnCard = widget.isLiquidGlass
        ? widget.isDarkApp
        : !widget.isDarkApp;
    final onCard = lightTextOnCard ? Colors.white : const Color(0xFF141416);
    final markerRingColor = lightTextOnCard
        ? SileoDefaults.lightThemeFill
        : SileoDefaults.darkThemeFill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'UNITED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: onCard.withValues(alpha: 0.85),
              ),
            ),
            Text(
              'UA13A',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: onCard.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              'DEL',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: onCard,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 36,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t =
                        Curves.easeOut.transform(_controller.value) * 0.42;
                    return CustomPaint(
                      painter: _FlightWavePainter(
                        progress: t,
                        surfaceColor: markerRingColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SFO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: onCard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'On Time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: (widget.isLiquidGlass && !widget.isDarkApp)
                        ? const Color(0xFF15803D)
                        : SileoDefaults.successColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    text: 'PNR ',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onCard.withValues(alpha: 0.5),
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: widget.pnr,
                        style: TextStyle(
                          color: onCard,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.airline_seat_recline_normal_rounded,
                    size: 15,
                    color: Colors.black,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '32K',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlightWavePainter extends CustomPainter {
  const _FlightWavePainter({
    required this.progress,
    required this.surfaceColor,
  });

  final double progress;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    const green = SileoDefaults.successColor;
    final start = Offset(0, size.height * 0.85);
    final control = Offset(size.width * 0.5, -size.height * 0.35);
    final end = Offset(size.width, size.height * 0.85);

    Offset pointAt(double t) {
      final mt = 1 - t;
      return Offset(
        mt * mt * start.dx + 2 * mt * t * control.dx + t * t * end.dx,
        mt * mt * start.dy + 2 * mt * t * control.dy + t * t * end.dy,
      );
    }

    // Dashed planned arc
    final dashedPaint = Paint()
      ..color = green.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const segments = 24;
    for (var i = 0; i < segments; i += 2) {
      final p0 = pointAt(i / segments);
      final p1 = pointAt(math.min(1.0, (i + 0.9) / segments));
      canvas.drawLine(p0, p1, dashedPaint);
    }

    // Flown solid arc + subtle gradient area
    final flownPath = Path()..moveTo(start.dx, start.dy);
    const steps = 28;
    for (var i = 1; i <= steps; i++) {
      final p = pointAt(progress * (i / steps));
      flownPath.lineTo(p.dx, p.dy);
    }

    final marker = pointAt(progress);
    final areaPath = Path.from(flownPath)
      ..lineTo(marker.dx, size.height)
      ..lineTo(start.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          green.withValues(alpha: 0.28),
          green.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final solidPaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(flownPath, solidPaint);

    // Drop line + aircraft dot
    canvas.drawLine(
      marker,
      Offset(marker.dx, size.height),
      Paint()
        ..color = green.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(marker, 5.2, Paint()..color = surfaceColor);
    canvas.drawCircle(marker, 3.2, Paint()..color = green);
  }

  @override
  bool shouldRepaint(_FlightWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
