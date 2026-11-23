import 'package:flutter/widgets.dart';

import 'constants.dart';

/// Visual and semantic state of a Sileo toast.
enum SileoState {
  /// Positive confirmation state with a green check badge.
  success,

  /// In-progress state with a spinning circular indicator.
  loading,

  /// Failure state with a red close badge.
  error,

  /// Caution state with an amber alert badge.
  warning,

  /// Informational state with a sky-blue life-buoy badge.
  info,

  /// Interactive call-to-action state with a blue arrow badge.
  action,
}

/// Horizontal alignment of the pill relative to the expanded body.
enum SileoHorizontalAlignment {
  /// Pill anchored to the left edge of the toast body.
  left,

  /// Pill centered above or below the toast body.
  center,

  /// Pill anchored to the right edge of the toast body.
  right,
}

/// Screen anchor position for a toast viewport.
enum SileoPosition {
  /// Anchored at the top-left corner; expands downward.
  topLeft,

  /// Anchored at the top-center edge; expands downward.
  topCenter,

  /// Anchored at the top-right corner; expands downward.
  topRight,

  /// Anchored at the bottom-left corner; expands upward.
  bottomLeft,

  /// Anchored at the bottom-center edge; expands upward.
  bottomCenter,

  /// Anchored at the bottom-right corner; expands upward.
  bottomRight;

  /// Whether this position sits along the top edge of the viewport.
  bool get isTop => this == topLeft || this == topCenter || this == topRight;

  /// Whether this position sits along the bottom edge of the viewport.
  bool get isBottom => !isTop;

  /// Whether the toast body expands downward from the pill.
  bool get expandsDownward => isTop;

  /// Horizontal alignment of the pill within the toast card.
  SileoHorizontalAlignment get horizontalAlignment => switch (this) {
    topLeft || bottomLeft => SileoHorizontalAlignment.left,
    topCenter || bottomCenter => SileoHorizontalAlignment.center,
    topRight || bottomRight => SileoHorizontalAlignment.right,
  };
}

/// Theme resolution mode for automatic toast surface fill selection.
enum SileoThemeMode {
  /// Renders dark toasts designed for light backgrounds.
  light,

  /// Renders light toasts designed for dark backgrounds.
  dark,

  /// Follows the ambient [MediaQuery.platformBrightnessOf] brightness automatically.
  system,
}

/// Visual rendering surface style for a Sileo toast.
enum SileoSurfaceStyle {
  /// Solid analytic gooey silhouette (default).
  solid,

  /// Real-time refractive Apple-style liquid glass powered by
  /// `liquid_glass_easy`.
  liquidGlass,
}

/// Visual configuration for [SileoSurfaceStyle.liquidGlass] toasts.
@immutable
class SileoGlassOptions {
  /// Creates liquid glass material settings with Apple-tuned defaults.
  const SileoGlassOptions({
    this.blur = 2.2,
    this.refractionIndex = 1.15,
    this.refractionWidth = 18.0,
    this.dispersion = 1.2,
    this.saturation = 1.22,
    this.magnification = 1.0,
    this.blendSmoothness,
    this.tintColor,
    this.specularIntensity,
    this.liteGlass = false,
  });

  /// Gaussian blur sigma applied to the backdrop behind the glass.
  final double blur;

  /// Refractive index controlling how strongly glass edges bend the backdrop.
  final double refractionIndex;

  /// Width in logical pixels of the refractive bevel along the silhouette rim.
  final double refractionWidth;

  /// Chromatic dispersion fringe strength along the refractive rim.
  final double dispersion;

  /// Backdrop saturation multiplier (`1.0` = neutral, `> 1.0` = richer glass).
  final double saturation;

  /// Lens magnification factor (`1.0` = none).
  final double magnification;

  /// Optional metaball bridge radius fusing the pill and body glass surfaces.
  ///
  /// When `null`, scales automatically from the toast's `roundness`.
  final double? blendSmoothness;

  /// Optional glass tint color overriding the automatic theme-adaptive tint.
  final Color? tintColor;

  /// Optional specular highlight intensity along the glass rim.
  final double? specularIntensity;

  /// Whether to render lightweight frosted glass without GPU refraction shaders.
  final bool liteGlass;

  /// Returns a copy with selectively overridden glass settings.
  SileoGlassOptions copyWith({
    double? blur,
    double? refractionIndex,
    double? refractionWidth,
    double? dispersion,
    double? saturation,
    double? magnification,
    double? blendSmoothness,
    Color? tintColor,
    double? specularIntensity,
    bool? liteGlass,
  }) {
    return SileoGlassOptions(
      blur: blur ?? this.blur,
      refractionIndex: refractionIndex ?? this.refractionIndex,
      refractionWidth: refractionWidth ?? this.refractionWidth,
      dispersion: dispersion ?? this.dispersion,
      saturation: saturation ?? this.saturation,
      magnification: magnification ?? this.magnification,
      blendSmoothness: blendSmoothness ?? this.blendSmoothness,
      tintColor: tintColor ?? this.tintColor,
      specularIntensity: specularIntensity ?? this.specularIntensity,
      liteGlass: liteGlass ?? this.liteGlass,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SileoGlassOptions &&
        other.blur == blur &&
        other.refractionIndex == refractionIndex &&
        other.refractionWidth == refractionWidth &&
        other.dispersion == dispersion &&
        other.saturation == saturation &&
        other.magnification == magnification &&
        other.blendSmoothness == blendSmoothness &&
        other.tintColor == tintColor &&
        other.specularIntensity == specularIntensity &&
        other.liteGlass == liteGlass;
  }

  @override
  int get hashCode => Object.hash(
    blur,
    refractionIndex,
    refractionWidth,
    dispersion,
    saturation,
    magnification,
    blendSmoothness,
    tintColor,
    specularIntensity,
    liteGlass,
  );
}

/// How new toasts without an explicit [SileoOptions.id] behave when another
/// toast is already visible.
enum SileoStackBehavior {
  /// Replaces and morphs the active default toast in place (Sileo default).
  morph,

  /// Assigns each toast a unique identifier so multiple toasts stack together.
  stack,
}

/// Controls automatic expansion and collapse timing for toasts with body content.
@immutable
class SileoAutopilot {
  /// Creates an autopilot configuration with optional custom [expand] and
  /// [collapse] delays.
  const SileoAutopilot({this.enabled = true, this.expand, this.collapse});

  /// Enables default automatic expand and collapse delays.
  const SileoAutopilot.enabled() : enabled = true, expand = null, collapse = null;

  /// Disables automatic expand and collapse; users expand via hover or tap.
  const SileoAutopilot.disabled() : enabled = false, expand = null, collapse = null;

  /// Enables automatic behavior with custom [expand] and [collapse] delays.
  ///
  /// Passing [Duration.zero] for [collapse] keeps the toast expanded until
  /// dismissed.
  const SileoAutopilot.custom({this.expand, this.collapse}) : enabled = true;

  /// Whether autopilot timers are active.
  final bool enabled;

  /// Delay after showing before automatically expanding the toast body.
  final Duration? expand;

  /// Delay after showing before automatically collapsing the toast body.
  ///
  /// When equal to [Duration.zero], no auto-collapse timer is scheduled.
  final Duration? collapse;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SileoAutopilot &&
        other.enabled == enabled &&
        other.expand == expand &&
        other.collapse == collapse;
  }

  @override
  int get hashCode => Object.hash(enabled, expand, collapse);
}

/// Configuration for the action pill button rendered inside an expanded toast.
@immutable
class SileoButton {
  /// Creates a toast action button with a label [title] and [onPressed] handler.
  const SileoButton({required this.title, required this.onPressed});

  /// Text label displayed inside the action pill.
  final String title;

  /// Callback invoked when the action button is pressed.
  final VoidCallback onPressed;
}

/// Accent colors associated with each [SileoState].
@immutable
class SileoStateColors {
  /// Creates a palette mapping every [SileoState] to its accent color.
  const SileoStateColors({
    this.success = SileoDefaults.successColor,
    this.loading = SileoDefaults.loadingColor,
    this.error = SileoDefaults.errorColor,
    this.warning = SileoDefaults.warningColor,
    this.info = SileoDefaults.infoColor,
    this.action = SileoDefaults.actionColor,
  });

  /// Accent color for [SileoState.success].
  final Color success;

  /// Accent color for [SileoState.loading].
  final Color loading;

  /// Accent color for [SileoState.error].
  final Color error;

  /// Accent color for [SileoState.warning].
  final Color warning;

  /// Accent color for [SileoState.info].
  final Color info;

  /// Accent color for [SileoState.action].
  final Color action;

  /// Returns the configured accent color for [state].
  Color colorFor(SileoState state) => switch (state) {
    SileoState.success => success,
    SileoState.loading => loading,
    SileoState.error => error,
    SileoState.warning => warning,
    SileoState.info => info,
    SileoState.action => action,
  };

  /// Returns a copy with selectively overridden state colors.
  SileoStateColors copyWith({
    Color? success,
    Color? loading,
    Color? error,
    Color? warning,
    Color? info,
    Color? action,
  }) {
    return SileoStateColors(
      success: success ?? this.success,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      action: action ?? this.action,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SileoStateColors &&
        other.success == success &&
        other.loading == loading &&
        other.error == error &&
        other.warning == warning &&
        other.info == info &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(success, loading, error, warning, info, action);
}

/// Fine-grained visual overrides for sub-elements of a toast.
@immutable
class SileoStyles {
  /// Creates optional style overrides for title, description, badge, and button.
  const SileoStyles({
    this.titleStyle,
    this.descriptionStyle,
    this.badgeBackgroundColor,
    this.badgeForegroundColor,
    this.buttonBackgroundColor,
    this.buttonHoverBackgroundColor,
    this.buttonForegroundColor,
    this.buttonTextStyle,
    this.descriptionPadding,
  });

  /// Text style override applied to the header title.
  final TextStyle? titleStyle;

  /// Text style override applied to the description text and default text style.
  final TextStyle? descriptionStyle;

  /// Background color override for the circular icon badge.
  final Color? badgeBackgroundColor;

  /// Foreground color override for the icon inside the badge.
  final Color? badgeForegroundColor;

  /// Resting background color override for the action button.
  final Color? buttonBackgroundColor;

  /// Hover/pressed background color override for the action button.
  final Color? buttonHoverBackgroundColor;

  /// Foreground color override for the action button label.
  final Color? buttonForegroundColor;

  /// Text style override for the action button label.
  final TextStyle? buttonTextStyle;

  /// Padding around the expanded description content area.
  final EdgeInsetsGeometry? descriptionPadding;

  /// Merges [other] on top of this style, preferring non-null values from [other].
  SileoStyles merge(SileoStyles? other) {
    if (other == null) return this;
    return SileoStyles(
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
      badgeBackgroundColor: other.badgeBackgroundColor ?? badgeBackgroundColor,
      badgeForegroundColor: other.badgeForegroundColor ?? badgeForegroundColor,
      buttonBackgroundColor: other.buttonBackgroundColor ?? buttonBackgroundColor,
      buttonHoverBackgroundColor: other.buttonHoverBackgroundColor ?? buttonHoverBackgroundColor,
      buttonForegroundColor: other.buttonForegroundColor ?? buttonForegroundColor,
      buttonTextStyle: other.buttonTextStyle ?? buttonTextStyle,
      descriptionPadding: other.descriptionPadding ?? descriptionPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SileoStyles &&
        other.titleStyle == titleStyle &&
        other.descriptionStyle == descriptionStyle &&
        other.badgeBackgroundColor == badgeBackgroundColor &&
        other.badgeForegroundColor == badgeForegroundColor &&
        other.buttonBackgroundColor == buttonBackgroundColor &&
        other.buttonHoverBackgroundColor == buttonHoverBackgroundColor &&
        other.buttonForegroundColor == buttonForegroundColor &&
        other.buttonTextStyle == buttonTextStyle &&
        other.descriptionPadding == descriptionPadding;
  }

  @override
  int get hashCode => Object.hash(
    titleStyle,
    descriptionStyle,
    badgeBackgroundColor,
    badgeForegroundColor,
    buttonBackgroundColor,
    buttonHoverBackgroundColor,
    buttonForegroundColor,
    buttonTextStyle,
    descriptionPadding,
  );
}

/// Configuration for displaying or updating a Sileo toast notification.
@immutable
class SileoOptions {
  /// Creates a toast configuration.
  const SileoOptions({
    this.id,
    this.title,
    this.description,
    this.descriptionWidget,
    this.type,
    this.position,
    this.duration,
    this.persistent,
    this.icon,
    this.styles,
    this.fill,
    this.surfaceStyle,
    this.glassOptions,
    this.roundness,
    this.elevation,
    this.border,
    this.autopilot,
    this.button,
    this.dismissible,
  });

  /// Stable identifier for this toast.
  ///
  /// Firing another toast with the same [id] morphs the existing toast in place.
  final String? id;

  /// Heading displayed inside the pill header.
  final String? title;

  /// Plain-text body content revealed when the toast expands.
  final String? description;

  /// Custom widget rendered inside the expanded body area.
  ///
  /// When provided, takes precedence over [description].
  final Widget? descriptionWidget;

  /// Visual state controlling the default icon and accent color.
  final SileoState? type;

  /// Screen position overriding the toaster's default position.
  final SileoPosition? position;

  /// Lifetime before auto-dismissing.
  ///
  /// Defaults to [SileoDefaults.toastDuration]. Setting [persistent] to `true`
  /// or passing [Duration.zero] keeps the toast visible until dismissed.
  final Duration? duration;

  /// Whether the toast should remain visible indefinitely without auto-dismissing.
  final bool? persistent;

  /// Custom icon widget replacing the default state icon in the badge.
  final Widget? icon;

  /// Style overrides for title, description, badge, and action button.
  final SileoStyles? styles;

  /// Background fill color of the gooey pill and card silhouette.
  final Color? fill;

  /// Surface rendering mode overriding the toaster default (`solid` or `liquidGlass`).
  final SileoSurfaceStyle? surfaceStyle;

  /// Fine-grained material settings used when [surfaceStyle] is
  /// [SileoSurfaceStyle.liquidGlass].
  final SileoGlassOptions? glassOptions;

  /// Corner radius and concave fillet roundness in logical pixels.
  final double? roundness;

  /// Soft drop shadow elevation behind the silhouette.
  final double? elevation;

  /// Optional hairline stroke drawn around the gooey silhouette.
  final BorderSide? border;

  /// Automatic expand and collapse behavior.
  final SileoAutopilot? autopilot;

  /// Optional action pill button displayed at the bottom of the expanded body.
  final SileoButton? button;

  /// Whether the user can dismiss this toast via vertical swipe.
  final bool? dismissible;

  /// Whether this configuration contains body content or an action button.
  bool get hasBody =>
      (description != null && description!.isNotEmpty) ||
      descriptionWidget != null ||
      button != null;

  /// Returns a copy with selectively replaced fields.
  SileoOptions copyWith({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
    SileoState? type,
    SileoPosition? position,
    Duration? duration,
    bool? persistent,
    Widget? icon,
    SileoStyles? styles,
    Color? fill,
    SileoSurfaceStyle? surfaceStyle,
    SileoGlassOptions? glassOptions,
    double? roundness,
    double? elevation,
    BorderSide? border,
    SileoAutopilot? autopilot,
    SileoButton? button,
    bool? dismissible,
  }) {
    return SileoOptions(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      descriptionWidget: descriptionWidget ?? this.descriptionWidget,
      type: type ?? this.type,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      persistent: persistent ?? this.persistent,
      icon: icon ?? this.icon,
      styles: styles ?? this.styles,
      fill: fill ?? this.fill,
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      glassOptions: glassOptions ?? this.glassOptions,
      roundness: roundness ?? this.roundness,
      elevation: elevation ?? this.elevation,
      border: border ?? this.border,
      autopilot: autopilot ?? this.autopilot,
      button: button ?? this.button,
      dismissible: dismissible ?? this.dismissible,
    );
  }

  /// Merges [override] on top of this defaults configuration.
  SileoOptions merge(SileoOptions? override) {
    if (override == null) return this;
    return SileoOptions(
      id: override.id ?? id,
      title: override.title ?? title,
      description: override.description ?? description,
      descriptionWidget: override.descriptionWidget ?? descriptionWidget,
      type: override.type ?? type,
      position: override.position ?? position,
      duration: override.duration ?? duration,
      persistent: override.persistent ?? persistent,
      icon: override.icon ?? icon,
      styles: styles != null ? styles!.merge(override.styles) : override.styles,
      fill: override.fill ?? fill,
      surfaceStyle: override.surfaceStyle ?? surfaceStyle,
      glassOptions: override.glassOptions ?? glassOptions,
      roundness: override.roundness ?? roundness,
      elevation: override.elevation ?? elevation,
      border: override.border ?? border,
      autopilot: override.autopilot ?? autopilot,
      button: override.button ?? button,
      dismissible: override.dismissible ?? dismissible,
    );
  }
}

/// Configuration for `Sileo.future`, driving a toast through loading to success,
/// action, or error states.
@immutable
class SileoFutureOptions<T> {
  /// Creates options for a [Future]-driven toast lifecycle.
  ///
  /// Provide either static options ([success], [error], [action]) or dynamic
  /// builders ([successBuilder], [errorBuilder], [actionBuilder]).
  const SileoFutureOptions({
    required this.loading,
    this.success,
    this.successBuilder,
    this.error,
    this.errorBuilder,
    this.action,
    this.actionBuilder,
    this.position,
    this.id,
  }) : assert(
         success != null || successBuilder != null || action != null || actionBuilder != null,
         'Provide success, successBuilder, action, or actionBuilder.',
       ),
       assert(error != null || errorBuilder != null, 'Provide error or errorBuilder.');

  /// Options shown while the future is pending.
  final SileoOptions loading;

  /// Static options shown when the future resolves without an action override.
  final SileoOptions? success;

  /// Dynamic builder creating success options from the resolved value.
  final SileoOptions Function(T data)? successBuilder;

  /// Static options shown when the future rejects with an error.
  final SileoOptions? error;

  /// Dynamic builder creating error options from the thrown error.
  final SileoOptions Function(Object error)? errorBuilder;

  /// Static action-state options that replace the success state when provided.
  final SileoOptions? action;

  /// Dynamic action-state builder replacing the success state when provided.
  final SileoOptions Function(T data)? actionBuilder;

  /// Optional screen position applied across all phases of the future lifecycle.
  final SileoPosition? position;

  /// Optional stable ID applied across all phases of the future lifecycle.
  final String? id;

  /// Resolves the completion options for a successful [data] result.
  (SileoState, SileoOptions) resolveSuccess(T data) {
    if (actionBuilder != null) {
      return (SileoState.action, actionBuilder!(data));
    }
    if (action != null) {
      return (SileoState.action, action!);
    }
    if (successBuilder != null) {
      return (SileoState.success, successBuilder!(data));
    }
    return (SileoState.success, success!);
  }

  /// Resolves the failure options for a rejected [err].
  SileoOptions resolveError(Object err) {
    if (errorBuilder != null) {
      return errorBuilder!(err);
    }
    return error!;
  }
}

/// Immutable snapshot of a live toast item managed by `SileoController`.
@immutable
class SileoToastItem {
  /// Creates an internal toast snapshot.
  const SileoToastItem({
    required this.id,
    required this.instanceId,
    required this.state,
    required this.position,
    required this.options,
    this.exiting = false,
    this.autoExpandDelay,
    this.autoCollapseDelay,
  });

  /// Logical toast identifier used for replacement and dismissal.
  final String id;

  /// Unique token incremented on every update to drive morph transitions.
  final String instanceId;

  /// Resolved toast state.
  final SileoState state;

  /// Resolved viewport anchor position.
  final SileoPosition position;

  /// Merged toast options.
  final SileoOptions options;

  /// Whether this toast is currently animating out before removal.
  final bool exiting;

  /// Resolved delay before auto-expanding, or `null` if disabled.
  final Duration? autoExpandDelay;

  /// Resolved delay before auto-collapsing, or `null` if disabled.
  final Duration? autoCollapseDelay;

  /// Composite key unique to this specific toast revision.
  String get timerKey => '$id:$instanceId';

  /// Effective auto-dismiss duration, or `null` when persistent.
  Duration? get effectiveDuration {
    if (options.persistent == true) return null;
    final dur = options.duration ?? SileoDefaults.toastDuration;
    if (dur <= Duration.zero) return null;
    return dur;
  }

  /// Returns a copy with updated [exiting] status.
  SileoToastItem copyWith({bool? exiting}) {
    return SileoToastItem(
      id: id,
      instanceId: instanceId,
      state: state,
      position: position,
      options: options,
      exiting: exiting ?? this.exiting,
      autoExpandDelay: autoExpandDelay,
      autoCollapseDelay: autoCollapseDelay,
    );
  }
}
