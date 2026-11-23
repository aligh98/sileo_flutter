import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sileo_flutter/sileo_flutter.dart';

void main() {
  group('SileoToaster widget tests', () {
    late SileoController controller;

    setUp(() {
      controller = SileoController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget wrapApp({
      required Widget home,
      SileoPosition position = SileoPosition.topRight,
      SileoStackBehavior stackBehavior = SileoStackBehavior.morph,
      SileoSurfaceStyle surfaceStyle = SileoSurfaceStyle.solid,
      TextDirection textDirection = TextDirection.ltr,
      bool disableAnimations = false,
      Size size = const Size(800, 600),
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: disableAnimations),
        child: MaterialApp(
          builder: (context, child) => Directionality(
            textDirection: textDirection,
            child: SileoToaster(
              controller: controller,
              position: position,
              stackBehavior: stackBehavior,
              surfaceStyle: surfaceStyle,
              child: child!,
            ),
          ),
          home: home,
        ),
      );
    }

    testWidgets('shows, auto-expands, invokes action button, and auto-dismisses cleanly', (
      tester,
    ) async {
      var buttonClicks = 0;

      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      controller.action(
        title: 'File Uploaded',
        description: 'Ready to share with your team.',
        duration: const Duration(milliseconds: 4000),
        button: SileoButton(title: 'Share Now', onPressed: () => buttonClicks++),
      );

      await tester.pump();
      expect(find.text('File Uploaded'), findsOneWidget);

      // Verify right-edge alignment for topRight viewport (800 - 12 offset = 788).
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopRight(find.byType(SileoToast)).dx, closeTo(788, 1.0));

      // Wait for autopilot expansion spring and content fade-in (before collapse at 2000ms).
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Ready to share with your team.'), findsOneWidget);
      expect(find.text('Share Now'), findsOneWidget);

      await tester.tap(find.text('Share Now'));
      await tester.pump();
      expect(buttonClicks, 1);

      // Advance past duration + exit animation and ensure toast is fully removed.
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(SileoDefaults.exitDuration + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('File Uploaded'), findsNothing);
    });

    testWidgets('passes taps through empty transparent area beside collapsed pill', (tester) async {
      var backgroundTaps = 0;

      await tester.pumpWidget(
        wrapApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 260),
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => backgroundTaps++,
                    child: const Text('Under'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Collapsed pill at top-right only occupies the rightmost ~110px.
      controller.success(title: 'Saved', persistent: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap button located to the left of the collapsed pill (still within the 350px toast slot).
      await tester.tap(find.text('Under'));
      await tester.pump();
      expect(backgroundTaps, 1);

      controller.clear();
      await tester.pump();
    });

    testWidgets('supports tap-to-expand and vertical swipe-to-dismiss', (tester) async {
      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      controller.info(
        title: 'Update',
        description: 'Tap to inspect release notes.',
        persistent: true,
        autopilot: const SileoAutopilot.disabled(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap pill to expand manually.
      await tester.tap(find.text('Update'));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Tap to inspect release notes.'), findsOneWidget);

      // Vertical swipe past threshold dismisses the toast.
      await tester.drag(find.text('Update'), const Offset(0, -60));
      await tester.pump();
      expect(controller.toasts.single.exiting, isTrue);

      await tester.pump(SileoDefaults.exitDuration + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Update'), findsNothing);
    });

    testWidgets('hovering pauses auto-dismiss and leaving resumes it', (tester) async {
      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      controller.success(title: 'Hover Me', duration: const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.text('Hover Me')));
      await tester.pump();

      // Advance well past original 1200ms lifetime while hovered -> still alive.
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.text('Hover Me'), findsOneWidget);

      // Leave hover -> timer resumes and dismisses toast.
      await gesture.moveTo(const Offset(10, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(SileoDefaults.exitDuration + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Hover Me'), findsNothing);
    });

    testWidgets('morphs loading -> success via controller.future()', (tester) async {
      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      final completer = Completer<String>();
      unawaited(
        controller.future<String>(
          completer.future,
          SileoFutureOptions<String>(
            loading: const SileoOptions(title: 'Booking Flight'),
            successBuilder: (code) => SileoOptions(
              title: 'Booking Confirmed',
              description: 'PNR $code',
              duration: const Duration(milliseconds: 2000),
            ),
            error: const SileoOptions(title: 'Booking Failed'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Booking Flight'), findsOneWidget);

      completer.complete('EC2QW4');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.text('PNR EC2QW4'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pump(SileoDefaults.exitDuration + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Booking Confirmed'), findsNothing);
    });

    testWidgets('morphs expanded toast cleanly via collapse-before-swap', (tester) async {
      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      controller.success(
        title: 'First Toast',
        description: 'First details',
        persistent: true,
        autopilot: const SileoAutopilot.custom(
          expand: Duration(milliseconds: 50),
          collapse: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('First Toast'), findsOneWidget);

      // Fire replacement while expanded.
      controller.error(
        title: 'Second Toast',
        description: 'Second details',
        persistent: true,
        autopilot: const SileoAutopilot.custom(
          expand: Duration(milliseconds: 50),
          collapse: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.pump(SileoDefaults.swapCollapseDelay + const Duration(milliseconds: 500));

      expect(find.text('Second Toast'), findsOneWidget);
      expect(find.text('Second details'), findsOneWidget);

      controller.clear();
      await tester.pump();
    });

    testWidgets('renders cleanly across all 6 positions, RTL, narrow screen, and reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapApp(
          textDirection: TextDirection.rtl,
          disableAnimations: true,
          size: const Size(300, 640),
          stackBehavior: SileoStackBehavior.stack,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      for (final pos in SileoPosition.values) {
        controller.success(
          title: 'اعلان ${pos.name}',
          description: 'توضیحات تست برای چیدمان راست‌به‌چپ در صفحه باریک.',
          position: pos,
          persistent: true,
          autopilot: const SileoAutopilot.custom(expand: Duration.zero, collapse: Duration.zero),
        );
      }

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      for (final pos in SileoPosition.values) {
        expect(find.text('اعلان ${pos.name}'), findsOneWidget);
      }

      controller.clear();
      await tester.pump();
    });

    testWidgets('renders and interacts cleanly in liquidGlass mode', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrapApp(
          surfaceStyle: SileoSurfaceStyle.liquidGlass,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      controller.action(
        title: 'Glass Notification',
        description: 'Refracts the live backdrop behind the toast.',
        persistent: true,
        autopilot: const SileoAutopilot.custom(
          expand: Duration(milliseconds: 50),
          collapse: Duration.zero,
        ),
        button: SileoButton(title: 'Inspect', onPressed: () => tapped = true),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 650));

      expect(tester.takeException(), isNull);
      expect(find.text('Glass Notification'), findsOneWidget);
      expect(find.text('Refracts the live backdrop behind the toast.'), findsOneWidget);

      await tester.tap(find.text('Inspect'));
      await tester.pump();
      expect(tapped, isTrue);

      controller.clear();
      await tester.pump();
    });

    testWidgets('disposing immediately after firing a toast never throws', (tester) async {
      await tester.pumpWidget(wrapApp(home: const Scaffold(body: SizedBox.expand())));

      controller.success(title: 'Transient Toast', description: 'Removed on the very next frame.');
      await tester.pump();

      // Unmount SileoToaster immediately while post-frame layout callbacks are queued.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
