import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sileo_glass/sileo_glass.dart';

void main() {
  group('SileoController', () {
    late SileoController controller;

    setUp(() {
      controller = SileoController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('morphs default toast in place when no id is provided', () {
      final id1 = controller.success(title: 'First');
      final firstInstance = controller.toasts.single.instanceId;

      final id2 = controller.error(title: 'Second');
      expect(id1, SileoDefaults.defaultToastId);
      expect(id2, SileoDefaults.defaultToastId);
      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.single.state, SileoState.error);
      expect(controller.toasts.single.options.title, 'Second');
      expect(controller.toasts.single.instanceId, isNot(firstInstance));
    });

    test('stacks toasts when explicit ids or stackBehavior.stack are used', () {
      controller.configure(stackBehavior: SileoStackBehavior.stack);

      final id1 = controller.success(title: 'One');
      final id2 = controller.info(title: 'Two');

      expect(id1, isNot(id2));
      expect(controller.toasts, hasLength(2));
      expect(controller.toasts.map((t) => t.options.title), <String?>['One', 'Two']);
    });

    test('merges default options and styles into every toast', () {
      controller.configure(
        position: SileoPosition.bottomCenter,
        options: const SileoOptions(
          fill: Color(0xFF111111),
          roundness: 12,
          styles: SileoStyles(
            titleStyle: TextStyle(color: Color(0xFFFFFFFF)),
            badgeBackgroundColor: Color(0x33FFFFFF),
          ),
        ),
      );

      controller.warning(
        title: 'Heads Up',
        styles: const SileoStyles(descriptionStyle: TextStyle(color: Color(0xAAFFFFFF))),
      );

      final item = controller.toasts.single;
      expect(item.position, SileoPosition.bottomCenter);
      expect(item.options.fill, const Color(0xFF111111));
      expect(item.options.roundness, 12);
      expect(item.options.styles?.titleStyle?.color, const Color(0xFFFFFFFF));
      expect(item.options.styles?.badgeBackgroundColor, const Color(0x33FFFFFF));
      expect(item.options.styles?.descriptionStyle?.color, const Color(0xAAFFFFFF));
    });

    test('future() transitions loading -> success and returns resolved value', () async {
      final completer = Completer<String>();
      final tracked = controller.future<String>(
        completer.future,
        SileoFutureOptions<String>(
          loading: const SileoOptions(title: 'Saving...'),
          successBuilder: (value) => SileoOptions(title: 'Saved $value', description: 'Done'),
          error: const SileoOptions(title: 'Failed'),
        ),
      );

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.single.state, SileoState.loading);
      expect(controller.toasts.single.effectiveDuration, isNull);

      completer.complete('v42');
      final result = await tracked;
      await Future<void>.delayed(Duration.zero);

      expect(result, 'v42');
      expect(controller.toasts.single.state, SileoState.success);
      expect(controller.toasts.single.options.title, 'Saved v42');
      expect(controller.toasts.single.options.description, 'Done');
    });

    test('future() prefers action state over success when action is provided', () async {
      final tracked = controller.future<int>(
        Future<int>.value(7),
        SileoFutureOptions<int>(
          loading: const SileoOptions(title: 'Uploading'),
          success: const SileoOptions(title: 'Unused'),
          actionBuilder: (count) => SileoOptions(
            title: 'Uploaded $count files',
            button: SileoButton(title: 'Open', onPressed: () {}),
          ),
          error: const SileoOptions(title: 'Failed'),
        ),
      );

      expect(await tracked, 7);
      await Future<void>.delayed(Duration.zero);

      expect(controller.toasts.single.state, SileoState.action);
      expect(controller.toasts.single.options.title, 'Uploaded 7 files');
    });

    test('future() transitions loading -> error on rejection', () async {
      final completer = Completer<void>();
      final tracked = controller.future<void>(
        completer.future,
        SileoFutureOptions<void>(
          loading: const SileoOptions(title: 'Connecting'),
          success: const SileoOptions(title: 'Connected'),
          errorBuilder: (err) =>
              SileoOptions(title: 'Connection Error', description: err.toString()),
        ),
      );

      completer.completeError(StateError('offline'));
      await expectLater(tracked, throwsA(isA<StateError>()));
      await Future<void>.delayed(Duration.zero);

      expect(controller.toasts.single.state, SileoState.error);
      expect(controller.toasts.single.options.title, 'Connection Error');
      expect(controller.toasts.single.options.description, contains('offline'));
    });

    test('dismiss() marks exiting then removes after exitDuration', () async {
      final id = controller.success(title: 'Bye');
      controller.dismiss(id);

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.single.exiting, isTrue);

      await Future<void>.delayed(SileoDefaults.exitDuration + const Duration(milliseconds: 50));
      expect(controller.toasts, isEmpty);
    });

    test('clear(position) removes only toasts in that viewport', () {
      controller.success(id: 'a', title: 'Top', position: SileoPosition.topLeft);
      controller.info(id: 'b', title: 'Bottom', position: SileoPosition.bottomRight);

      controller.clear(SileoPosition.topLeft);

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.single.id, 'b');
    });

    test('resolves autopilot delays and clamps against toast duration', () {
      controller.success(
        id: 'disabled',
        title: 'Manual',
        autopilot: const SileoAutopilot.disabled(),
      );
      expect(controller.toasts.last.autoExpandDelay, isNull);
      expect(controller.toasts.last.autoCollapseDelay, isNull);

      controller.success(
        id: 'clamped',
        title: 'Short',
        duration: const Duration(milliseconds: 1000),
        autopilot: const SileoAutopilot.custom(
          expand: Duration(milliseconds: 200),
          collapse: Duration(milliseconds: 5000),
        ),
      );
      expect(controller.toasts.last.autoExpandDelay, const Duration(milliseconds: 200));
      expect(controller.toasts.last.autoCollapseDelay, const Duration(milliseconds: 1000));

      controller.success(
        id: 'pinned',
        title: 'Pinned Open',
        persistent: true,
        autopilot: const SileoAutopilot.custom(collapse: Duration.zero),
      );
      expect(controller.toasts.last.autoExpandDelay, SileoDefaults.autoExpandDelay);
      expect(controller.toasts.last.autoCollapseDelay, isNull);
    });
  });
}
