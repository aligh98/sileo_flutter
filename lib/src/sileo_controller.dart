import 'dart:async';

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'types.dart';

/// Reactive controller that owns active Sileo toasts and orchestrates their
/// creation, updates, morphing, and dismissal.
///
/// Use the global [Sileo] facade for convenience, or instantiate a dedicated
/// [SileoController] and pass it to `SileoToaster(controller: ...)` for
/// isolated scopes and deterministic testing.
class SileoController extends ChangeNotifier {
  /// Creates a toast controller with optional default [position], default
  /// [options], and [stackBehavior].
  SileoController({
    SileoPosition position = SileoPosition.topRight,
    SileoOptions? options,
    SileoStackBehavior stackBehavior = SileoStackBehavior.morph,
  }) : _position = position,
       _defaultOptions = options,
       _stackBehavior = stackBehavior;

  List<SileoToastItem> _toasts = const <SileoToastItem>[];
  SileoPosition _position;
  SileoOptions? _defaultOptions;
  SileoStackBehavior _stackBehavior;
  int _instanceCounter = 0;
  int _idCounter = 0;
  final Map<String, Timer> _exitTimers = <String, Timer>{};
  bool _disposed = false;

  /// Unmodifiable list of currently active and exiting toasts.
  List<SileoToastItem> get toasts => List<SileoToastItem>.unmodifiable(_toasts);

  /// Default viewport position for toasts that do not specify one.
  SileoPosition get position => _position;

  /// Global default options merged into every toast shown through this controller.
  SileoOptions? get defaultOptions => _defaultOptions;

  /// Default stacking behavior when a toast is shown without an explicit ID.
  SileoStackBehavior get stackBehavior => _stackBehavior;

  /// Updates controller-level defaults without discarding live toasts.
  void configure({
    SileoPosition? position,
    SileoOptions? options,
    SileoStackBehavior? stackBehavior,
    bool clearDefaultOptions = false,
  }) {
    if (position != null) _position = position;
    if (clearDefaultOptions) {
      _defaultOptions = null;
    } else if (options != null) {
      _defaultOptions = options;
    }
    if (stackBehavior != null) _stackBehavior = stackBehavior;
  }

  /// Displays a toast using a prebuilt [SileoOptions] object and returns its ID.
  String showOptions(SileoOptions options, {SileoState? state}) {
    return _createToast(options, overrideState: state);
  }

  /// Displays a generic toast notification and returns its ID.
  String show({
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        type: type,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
    );
  }

  /// Displays a green success toast and returns its ID.
  String success({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
      overrideState: SileoState.success,
    );
  }

  /// Displays a red error toast and returns its ID.
  String error({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
      overrideState: SileoState.error,
    );
  }

  /// Displays a warning toast and returns its ID.
  String warning({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
      overrideState: SileoState.warning,
    );
  }

  /// Displays an informational toast and returns its ID.
  String info({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
      overrideState: SileoState.info,
    );
  }

  /// Displays an action toast and returns its ID.
  String action({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        description: description,
        descriptionWidget: descriptionWidget,
        position: position,
        duration: duration,
        persistent: persistent,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        autopilot: autopilot,
        button: button,
        dismissible: dismissible,
      ),
      overrideState: SileoState.action,
    );
  }

  /// Displays a persistent loading toast and returns its ID.
  String loading({
    String? id,
    String? title,
    SileoPosition? position,
    Widget? icon,
    SileoStyles? styles,
    Color? fill,
    SileoSurfaceStyle? surfaceStyle,
    SileoGlassOptions? glassOptions,
    double? roundness,
    double? elevation,
    BorderSide? border,
    bool? dismissible,
  }) {
    return _createToast(
      SileoOptions(
        id: id,
        title: title,
        position: position,
        persistent: true,
        icon: icon,
        styles: styles,
        fill: fill,
        surfaceStyle: surfaceStyle,
        glassOptions: glassOptions,
        roundness: roundness,
        elevation: elevation,
        border: border,
        dismissible: dismissible,
      ),
      overrideState: SileoState.loading,
    );
  }

  /// Updates an existing toast identified by [id] in place.
  ///
  /// Does nothing if no toast with [id] exists.
  void update(String id, SileoOptions options, {SileoState? state}) {
    final index = _toasts.indexWhere((t) => t.id == id);
    if (index == -1) return;

    _cancelExitTimer(id);
    final existing = _toasts[index];
    final merged = _mergeWithDefaults(options);
    final item = _buildItem(
      merged: merged,
      id: id,
      overrideState: state,
      fallbackPosition: existing.position,
    );

    final updated = List<SileoToastItem>.of(_toasts);
    updated[index] = item;
    _setToasts(updated);
  }

  /// Tracks an asynchronous [future], showing a loading pill and morphing into
  /// a success, action, or error toast when [future] settles.
  ///
  /// Returns the original [future] so callers can still await its result.
  Future<T> future<T>(Future<T> future, SileoFutureOptions<T> options) {
    final id = _createToast(
      options.loading.copyWith(
        id: options.id ?? options.loading.id,
        position: options.position ?? options.loading.position,
        persistent: true,
      ),
      overrideState: SileoState.loading,
    );

    unawaited(
      future.then<void>(
        (T data) {
          if (_disposed) return;
          final (resolvedState, resolvedOptions) = options.resolveSuccess(data);
          update(
            id,
            resolvedOptions.copyWith(
              id: id,
              position: resolvedOptions.position ?? options.position,
            ),
            state: resolvedState,
          );
        },
        onError: (Object err, StackTrace _) {
          if (_disposed) return;
          final resolvedOptions = options.resolveError(err);
          update(
            id,
            resolvedOptions.copyWith(
              id: id,
              position: resolvedOptions.position ?? options.position,
            ),
            state: SileoState.error,
          );
        },
      ),
    );

    return future;
  }

  /// Triggers the exit animation for the toast identified by [id], then removes
  /// it after [SileoDefaults.exitDuration].
  void dismiss(String id) {
    final index = _toasts.indexWhere((t) => t.id == id);
    if (index == -1 || _toasts[index].exiting) return;

    final updated = List<SileoToastItem>.of(_toasts);
    updated[index] = updated[index].copyWith(exiting: true);
    _setToasts(updated);

    _cancelExitTimer(id);
    _exitTimers[id] = Timer(SileoDefaults.exitDuration, () {
      _exitTimers.remove(id);
      if (_disposed) return;
      _setToasts(_toasts.where((t) => t.id != id).toList(growable: false));
    });
  }

  /// Removes all toasts immediately, or only those anchored at [position].
  void clear([SileoPosition? position]) {
    if (position == null) {
      for (final timer in _exitTimers.values) {
        timer.cancel();
      }
      _exitTimers.clear();
      if (_toasts.isEmpty) return;
      _setToasts(const <SileoToastItem>[]);
      return;
    }

    final remaining = <SileoToastItem>[];
    for (final toast in _toasts) {
      if (toast.position == position) {
        _cancelExitTimer(toast.id);
      } else {
        remaining.add(toast);
      }
    }
    _setToasts(remaining);
  }

  String _createToast(SileoOptions options, {SileoState? overrideState}) {
    final merged = _mergeWithDefaults(options);
    final id =
        merged.id ??
        (_stackBehavior == SileoStackBehavior.stack
            ? 'sileo-${++_idCounter}'
            : SileoDefaults.defaultToastId);

    _cancelExitTimer(id);

    final liveIndex = _toasts.indexWhere((t) => t.id == id && !t.exiting);
    final fallbackPosition = liveIndex != -1 ? _toasts[liveIndex].position : null;
    final item = _buildItem(
      merged: merged,
      id: id,
      overrideState: overrideState,
      fallbackPosition: fallbackPosition,
    );

    if (liveIndex != -1) {
      final updated = List<SileoToastItem>.of(_toasts);
      updated[liveIndex] = item;
      _setToasts(updated);
    } else {
      final updated = <SileoToastItem>[
        for (final toast in _toasts)
          if (toast.id != id) toast,
        item,
      ];
      _setToasts(updated);
    }

    return id;
  }

  SileoOptions _mergeWithDefaults(SileoOptions options) {
    final defaults = _defaultOptions;
    return defaults == null ? options : defaults.merge(options);
  }

  SileoToastItem _buildItem({
    required SileoOptions merged,
    required String id,
    SileoState? overrideState,
    SileoPosition? fallbackPosition,
  }) {
    final resolvedState = overrideState ?? merged.type ?? SileoState.success;
    final resolvedPosition = merged.position ?? fallbackPosition ?? _position;
    final isPersistent = merged.persistent == true || merged.duration == Duration.zero;
    final effectiveDuration = isPersistent
        ? null
        : (merged.duration ?? SileoDefaults.toastDuration);

    final (expandDelay, collapseDelay) = _resolveAutopilot(
      autopilot: merged.autopilot,
      effectiveDuration: effectiveDuration,
    );

    return SileoToastItem(
      id: id,
      instanceId: 'inst-${++_instanceCounter}',
      state: resolvedState,
      position: resolvedPosition,
      options: merged,
      autoExpandDelay: expandDelay,
      autoCollapseDelay: collapseDelay,
    );
  }

  (Duration?, Duration?) _resolveAutopilot({
    required SileoAutopilot? autopilot,
    required Duration? effectiveDuration,
  }) {
    final cfg = autopilot ?? const SileoAutopilot.enabled();
    if (!cfg.enabled) return (null, null);

    // Match Sileo web: persistent toasts with explicit autopilot config still
    // support auto-expand (e.g. standing card with collapse: Duration.zero).
    if (effectiveDuration == null) {
      if (autopilot == null) return (null, null);
      final expand = cfg.expand ?? SileoDefaults.autoExpandDelay;
      final collapse = cfg.collapse;
      return (
        expand < Duration.zero ? Duration.zero : expand,
        collapse != null && collapse > Duration.zero ? collapse : null,
      );
    }

    if (effectiveDuration <= Duration.zero) return (null, null);

    Duration clampDuration(Duration value) {
      if (value < Duration.zero) return Duration.zero;
      if (value > effectiveDuration) return effectiveDuration;
      return value;
    }

    final defaultCollapse = effectiveDuration > SileoDefaults.autoCollapseBeforeEnd
        ? effectiveDuration - SileoDefaults.autoCollapseBeforeEnd
        : Duration.zero;

    final expand = clampDuration(cfg.expand ?? SileoDefaults.autoExpandDelay);
    final rawCollapse = cfg.collapse ?? defaultCollapse;
    final collapse = rawCollapse <= Duration.zero ? null : clampDuration(rawCollapse);

    return (expand, collapse);
  }

  void _cancelExitTimer(String id) {
    _exitTimers.remove(id)?.cancel();
  }

  void _setToasts(List<SileoToastItem> next) {
    _toasts = next;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _exitTimers.values) {
      timer.cancel();
    }
    _exitTimers.clear();
    super.dispose();
  }
}

/// Global entry point for firing, updating, and dismissing Sileo toasts.
///
/// Mount a `SileoToaster` near the root of your application to render toasts
/// triggered through [Sileo].
abstract final class Sileo {
  /// Default shared [SileoController] used when no custom controller is provided.
  static final SileoController instance = SileoController();

  /// Displays a toast using a prebuilt [SileoOptions] configuration.
  static String showOptions(SileoOptions options, {SileoState? state}) =>
      instance.showOptions(options, state: state);

  /// Displays a generic toast notification and returns its ID.
  static String show({
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
  }) => instance.show(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    type: type,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays a green success toast and returns its ID.
  static String success({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
  }) => instance.success(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays a red error toast and returns its ID.
  static String error({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
  }) => instance.error(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays a warning toast and returns its ID.
  static String warning({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
  }) => instance.warning(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays an informational toast and returns its ID.
  static String info({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
  }) => instance.info(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays an action toast and returns its ID.
  static String action({
    String? id,
    String? title,
    String? description,
    Widget? descriptionWidget,
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
  }) => instance.action(
    id: id,
    title: title,
    description: description,
    descriptionWidget: descriptionWidget,
    position: position,
    duration: duration,
    persistent: persistent,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    autopilot: autopilot,
    button: button,
    dismissible: dismissible,
  );

  /// Displays a persistent loading toast and returns its ID.
  static String loading({
    String? id,
    String? title,
    SileoPosition? position,
    Widget? icon,
    SileoStyles? styles,
    Color? fill,
    SileoSurfaceStyle? surfaceStyle,
    SileoGlassOptions? glassOptions,
    double? roundness,
    double? elevation,
    BorderSide? border,
    bool? dismissible,
  }) => instance.loading(
    id: id,
    title: title,
    position: position,
    icon: icon,
    styles: styles,
    fill: fill,
    surfaceStyle: surfaceStyle,
    glassOptions: glassOptions,
    roundness: roundness,
    elevation: elevation,
    border: border,
    dismissible: dismissible,
  );

  /// Updates an existing toast identified by [id] in place.
  static void update(String id, SileoOptions options, {SileoState? state}) =>
      instance.update(id, options, state: state);

  /// Tracks [future] through loading and into success, action, or error states.
  static Future<T> future<T>(Future<T> future, SileoFutureOptions<T> options) =>
      instance.future<T>(future, options);

  /// Dismisses the toast identified by [id] with an exit animation.
  static void dismiss(String id) => instance.dismiss(id);

  /// Clears all toasts immediately, or only those anchored at [position].
  static void clear([SileoPosition? position]) => instance.clear(position);
}
