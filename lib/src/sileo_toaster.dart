import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'sileo_controller.dart';
import 'sileo_liquid_glass.dart';
import 'sileo_toast.dart';
import 'types.dart';

/// Viewport overlay that renders and coordinates Sileo toast notifications.
///
/// Mount once near the root of your application, for example inside
/// `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => SileoToaster(
///     position: SileoPosition.topRight,
///     child: child!,
///   ),
///   home: const MyHomePage(),
/// )
/// ```
///
/// Or place [SileoToaster] without a [child] directly inside a [Stack].
class SileoToaster extends StatefulWidget {
  /// Creates a toast viewport overlay.
  const SileoToaster({
    super.key,
    this.child,
    this.controller,
    this.position = SileoPosition.topRight,
    this.offset = const EdgeInsets.all(SileoDefaults.viewportPadding),
    this.options,
    this.themeMode = SileoThemeMode.system,
    this.surfaceStyle = SileoSurfaceStyle.solid,
    this.glassOptions = const SileoGlassOptions(),
    this.warmUpLiquidGlass = false,
    this.stackBehavior = SileoStackBehavior.morph,
    this.stateColors = const SileoStateColors(),
    this.maxWidth = SileoDefaults.maxWidth,
    this.gap = SileoDefaults.viewportGap,
    this.useSafeArea = true,
  });

  /// Application content rendered beneath the toast overlay viewports.
  final Widget? child;

  /// Optional dedicated controller. Defaults to [Sileo.instance].
  final SileoController? controller;

  /// Default anchor position for toasts that do not specify one.
  final SileoPosition position;

  /// Distance from each screen edge in logical pixels.
  final EdgeInsets offset;

  /// Global default options merged into every toast fired while mounted.
  final SileoOptions? options;

  /// Automatic surface fill resolution mode (`light`, `dark`, or `system`).
  final SileoThemeMode themeMode;

  /// Default surface rendering mode (`solid` by default, or `liquidGlass`).
  final SileoSurfaceStyle surfaceStyle;

  /// Default material settings used when rendering [SileoSurfaceStyle.liquidGlass].
  final SileoGlassOptions glassOptions;

  /// Whether to pre-compile Liquid Glass GPU shaders behind [child] on launch
  /// (only runs on Impeller; ignored when `false`).
  final bool warmUpLiquidGlass;

  /// Controls whether new toasts without an explicit ID morph in place or stack.
  final SileoStackBehavior stackBehavior;

  /// Semantic accent color palette shared by all rendered toasts.
  final SileoStateColors stateColors;

  /// Maximum width of an expanded toast card before clamping to viewport width.
  final double maxWidth;

  /// Vertical gap between stacked toasts in the same viewport.
  final double gap;

  /// Whether to pad viewports away from notches, status bars, and home indicators.
  final bool useSafeArea;

  @override
  State<SileoToaster> createState() => _SileoToasterState();
}

class _SileoToasterState extends State<SileoToaster> {
  final Map<String, Timer> _dismissTimers = <String, Timer>{};
  final Set<String> _pausedToastIds = <String>{};

  late SileoController _controller;
  List<SileoToastItem> _toasts = const <SileoToastItem>[];
  String? _activeId;
  String? _latestId;

  bool get _isPaused => _pausedToastIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? Sileo.instance;
    _syncControllerConfig();
    _controller.addListener(_onStoreChanged);
    _syncToasts(_controller.toasts, shouldNotify: false);
    _maybeWarmUpGlass();
  }

  @override
  void didUpdateWidget(covariant SileoToaster oldWidget) {
    super.didUpdateWidget(oldWidget);

    final prevController = oldWidget.controller ?? Sileo.instance;
    final nextController = widget.controller ?? Sileo.instance;
    final controllerChanged = !identical(nextController, prevController);
    if (controllerChanged) {
      _controller.removeListener(_onStoreChanged);
      _clearAllTimers();
      _pausedToastIds.clear();
      _controller = nextController;
      _controller.addListener(_onStoreChanged);
    }

    if (widget.position != oldWidget.position ||
        widget.options != oldWidget.options ||
        widget.stackBehavior != oldWidget.stackBehavior ||
        controllerChanged) {
      _syncControllerConfig();
    }

    if (controllerChanged) {
      _syncToasts(_controller.toasts, shouldNotify: true);
    }

    if ((widget.warmUpLiquidGlass && !oldWidget.warmUpLiquidGlass) ||
        (widget.surfaceStyle == SileoSurfaceStyle.liquidGlass &&
            oldWidget.surfaceStyle != SileoSurfaceStyle.liquidGlass)) {
      _maybeWarmUpGlass();
    }
  }

  void _maybeWarmUpGlass() {
    if (!isLiquidGlassShaderSupported) return;
    if (widget.warmUpLiquidGlass || widget.surfaceStyle == SileoSurfaceStyle.liquidGlass) {
      unawaited(warmUpSileoLiquidGlassShaders());
    }
  }

  void _syncControllerConfig() {
    _controller.configure(
      position: widget.position,
      options: widget.options,
      stackBehavior: widget.stackBehavior,
      clearDefaultOptions: widget.options == null,
    );
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _syncToasts(_controller.toasts, shouldNotify: true);
  }

  void _syncToasts(List<SileoToastItem> next, {required bool shouldNotify}) {
    final activeKeys = <String>{for (final t in next) t.timerKey};
    final activeIds = <String>{for (final t in next) t.id};

    // Cancel timers for removed or superseded toast revisions.
    final staleKeys = <String>[
      for (final key in _dismissTimers.keys)
        if (!activeKeys.contains(key)) key,
    ];
    for (final key in staleKeys) {
      _dismissTimers.remove(key)?.cancel();
    }

    _pausedToastIds.removeWhere((id) => !activeIds.contains(id));

    String? latest;
    for (var i = next.length - 1; i >= 0; i--) {
      if (!next[i].exiting) {
        latest = next[i].id;
        break;
      }
    }

    final latestChanged = latest != _latestId;
    _latestId = latest;

    if (shouldNotify) {
      setState(() {
        _toasts = next;
        if (latestChanged || !activeIds.contains(_activeId)) {
          _activeId = latest;
        }
      });
    } else {
      _toasts = next;
      _activeId = latest;
    }

    _scheduleTimers(next);
  }

  void _clearAllTimers() {
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    _dismissTimers.clear();
  }

  void _scheduleTimers(List<SileoToastItem> items) {
    if (_isPaused) return;

    for (final item in items) {
      if (item.exiting) continue;
      if (_dismissTimers.containsKey(item.timerKey)) continue;

      final duration = item.effectiveDuration;
      if (duration == null) continue;

      _dismissTimers[item.timerKey] = Timer(duration, () {
        _dismissTimers.remove(item.timerKey);
        _controller.dismiss(item.id);
      });
    }
  }

  void _setToastPaused(String toastId, bool paused, {bool updateActiveId = true}) {
    final wasPaused = _isPaused;
    if (paused) {
      _pausedToastIds.add(toastId);
    } else {
      _pausedToastIds.remove(toastId);
    }

    if (updateActiveId) {
      final nextActive = paused ? toastId : _latestId;
      if (nextActive != _activeId && mounted) {
        setState(() => _activeId = nextActive);
      }
    }

    if (!wasPaused && _isPaused) {
      _clearAllTimers();
    } else if (wasPaused && !_isPaused) {
      _scheduleTimers(_toasts);
    }
  }

  Brightness _resolveBrightness(BuildContext context) {
    return switch (widget.themeMode) {
      SileoThemeMode.light => Brightness.light,
      SileoThemeMode.dark => Brightness.dark,
      SileoThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }

  Color _resolveDefaultFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? SileoDefaults.darkThemeFill
        : SileoDefaults.lightThemeFill;
  }

  @override
  void dispose() {
    _controller.removeListener(_onStoreChanged);
    _clearAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _buildViewports(context);
    final child = widget.child;
    if (child == null) {
      return overlay;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned.fill(child: overlay),
      ],
    );
  }

  Widget _buildViewports(BuildContext context) {
    if (_toasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.maybeOf(context);
    final safePadding = widget.useSafeArea
        ? (mediaQuery?.padding ?? EdgeInsets.zero)
        : EdgeInsets.zero;
    final brightness = _resolveBrightness(context);
    final defaultFill = _resolveDefaultFill(brightness);

    final grouped = <SileoPosition, List<SileoToastItem>>{};
    for (final toast in _toasts) {
      grouped.putIfAbsent(toast.position, () => <SileoToastItem>[]).add(toast);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (mediaQuery?.size.width ?? SileoDefaults.maxWidth);

        final horizontalInset =
            widget.offset.left + widget.offset.right + safePadding.left + safePadding.right;
        final clampedMaxWidth = math
            .min(
              widget.maxWidth,
              math.max(SileoDefaults.pillHeight, viewportWidth - horizontalInset),
            )
            .toDouble();

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final entry in grouped.entries)
              _buildPositionViewport(
                position: entry.key,
                items: entry.value,
                safePadding: safePadding,
                defaultFill: defaultFill,
                ambientBrightness: brightness,
                clampedMaxWidth: clampedMaxWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildPositionViewport({
    required SileoPosition position,
    required List<SileoToastItem> items,
    required EdgeInsets safePadding,
    required Color defaultFill,
    required Brightness ambientBrightness,
    required double clampedMaxWidth,
  }) {
    final alignment = switch (position) {
      SileoPosition.topLeft => Alignment.topLeft,
      SileoPosition.topCenter => Alignment.topCenter,
      SileoPosition.topRight => Alignment.topRight,
      SileoPosition.bottomLeft => Alignment.bottomLeft,
      SileoPosition.bottomCenter => Alignment.bottomCenter,
      SileoPosition.bottomRight => Alignment.bottomRight,
    };

    final crossAxis = switch (position.horizontalAlignment) {
      SileoHorizontalAlignment.left => CrossAxisAlignment.start,
      SileoHorizontalAlignment.center => CrossAxisAlignment.center,
      SileoHorizontalAlignment.right => CrossAxisAlignment.end,
    };

    // Match Sileo web stacking order: newest toast sits closest to the anchored edge.
    final orderedItems = position.isTop ? items.reversed.toList(growable: false) : items;

    final edgePadding = EdgeInsets.only(
      top: position.isTop ? widget.offset.top + safePadding.top : 0,
      bottom: position.isBottom ? widget.offset.bottom + safePadding.bottom : 0,
      left: widget.offset.left + safePadding.left,
      right: widget.offset.right + safePadding.right,
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: edgePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxis,
          children: <Widget>[
            for (var i = 0; i < orderedItems.length; i++) ...<Widget>[
              if (i > 0) SizedBox(height: widget.gap),
              _buildToastWidget(
                item: orderedItems[i],
                position: position,
                defaultFill: defaultFill,
                ambientBrightness: ambientBrightness,
                clampedMaxWidth: clampedMaxWidth,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToastWidget({
    required SileoToastItem item,
    required SileoPosition position,
    required Color defaultFill,
    required Brightness ambientBrightness,
    required double clampedMaxWidth,
  }) {
    final opts = item.options;
    return SileoToast(
      key: ValueKey<String>('sileo-toast-${item.id}'),
      id: item.id,
      state: item.state,
      title: opts.title,
      description: opts.description,
      descriptionWidget: opts.descriptionWidget,
      alignment: position.horizontalAlignment,
      expandDownward: position.expandsDownward,
      maxWidth: clampedMaxWidth,
      icon: opts.icon,
      fill: opts.fill ?? defaultFill,
      surfaceStyle: opts.surfaceStyle ?? widget.surfaceStyle,
      glassOptions: opts.glassOptions ?? widget.glassOptions,
      ambientBrightness: ambientBrightness,
      styles: opts.styles,
      button: opts.button,
      roundness: opts.roundness ?? SileoDefaults.roundness,
      elevation: opts.elevation ?? SileoDefaults.elevation,
      border: opts.border,
      exiting: item.exiting,
      dismissible: opts.dismissible ?? true,
      autoExpandDelay: item.autoExpandDelay,
      autoCollapseDelay: item.autoCollapseDelay,
      refreshKey: item.instanceId,
      canExpand: _activeId == null || _activeId == item.id,
      stateColors: widget.stateColors,
      onHoverChanged: (hovered) => _setToastPaused(item.id, hovered),
      onInteractionPauseChanged: (paused) => _setToastPaused(item.id, paused),
      onDismiss: () => _controller.dismiss(item.id),
    );
  }
}
