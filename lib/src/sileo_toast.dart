import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'sileo_gooey_painter.dart';
import 'sileo_icons.dart';
import 'sileo_liquid_glass.dart';
import 'types.dart';

/// A single physics-driven, gooey morphing Sileo toast notification widget.
///
/// Normally mounted and managed automatically by `SileoToaster`, though it can
/// also be rendered standalone for custom previews or showcases.
class SileoToast extends StatefulWidget {
  /// Creates a Sileo toast widget.
  const SileoToast({
    super.key,
    required this.id,
    required this.fill,
    required this.state,
    required this.alignment,
    required this.expandDownward,
    required this.maxWidth,
    this.title,
    this.description,
    this.descriptionWidget,
    this.icon,
    this.styles,
    this.button,
    this.roundness = SileoDefaults.roundness,
    this.elevation = SileoDefaults.elevation,
    this.border,
    this.surfaceStyle = SileoSurfaceStyle.solid,
    this.glassOptions = const SileoGlassOptions(),
    this.ambientBrightness = Brightness.light,
    this.exiting = false,
    this.canExpand = true,
    this.dismissible = true,
    this.autoExpandDelay,
    this.autoCollapseDelay,
    this.refreshKey,
    this.stateColors = const SileoStateColors(),
    this.onHoverChanged,
    this.onInteractionPauseChanged,
    this.onDismiss,
  });

  /// Stable toast identifier.
  final String id;

  /// Surface background color of the gooey pill and expanded card.
  final Color fill;

  /// Current semantic state controlling badge color and default icon.
  final SileoState state;

  /// Horizontal anchor of the pill relative to the expanded body.
  final SileoHorizontalAlignment alignment;

  /// Whether the expanded body grows downward (`true`) or upward (`false`).
  final bool expandDownward;

  /// Maximum width available for the expanded toast card.
  final double maxWidth;

  /// Header title shown next to the badge.
  final String? title;

  /// Optional plain-text description rendered in the expanded body.
  final String? description;

  /// Optional custom widget rendered in the expanded body.
  final Widget? descriptionWidget;

  /// Optional custom icon widget replacing the default state icon.
  final Widget? icon;

  /// Optional style overrides for title, description, badge, and button.
  final SileoStyles? styles;

  /// Optional action button rendered inside the expanded body.
  final SileoButton? button;

  /// Corner radius and concave fillet radius in logical pixels.
  final double roundness;

  /// Soft drop shadow elevation behind the silhouette.
  final double elevation;

  /// Optional hairline stroke drawn around the silhouette.
  final BorderSide? border;

  /// Surface rendering mode (`solid` by default, or `liquidGlass`).
  final SileoSurfaceStyle surfaceStyle;

  /// Material settings used when [surfaceStyle] is [SileoSurfaceStyle.liquidGlass].
  final SileoGlassOptions glassOptions;

  /// Ambient brightness of the screen beneath the toast, used for liquid glass tinting.
  final Brightness ambientBrightness;

  /// Whether this toast is currently animating out before removal.
  final bool exiting;

  /// Whether this toast is currently permitted to auto-expand.
  final bool canExpand;

  /// Whether vertical swipe-to-dismiss is enabled.
  final bool dismissible;

  /// Delay before automatically expanding the toast body.
  final Duration? autoExpandDelay;

  /// Delay before automatically collapsing the toast body.
  final Duration? autoCollapseDelay;

  /// Revision token triggering collapse-then-swap morphing when updated.
  final String? refreshKey;

  /// Accent color palette for semantic states.
  final SileoStateColors stateColors;

  /// Invoked when pointer hover enters or exits this toast.
  final ValueChanged<bool>? onHoverChanged;

  /// Invoked when touch interaction requests pausing or resuming auto-dismiss.
  final ValueChanged<bool>? onInteractionPauseChanged;

  /// Invoked when the user swipes the toast past the dismiss threshold.
  final VoidCallback? onDismiss;

  @override
  State<SileoToast> createState() => _SileoToastState();
}

class _ToastViewSnapshot {
  const _ToastViewSnapshot({
    required this.title,
    required this.description,
    required this.descriptionWidget,
    required this.state,
    required this.icon,
    required this.styles,
    required this.button,
    required this.fill,
    required this.surfaceStyle,
    required this.glassOptions,
  });

  final String title;
  final String? description;
  final Widget? descriptionWidget;
  final SileoState state;
  final Widget? icon;
  final SileoStyles? styles;
  final SileoButton? button;
  final Color fill;
  final SileoSurfaceStyle surfaceStyle;
  final SileoGlassOptions glassOptions;

  String get headerKey => '${state.name}-$title';

  bool get hasBody =>
      (description != null && description!.isNotEmpty) ||
      descriptionWidget != null ||
      button != null;

  _ToastViewSnapshot copyWith({
    Color? fill,
    SileoSurfaceStyle? surfaceStyle,
    SileoGlassOptions? glassOptions,
  }) {
    return _ToastViewSnapshot(
      title: title,
      description: description,
      descriptionWidget: descriptionWidget,
      state: state,
      icon: icon,
      styles: styles,
      button: button,
      fill: fill ?? this.fill,
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      glassOptions: glassOptions ?? this.glassOptions,
    );
  }
}

class _HeaderEntry {
  const _HeaderEntry({required this.key, required this.view});

  final String key;
  final _ToastViewSnapshot view;
}

class _SileoToastState extends State<SileoToast> with TickerProviderStateMixin {
  late _ToastViewSnapshot _view;
  late _HeaderEntry _currentHeader;
  _HeaderEntry? _prevHeader;

  String? _lastRefreshKey;
  String? _appliedRefreshKey;
  ({String? key, _ToastViewSnapshot payload})? _pendingSwap;

  bool _isExpanded = false;
  bool _isHovered = false;
  bool _isManuallyExpanded = false;
  bool _ready = false;
  bool _hasStartedEntry = false;
  bool _hasMeasuredPill = false;

  double _pillWidth = SileoDefaults.pillHeight;
  double _contentHeight = 0.0;
  double _frozenExpandedHeight = SileoDefaults.pillHeight * SileoDefaults.minExpandRatio;
  double _dragAccumulatedY = 0.0;

  Timer? _autoExpandTimer;
  Timer? _autoCollapseTimer;
  Timer? _swapTimer;
  Timer? _headerExitTimer;
  Timer? _contentDelayTimer;

  late final AnimationController _entryController;
  late final AnimationController _bodyHeightController;
  late final AnimationController _pillWidthController;
  late final AnimationController _pillXController;
  late final AnimationController _headerShiftController;
  late final AnimationController _contentOpacityController;
  late final AnimationController _dragOffsetController;
  late final AnimationController _headerEnterController;
  late final AnimationController _headerExitController;

  bool _reduceMotion = false;

  bool get _isLoading => _view.state == SileoState.loading;
  bool get _hasDesc => _view.hasBody;
  bool get _open => _hasDesc && _isExpanded && !_isLoading && !widget.exiting;
  bool get _allowExpand => !_isLoading && widget.canExpand;

  double get _toastWidth => math.max(SileoDefaults.pillHeight, widget.maxWidth);

  double get _maxHeaderInnerWidth => math.max(
    SileoDefaults.pillHeight,
    _toastWidth - SileoDefaults.headerPadding * 2 - SileoDefaults.pillExtraPadding,
  );

  double get _minExpandedHeight => SileoDefaults.pillHeight * SileoDefaults.minExpandRatio;

  double get _rawExpandedHeight => _hasDesc
      ? math.max(_minExpandedHeight, SileoDefaults.pillHeight + _contentHeight)
      : _minExpandedHeight;

  double get _resolvedPillWidth => _pillWidth.clamp(SileoDefaults.pillHeight, _toastWidth);

  double _computePillX(double pillW) {
    final maxOffset = math.max(0.0, _toastWidth - pillW);
    return switch (widget.alignment) {
      SileoHorizontalAlignment.left => 0.0,
      SileoHorizontalAlignment.center => maxOffset / 2.0,
      SileoHorizontalAlignment.right => maxOffset,
    };
  }

  _ToastViewSnapshot _snapshotFromWidget(SileoToast w) {
    final resolvedTitle = (w.title != null && w.title!.isNotEmpty)
        ? w.title!
        : _capitalize(w.state.name);
    return _ToastViewSnapshot(
      title: resolvedTitle,
      description: w.description,
      descriptionWidget: w.descriptionWidget,
      state: w.state,
      icon: w.icon,
      styles: w.styles,
      button: w.button,
      fill: w.fill,
      surfaceStyle: w.surfaceStyle,
      glassOptions: w.glassOptions,
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _view = _snapshotFromWidget(widget);
    _currentHeader = _HeaderEntry(key: _view.headerKey, view: _view);
    _lastRefreshKey = widget.refreshKey;
    _appliedRefreshKey = widget.refreshKey;

    _entryController = AnimationController.unbounded(vsync: this);
    _bodyHeightController = AnimationController.unbounded(vsync: this);
    _pillWidthController = AnimationController.unbounded(
      vsync: this,
      value: SileoDefaults.pillHeight,
    );
    _pillXController = AnimationController.unbounded(
      vsync: this,
      value: _computePillX(SileoDefaults.pillHeight),
    );
    _headerShiftController = AnimationController.unbounded(vsync: this);
    _contentOpacityController = AnimationController(
      vsync: this,
      value: 0.0,
      duration: SileoDefaults.contentOpenDuration,
    );
    _dragOffsetController = AnimationController.unbounded(vsync: this);
    _headerEnterController = AnimationController(
      vsync: this,
      value: 0.0,
      duration: SileoDefaults.animationDuration,
    );
    _headerExitController = AnimationController(
      vsync: this,
      value: 0.0,
      duration: SileoDefaults.headerExitDuration,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ready = true;
      _scheduleAutopilot();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_hasStartedEntry) {
      _hasStartedEntry = true;
      _animateEntry(entering: !widget.exiting);
      if (_reduceMotion) {
        _headerEnterController.value = 1.0;
      } else {
        unawaited(_headerEnterController.forward(from: 0.0));
      }
    }
  }

  @override
  void didUpdateWidget(covariant SileoToast oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextSnapshot = _snapshotFromWidget(widget);

    // Sync surface fill and surface style immediately so theme / mode toggles respond smoothly.
    if (widget.fill != oldWidget.fill ||
        widget.surfaceStyle != oldWidget.surfaceStyle ||
        widget.glassOptions != oldWidget.glassOptions) {
      _view = _view.copyWith(
        fill: widget.fill,
        surfaceStyle: widget.surfaceStyle,
        glassOptions: widget.glassOptions,
      );
      _currentHeader = _HeaderEntry(key: _currentHeader.key, view: _view);
    }

    // Handle exit transition.
    if (widget.exiting != oldWidget.exiting) {
      if (widget.exiting) {
        _setExpanded(false);
        _animateEntry(entering: false);
      } else {
        _animateEntry(entering: true);
      }
    }

    // Handle refresh / morph updates with collapse-before-swap choreography.
    if (widget.refreshKey == null) {
      _applyViewUpdate(nextSnapshot, appliedKey: null);
      _lastRefreshKey = null;
      _pendingSwap = null;
    } else if (_lastRefreshKey != widget.refreshKey) {
      _lastRefreshKey = widget.refreshKey;
      _swapTimer?.cancel();
      _swapTimer = null;

      if (_open) {
        _pendingSwap = (key: widget.refreshKey, payload: nextSnapshot);
        _isManuallyExpanded = false;
        _setExpanded(false);
        _swapTimer = Timer(SileoDefaults.swapCollapseDelay, () {
          _swapTimer = null;
          if (!mounted) return;
          final pending = _pendingSwap;
          if (pending == null) return;
          _pendingSwap = null;
          _applyViewUpdate(pending.payload, appliedKey: pending.key);
          _scheduleAutopilot();
        });
      } else {
        _pendingSwap = null;
        _applyViewUpdate(nextSnapshot, appliedKey: widget.refreshKey);
        _scheduleAutopilot();
      }
    }

    // Re-sync alignment or viewport width changes.
    if (widget.alignment != oldWidget.alignment || widget.maxWidth != oldWidget.maxWidth) {
      final targetW = _resolvedPillWidth;
      final targetX = _computePillX(targetW);
      _animateSpring(_pillWidthController, targetW, SileoDefaults.openSpring, immediate: !_ready);
      _animateSpring(_pillXController, targetX, SileoDefaults.openSpring, immediate: !_ready);
    }

    // Re-evaluate autopilot if expand permission or delays changed.
    if (_pendingSwap == null &&
        (widget.canExpand != oldWidget.canExpand ||
            widget.autoExpandDelay != oldWidget.autoExpandDelay ||
            widget.autoCollapseDelay != oldWidget.autoCollapseDelay)) {
      _scheduleAutopilot();
    }
  }

  void _applyViewUpdate(_ToastViewSnapshot next, {required String? appliedKey}) {
    final prevHeader = _currentHeader;
    final headerChanged = prevHeader.key != next.headerKey;

    setState(() {
      _view = next;
      _appliedRefreshKey = appliedKey;
      if (headerChanged) {
        _prevHeader = prevHeader;
        _currentHeader = _HeaderEntry(key: next.headerKey, view: next);
      } else {
        _currentHeader = _HeaderEntry(key: next.headerKey, view: next);
      }
    });

    if (headerChanged) {
      _headerExitTimer?.cancel();
      if (_reduceMotion) {
        _headerEnterController.value = 1.0;
        _headerExitController.value = 1.0;
        setState(() => _prevHeader = null);
      } else {
        unawaited(_headerEnterController.forward(from: 0.0));
        unawaited(_headerExitController.forward(from: 0.0));
        _headerExitTimer = Timer(SileoDefaults.headerExitDuration, () {
          _headerExitTimer = null;
          if (!mounted) return;
          setState(() => _prevHeader = null);
        });
      }
    }

    if (!_view.hasBody) {
      _contentHeight = 0.0;
      _setExpanded(false);
    } else if (_open) {
      _syncOpenAnimations();
    }
  }

  void _scheduleAutopilot() {
    _autoExpandTimer?.cancel();
    _autoExpandTimer = null;
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = null;

    if (!_hasDesc) {
      _setExpanded(false);
      return;
    }

    if (widget.exiting || !_allowExpand) {
      _setExpanded(false);
      return;
    }

    // Do not override active hover or manual touch expansion.
    if (_isHovered || _isManuallyExpanded) return;

    final expandDelay = widget.autoExpandDelay;
    final collapseDelay = widget.autoCollapseDelay;
    if (expandDelay == null && collapseDelay == null) return;

    if (expandDelay != null) {
      if (expandDelay > Duration.zero) {
        _autoExpandTimer = Timer(expandDelay, () {
          _autoExpandTimer = null;
          if (!mounted || widget.exiting || !_allowExpand) return;
          _setExpanded(true);
        });
      } else {
        _setExpanded(true);
      }
    }

    if (collapseDelay != null && collapseDelay > Duration.zero) {
      _autoCollapseTimer = Timer(collapseDelay, () {
        _autoCollapseTimer = null;
        if (!mounted || _isHovered || _isManuallyExpanded) return;
        _setExpanded(false);
      });
    }
  }

  void _setExpanded(bool value) {
    final nextExpanded = value && _hasDesc && !_isLoading && !widget.exiting;
    if (_isExpanded == nextExpanded) {
      // Ensure body height still stays synced if content size changed while open.
      if (nextExpanded) {
        _syncOpenAnimations();
      }
      return;
    }

    setState(() {
      _isExpanded = nextExpanded;
      if (_open) {
        _frozenExpandedHeight = _rawExpandedHeight;
      }
    });

    _syncOpenAnimations();
  }

  void _syncOpenAnimations() {
    final isOpen = _open;
    if (isOpen) {
      _frozenExpandedHeight = _rawExpandedHeight;
    }
    final expandedTotal = isOpen ? _rawExpandedHeight : _frozenExpandedHeight;
    final targetBodyHeight = isOpen ? math.max(0.0, expandedTotal - SileoDefaults.pillHeight) : 0.0;

    final spring = isOpen ? SileoDefaults.openSpring : SileoDefaults.closeSpring;
    _animateSpring(_bodyHeightController, targetBodyHeight, spring, immediate: _reduceMotion);
    _animateSpring(_headerShiftController, isOpen ? 1.0 : 0.0, spring, immediate: _reduceMotion);

    _contentDelayTimer?.cancel();
    _contentDelayTimer = null;

    if (_reduceMotion) {
      _contentOpacityController.value = isOpen ? 1.0 : 0.0;
      return;
    }

    if (isOpen) {
      _contentOpacityController.duration = SileoDefaults.contentOpenDuration;
      _contentDelayTimer = Timer(SileoDefaults.contentOpenDelay, () {
        _contentDelayTimer = null;
        if (!mounted || !_open) return;
        unawaited(_contentOpacityController.forward());
      });
    } else {
      _contentOpacityController.duration = SileoDefaults.contentCloseDuration;
      unawaited(_contentOpacityController.reverse());
    }
  }

  void _animateEntry({required bool entering}) {
    final target = entering ? 1.0 : 0.0;
    if (_reduceMotion) {
      _entryController.value = target;
      return;
    }
    final spring = entering ? SileoDefaults.entrySpring : SileoDefaults.closeSpring;
    _animateSpring(_entryController, target, spring);
  }

  void _animateSpring(
    AnimationController controller,
    double target,
    SpringDescription spring, {
    bool immediate = false,
  }) {
    if (immediate || _reduceMotion) {
      controller.value = target;
      return;
    }
    if ((controller.value - target).abs() < 0.05 && controller.velocity.abs() < 0.05) {
      controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      spring,
      controller.value,
      target,
      controller.velocity,
      tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
    );
    unawaited(controller.animateWith(simulation));
  }

  void _onHeaderSizeChanged(Size size) {
    if (!mounted) return;
    final measured = (size.width + SileoDefaults.headerPadding * 2 + SileoDefaults.pillExtraPadding)
        .clamp(SileoDefaults.pillHeight, _toastWidth);

    if (_hasMeasuredPill && (measured - _pillWidth).abs() < 0.5) return;

    final isFirstMeasurement = !_hasMeasuredPill;
    _hasMeasuredPill = true;
    _pillWidth = measured;

    final targetX = _computePillX(measured);
    final immediate = isFirstMeasurement || !_ready || _reduceMotion;
    _animateSpring(_pillWidthController, measured, SileoDefaults.openSpring, immediate: immediate);
    _animateSpring(_pillXController, targetX, SileoDefaults.openSpring, immediate: immediate);
  }

  void _onContentSizeChanged(Size size) {
    if (!mounted) return;
    if ((size.height - _contentHeight).abs() < 0.5) return;
    _contentHeight = size.height;
    if (_open) {
      _frozenExpandedHeight = _rawExpandedHeight;
      final targetBody = math.max(0.0, _rawExpandedHeight - SileoDefaults.pillHeight);
      _animateSpring(_bodyHeightController, targetBody, SileoDefaults.openSpring);
    }
  }

  void _handleMouseEnter() {
    if (widget.exiting) return;
    _isHovered = true;
    widget.onHoverChanged?.call(true);
    if (_hasDesc && !_isLoading) {
      _setExpanded(true);
    }
  }

  void _handleMouseExit() {
    _isHovered = false;
    widget.onHoverChanged?.call(false);
    if (!_isManuallyExpanded) {
      _setExpanded(false);
    }
  }

  void _handleTap() {
    if (widget.exiting || !_hasDesc || _isLoading) return;
    final next = !_open;
    _isManuallyExpanded = next;
    _setExpanded(next);
    widget.onInteractionPauseChanged?.call(next);
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.exiting || !widget.dismissible || widget.onDismiss == null) return;
    _dragAccumulatedY = 0.0;
    _dragOffsetController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.exiting || !widget.dismissible || widget.onDismiss == null) return;
    _dragAccumulatedY += details.delta.dy;
    final sign = _dragAccumulatedY >= 0 ? 1.0 : -1.0;
    final clamped = math.min(_dragAccumulatedY.abs(), SileoDefaults.swipeMaxOffset) * sign;
    _dragOffsetController.value = clamped;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.exiting || !widget.dismissible || widget.onDismiss == null) return;
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    final shouldDismiss =
        _dragAccumulatedY.abs() > SileoDefaults.swipeDismissDistance ||
        velocity > SileoDefaults.swipeDismissVelocity;
    _dragAccumulatedY = 0.0;

    if (shouldDismiss) {
      _isManuallyExpanded = false;
      widget.onInteractionPauseChanged?.call(false);
      widget.onDismiss?.call();
    } else {
      _animateSpring(_dragOffsetController, 0.0, SileoDefaults.dragReturnSpring);
    }
  }

  void _handleDragCancel() {
    _dragAccumulatedY = 0.0;
    _animateSpring(_dragOffsetController, 0.0, SileoDefaults.dragReturnSpring);
  }

  @override
  void dispose() {
    _autoExpandTimer?.cancel();
    _autoCollapseTimer?.cancel();
    _swapTimer?.cancel();
    _headerExitTimer?.cancel();
    _contentDelayTimer?.cancel();
    _entryController.dispose();
    _bodyHeightController.dispose();
    _pillWidthController.dispose();
    _pillXController.dispose();
    _headerShiftController.dispose();
    _contentOpacityController.dispose();
    _dragOffsetController.dispose();
    _headerEnterController.dispose();
    _headerExitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.stateColors.colorFor(_view.state);
    final isLiquidGlass = _view.surfaceStyle == SileoSurfaceStyle.liquidGlass;
    final Color defaultDescriptionColor;
    if (isLiquidGlass) {
      defaultDescriptionColor = widget.ambientBrightness == Brightness.dark
          ? const Color(0xF0FFFFFF)
          : const Color(0xEB101015);
    } else {
      final isLightSurface = _view.fill.computeLuminance() > 0.5;
      defaultDescriptionColor = isLightSurface
          ? const Color.fromRGBO(0, 0, 0, 0.62)
          : const Color.fromRGBO(255, 255, 255, 0.66);
    }

    final headerWidget = _buildHeaderLayers();
    final bodyWidget = _hasDesc
        ? _buildBodyContent(
            accentColor: accentColor,
            defaultDescriptionColor: defaultDescriptionColor,
          )
        : null;

    final animListenable = Listenable.merge(<Listenable>[
      _entryController,
      _bodyHeightController,
      _pillWidthController,
      _pillXController,
      _headerShiftController,
      _dragOffsetController,
    ]);

    // Track appliedRefreshKey in semantics label for debugging / a11y continuity.
    return Semantics(
      liveRegion: true,
      label: _view.title,
      hint: _view.description,
      child: IgnorePointer(
        ignoring: widget.exiting,
        child: AnimatedBuilder(
          animation: animListenable,
          builder: (context, _) {
            final entry = _entryController.value;
            final entryClamped = entry.clamp(0.0, 1.0);
            final bodyH = math.max(0.0, _bodyHeightController.value);
            final pillW = _pillWidthController.value
                .clamp(SileoDefaults.pillHeight, _toastWidth)
                .toDouble();
            final pillX = _pillXController.value
                .clamp(0.0, math.max(0.0, _toastWidth - pillW))
                .toDouble();
            final totalH = SileoDefaults.pillHeight + bodyH;
            final shift = _headerShiftController.value;
            final dragY = _dragOffsetController.value;

            final slideDistance = widget.expandDownward ? -6.0 : 6.0;
            final entrySlideY = ui.lerpDouble(slideDistance, 0.0, entry)!;
            final entryScale = ui.lerpDouble(0.95, 1.0, entry)!;

            final headerShiftY = (widget.expandDownward ? 3.0 : -3.0) * shift;
            final headerScale = ui.lerpDouble(1.0, 0.9, shift)!;

            final pillTop = widget.expandDownward ? 0.0 : bodyH;
            final bodyTop = widget.expandDownward ? SileoDefaults.pillHeight : 0.0;
            final resolvedRoundness = math.max(0.0, widget.roundness);

            final gooeyPath = buildSileoGooeyPath(
              width: _toastWidth,
              pillHeight: SileoDefaults.pillHeight,
              pillX: pillX,
              pillWidth: pillW,
              bodyHeight: bodyH,
              roundness: resolvedRoundness,
              expandDownward: widget.expandDownward,
            );

            final pillRect = Rect.fromLTWH(pillX, pillTop, pillW, SileoDefaults.pillHeight);
            final bodyRect = bodyH > 1.0 ? Rect.fromLTWH(0, bodyTop, _toastWidth, bodyH) : null;

            final Widget surfaceLayer = isLiquidGlass
                ? SileoLiquidGlassSurface(
                    width: _toastWidth,
                    pillHeight: SileoDefaults.pillHeight,
                    pillX: pillX,
                    pillWidth: pillW,
                    bodyHeight: bodyH,
                    roundness: resolvedRoundness,
                    expandDownward: widget.expandDownward,
                    ambientBrightness: widget.ambientBrightness,
                    opacity: entryClamped,
                    glassOptions: _view.glassOptions,
                  )
                : RepaintBoundary(
                    child: CustomPaint(
                      painter: SileoGooeyPainter(
                        pillHeight: SileoDefaults.pillHeight,
                        pillX: pillX,
                        pillWidth: pillW,
                        bodyHeight: bodyH,
                        roundness: resolvedRoundness,
                        fill: _view.fill,
                        expandDownward: widget.expandDownward,
                        elevation: math.max(0.0, widget.elevation),
                        border: widget.border,
                        cachedPath: gooeyPath,
                      ),
                    ),
                  );

            final toastStack = SizedBox(
              width: _toastWidth,
              height: totalH,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Gooey solid or real-time refractive Liquid Glass silhouette
                  Positioned.fill(child: surfaceLayer),

                  // Expanded body content clipped strictly to the liquid silhouette
                  if (bodyWidget != null)
                    Positioned(
                      left: 0,
                      width: _toastWidth,
                      top: bodyTop,
                      height: bodyH,
                      child: ClipPath(
                        clipper: _SileoShiftedPathClipper(
                          path: gooeyPath,
                          dy: -bodyTop,
                          width: _toastWidth,
                          bodyHeight: bodyH,
                          pillX: pillX,
                          pillWidth: pillW,
                          roundness: resolvedRoundness,
                          expandDownward: widget.expandDownward,
                        ),
                        child: OverflowBox(
                          alignment: widget.expandDownward
                              ? Alignment.topCenter
                              : Alignment.bottomCenter,
                          minWidth: _toastWidth,
                          maxWidth: _toastWidth,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: IgnorePointer(
                            ignoring: !_open,
                            child: ExcludeSemantics(
                              excluding: !_open,
                              child: AnimatedBuilder(
                                animation: _contentOpacityController,
                                builder: (context, child) {
                                  final baseOp = Curves.easeOut.transform(
                                    _contentOpacityController.value.clamp(0.0, 1.0),
                                  );
                                  final op = isLiquidGlass ? baseOp * entryClamped : baseOp;
                                  final slide =
                                      (1.0 - baseOp) * (widget.expandDownward ? -4.0 : 4.0);
                                  return Opacity(
                                    opacity: op,
                                    child: Transform.translate(
                                      offset: Offset(0, slide),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _MeasureSize(
                                  onChange: _onContentSizeChanged,
                                  child: bodyWidget,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Header pill (badge + title) with subtle open shift
                  Positioned(
                    left: pillX,
                    top: pillTop,
                    width: pillW,
                    height: SileoDefaults.pillHeight,
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(0, headerShiftY),
                        child: Transform.scale(
                          scale: headerScale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SileoDefaults.headerPadding,
                            ),
                            child: OverflowBox(
                              alignment: AlignmentDirectional.centerStart,
                              minWidth: 0,
                              maxWidth: _maxHeaderInnerWidth,
                              minHeight: 0,
                              maxHeight: SileoDefaults.pillHeight,
                              child: isLiquidGlass
                                  ? Opacity(opacity: entryClamped, child: headerWidget)
                                  : headerWidget,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final interactiveCore = Transform.translate(
              offset: Offset(0, entrySlideY + dragY),
              child: Transform.scale(
                scale: entryScale,
                child: _SileoHitTestMask(
                  pillRect: pillRect,
                  bodyRect: bodyRect,
                  child: MouseRegion(
                    cursor: _isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                    onEnter: (_) => _handleMouseEnter(),
                    onExit: (_) => _handleMouseExit(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleTap,
                      onVerticalDragStart: _handleDragStart,
                      onVerticalDragUpdate: _handleDragUpdate,
                      onVerticalDragEnd: _handleDragEnd,
                      onVerticalDragCancel: _handleDragCancel,
                      child: toastStack,
                    ),
                  ),
                ),
              ),
            );

            return ClipRect(
              clipBehavior: Clip.none,
              child: Align(
                alignment: widget.expandDownward ? Alignment.topCenter : Alignment.bottomCenter,
                widthFactor: 1.0,
                heightFactor: math.max(0.0, entryClamped),
                // Avoid isolating LiquidGlassBlender inside an Opacity layer so
                // live Impeller refraction keeps sampling the real backdrop.
                child: isLiquidGlass
                    ? interactiveCore
                    : Opacity(opacity: entryClamped, child: interactiveCore),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderLayers() {
    final maxInnerWidth = _maxHeaderInnerWidth;

    final currentRow = _MeasureSize(
      onChange: _onHeaderSizeChanged,
      child: _buildHeaderRow(_currentHeader.view, maxInnerWidth),
    );

    final prev = _prevHeader;

    return Stack(
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.none,
      children: <Widget>[
        if (prev != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _headerExitController,
              builder: (context, child) {
                final t = Curves.easeOut.transform(_headerExitController.value);
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final sigma = 6.0 * t;
                return _maybeBlur(
                  sigma: sigma,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: _buildHeaderRow(prev.view, maxInnerWidth),
            ),
          ),
        AnimatedBuilder(
          animation: _headerEnterController,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_headerEnterController.value);
            final opacity = t.clamp(0.0, 1.0);
            final sigma = 6.0 * (1.0 - t);
            return _maybeBlur(
              sigma: sigma,
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>('${_currentHeader.key}:${_appliedRefreshKey ?? ''}'),
            child: currentRow,
          ),
        ),
      ],
    );
  }

  Widget _maybeBlur({required double sigma, required Widget child}) {
    // Skip ImageFiltered offscreen layer completely when at rest.
    if (sigma <= 0.05) return child;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }

  Widget _buildHeaderRow(_ToastViewSnapshot view, double maxInnerWidth) {
    final accentColor = widget.stateColors.colorFor(view.state);
    final styles = view.styles;
    final isGlass = view.surfaceStyle == SileoSurfaceStyle.liquidGlass;
    final isDarkGlass = widget.ambientBrightness == Brightness.dark;

    final Color defaultBadgeBg;
    final Color defaultBadgeFg;
    final Color defaultTitleColor;
    final List<Shadow>? titleShadows;

    if (isGlass) {
      if (view.state == SileoState.loading) {
        defaultBadgeBg = isDarkGlass ? const Color(0x2EFFFFFF) : const Color(0x1C000000);
        defaultBadgeFg = isDarkGlass ? const Color(0xF0FFFFFF) : const Color(0xE0111116);
      } else {
        defaultBadgeBg = accentColor;
        defaultBadgeFg = accentColor.computeLuminance() > 0.52
            ? const Color(0xFF111114)
            : const Color(0xFFFFFFFF);
      }
      defaultTitleColor = isDarkGlass ? const Color(0xFAFFFFFF) : const Color(0xF20D0D12);
      titleShadows = isDarkGlass
          ? const <Shadow>[Shadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 1))]
          : const <Shadow>[Shadow(color: Color(0x66FFFFFF), blurRadius: 4)];
    } else {
      defaultBadgeBg = accentColor.withValues(alpha: 0.20);
      defaultBadgeFg = accentColor;
      defaultTitleColor = accentColor;
      titleShadows = null;
    }

    final badgeBg = styles?.badgeBackgroundColor ?? defaultBadgeBg;
    final badgeFg = styles?.badgeForegroundColor ?? defaultBadgeFg;

    final defaultTitleStyle = TextStyle(
      fontSize: 13.4,
      height: 16.0 / 13.4,
      fontWeight: isGlass ? FontWeight.w600 : FontWeight.w500,
      color: defaultTitleColor,
      shadows: titleShadows,
      decoration: TextDecoration.none,
    );
    final titleStyle = styles?.titleStyle != null
        ? defaultTitleStyle.merge(styles!.titleStyle)
        : defaultTitleStyle;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxInnerWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(color: badgeFg, size: 15),
              child: view.icon ?? SileoStateIcon(state: view.state, color: badgeFg),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              view.title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({required Color accentColor, required Color defaultDescriptionColor}) {
    final styles = _view.styles;
    final isGlass = _view.surfaceStyle == SileoSurfaceStyle.liquidGlass;
    final isDarkGlass = widget.ambientBrightness == Brightness.dark;
    final descShadows = isGlass
        ? (isDarkGlass
              ? const <Shadow>[
                  Shadow(color: Color(0x4D000000), blurRadius: 5, offset: Offset(0, 1)),
                ]
              : const <Shadow>[Shadow(color: Color(0x59FFFFFF), blurRadius: 4)])
        : null;

    final baseDescStyle = TextStyle(
      fontSize: 14.0,
      height: 20.0 / 14.0,
      fontWeight: FontWeight.w400,
      color: defaultDescriptionColor,
      shadows: descShadows,
      decoration: TextDecoration.none,
    );
    final resolvedDescStyle = styles?.descriptionStyle != null
        ? baseDescStyle.merge(styles!.descriptionStyle)
        : baseDescStyle;

    final padding = styles?.descriptionPadding ?? const EdgeInsets.all(16);

    return Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: resolvedDescStyle,
        textAlign: TextAlign.start,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_view.descriptionWidget != null)
              _view.descriptionWidget!
            else if (_view.description != null && _view.description!.isNotEmpty)
              Text(_view.description!),
            if (_view.button != null)
              Padding(
                padding: EdgeInsets.only(
                  top:
                      (_view.descriptionWidget != null ||
                          (_view.description != null && _view.description!.isNotEmpty))
                      ? 12.0
                      : 0.0,
                ),
                child: _SileoActionButton(
                  button: _view.button!,
                  accentColor: accentColor,
                  isLiquidGlass: isGlass,
                  styles: styles,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SileoActionButton extends StatefulWidget {
  const _SileoActionButton({
    required this.button,
    required this.accentColor,
    required this.isLiquidGlass,
    this.styles,
  });

  final SileoButton button;
  final Color accentColor;
  final bool isLiquidGlass;
  final SileoStyles? styles;

  @override
  State<_SileoActionButton> createState() => _SileoActionButtonState();
}

class _SileoActionButtonState extends State<_SileoActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final styles = widget.styles;
    final Color defaultFg;
    final Color defaultBg;
    final Color defaultHoverBg;

    if (widget.isLiquidGlass) {
      defaultBg = widget.accentColor.withValues(alpha: 0.90);
      defaultHoverBg = widget.accentColor;
      defaultFg = widget.accentColor.computeLuminance() > 0.52
          ? const Color(0xFF111114)
          : const Color(0xFFFFFFFF);
    } else {
      defaultFg = widget.accentColor;
      defaultBg = widget.accentColor.withValues(alpha: 0.15);
      defaultHoverBg = widget.accentColor.withValues(alpha: 0.25);
    }

    final fg = styles?.buttonForegroundColor ?? defaultFg;
    final bg = styles?.buttonBackgroundColor ?? defaultBg;
    final hoverBg = styles?.buttonHoverBackgroundColor ?? defaultHoverBg;

    final baseStyle = TextStyle(
      fontSize: 12.0,
      height: 1.0,
      fontWeight: widget.isLiquidGlass ? FontWeight.w600 : FontWeight.w500,
      color: fg,
      decoration: TextDecoration.none,
    );
    final textStyle = styles?.buttonTextStyle != null
        ? baseStyle.merge(styles!.buttonTextStyle)
        : baseStyle;

    return Semantics(
      button: true,
      label: widget.button.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.button.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: (_hovered || _pressed) ? hoverBg : bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[Text(widget.button.title, style: textStyle)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Restricts pointer hit-testing to the visible pill and active body rectangles
/// so transparent space beside a collapsed pill passes taps through to content
/// underneath.
class _SileoHitTestMask extends SingleChildRenderObjectWidget {
  const _SileoHitTestMask({required this.pillRect, required this.bodyRect, required super.child});

  final Rect pillRect;
  final Rect? bodyRect;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSileoHitTestMask(pillRect: pillRect, bodyRect: bodyRect);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSileoHitTestMask renderObject) {
    renderObject
      ..pillRect = pillRect
      ..bodyRect = bodyRect;
  }
}

class _RenderSileoHitTestMask extends RenderProxyBox {
  _RenderSileoHitTestMask({required Rect pillRect, required Rect? bodyRect})
    : _pillRect = pillRect,
      _bodyRect = bodyRect;

  Rect _pillRect;
  Rect? _bodyRect;

  set pillRect(Rect value) {
    _pillRect = value;
  }

  set bodyRect(Rect? value) {
    _bodyRect = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final insidePill = _pillRect.contains(position);
    final insideBody = _bodyRect != null && _bodyRect!.contains(position);
    if (!insidePill && !insideBody) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}

/// Reports layout size changes of its child after the current frame.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize == null || _oldSize == newSize) return;
    _oldSize = newSize;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!attached) return;
      onChange(newSize);
    });
  }
}

/// Clips the expanded body slot to the exact shifted gooey liquid contour.
class _SileoShiftedPathClipper extends CustomClipper<Path> {
  const _SileoShiftedPathClipper({
    required this.path,
    required this.dy,
    required this.width,
    required this.bodyHeight,
    required this.pillX,
    required this.pillWidth,
    required this.roundness,
    required this.expandDownward,
  });

  final Path path;
  final double dy;
  final double width;
  final double bodyHeight;
  final double pillX;
  final double pillWidth;
  final double roundness;
  final bool expandDownward;

  @override
  Path getClip(Size size) => dy == 0.0 ? path : path.shift(Offset(0, dy));

  @override
  bool shouldReclip(_SileoShiftedPathClipper oldClipper) {
    return oldClipper.width != width ||
        oldClipper.bodyHeight != bodyHeight ||
        oldClipper.pillX != pillX ||
        oldClipper.pillWidth != pillWidth ||
        oldClipper.roundness != roundness ||
        oldClipper.expandDownward != expandDownward ||
        oldClipper.dy != dy;
  }
}
