import 'package:flutter/widgets.dart';

/// Core layout, timing, physics, and visual defaults for Sileo toasts.
abstract final class SileoDefaults {
  /// Default ID used when morph-in-place mode replaces the active toast.
  static const String defaultToastId = 'sileo-default';

  /* --------------------------------- Layout -------------------------------- */

  /// Default collapsed pill height in logical pixels.
  static const double pillHeight = 40.0;

  /// Default maximum expanded toast width in logical pixels.
  static const double maxWidth = 350.0;

  /// Default corner roundness and concave fillet radius in logical pixels.
  static const double roundness = 16.0;

  /// Extra horizontal breathing room added to the measured pill width.
  static const double pillExtraPadding = 10.0;

  /// Horizontal padding inside the toast header pill.
  static const double headerPadding = 8.0;

  /// Minimum expanded height expressed as a multiple of [pillHeight].
  static const double minExpandRatio = 2.25;

  /// Spacing between stacked toasts in the same viewport.
  static const double viewportGap = 12.0;

  /// Default outer padding from viewport edges.
  static const double viewportPadding = 12.0;

  /// Default elevation shadow blur for subtle separation on matching surfaces.
  static const double elevation = 6.0;

  /// Maximum vertical drag displacement applied while swiping to dismiss.
  static const double swipeMaxOffset = 20.0;

  /// Vertical drag distance threshold required to dismiss a toast.
  static const double swipeDismissDistance = 30.0;

  /// Vertical fling velocity threshold (px/s) required to dismiss a toast.
  static const double swipeDismissVelocity = 350.0;

  /* --------------------------------- Timing -------------------------------- */

  /// Primary spring duration for morphing and expansion.
  static const Duration animationDuration = Duration(milliseconds: 600);

  /// Duration for toast entry and exit transitions.
  static const Duration entryExitDuration = Duration(milliseconds: 400);

  /// Default lifetime before a toast automatically dismisses.
  static const Duration toastDuration = Duration(milliseconds: 6000);

  /// Duration kept in the exiting state before removing from the store.
  static const Duration exitDuration = Duration(milliseconds: 600);

  /// Default delay before an expandable toast automatically opens.
  static const Duration autoExpandDelay = Duration(milliseconds: 150);

  /// Default offset before dismissal when an expanded toast collapses.
  static const Duration autoCollapseBeforeEnd = Duration(milliseconds: 2000);

  /// Delay allowing an open toast to begin collapsing before swapping content.
  static const Duration swapCollapseDelay = Duration(milliseconds: 200);

  /// Duration for the outgoing header blur-out animation.
  static const Duration headerExitDuration = Duration(milliseconds: 420);

  /// Delay before body content fades in during expansion.
  static const Duration contentOpenDelay = Duration(milliseconds: 160);

  /// Duration of body content fade-in during expansion.
  static const Duration contentOpenDuration = Duration(milliseconds: 340);

  /// Duration of body content fade-out during collapse.
  static const Duration contentCloseDuration = Duration(milliseconds: 55);

  /* -------------------------------- Physics -------------------------------- */

  /// Expressive bouncy spring used when opening, expanding, and morphing pills.
  static final SpringDescription openSpring = SpringDescription.withDurationAndBounce(
    duration: animationDuration,
    bounce: 0.25,
  );

  /// Critically damped spring used when collapsing the body without overshoot.
  static final SpringDescription closeSpring = SpringDescription.withDurationAndBounce(
    duration: animationDuration,
  );

  /// Snappy spring used for entry, exit, and layout slot animations.
  static final SpringDescription entrySpring = SpringDescription.withDurationAndBounce(
    duration: entryExitDuration,
    bounce: 0.25,
  );

  /// Spring used when a cancelled swipe snaps back to rest.
  static final SpringDescription dragReturnSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 320),
    bounce: 0.2,
  );

  /* --------------------------------- Colors -------------------------------- */

  /// Surface color used when the surrounding app is in light mode.
  static const Color lightThemeFill = Color(0xFF1A1A1A);

  /// Surface color used when the surrounding app is in dark mode.
  static const Color darkThemeFill = Color(0xFFF2F2F2);

  /// Success accent matching Sileo's `oklch(0.723 0.219 142.136)`.
  static const Color successColor = Color(0xFF22C55E);

  /// Loading accent matching Sileo's `oklch(0.556 0 0)`.
  static const Color loadingColor = Color(0xFF737373);

  /// Error accent matching Sileo's `oklch(0.637 0.237 25.331)`.
  static const Color errorColor = Color(0xFFFB2C36);

  /// Warning accent matching Sileo's `oklch(0.795 0.184 86.047)`.
  static const Color warningColor = Color(0xFFF0B100);

  /// Info accent matching Sileo's `oklch(0.685 0.169 237.323)`.
  static const Color infoColor = Color(0xFF00A6F4);

  /// Action accent matching Sileo's `oklch(0.623 0.214 259.815)`.
  static const Color actionColor = Color(0xFF2B7FFF);
}
