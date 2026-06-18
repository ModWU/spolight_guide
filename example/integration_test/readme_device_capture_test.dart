import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:spotlight_guide_example/src/spotlight_guide_example_app.dart';

int _nextPointer = 1;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('capture readme gifs on a real simulator', (
    WidgetTester tester,
  ) async {
    await _captureBasicGuide(tester, binding);
    await _capturePointerHint(tester, binding);
    await _captureSameStepHints(tester, binding);
    await _captureGroupedAndCustomAnchors(tester, binding);
    await _captureTargetDecoration(tester, binding);
    await _captureDynamicSteps(tester, binding);
    await _captureSameStepScroll(tester, binding);
    await _captureLazyTarget(tester, binding);
    await _captureBarrierDismiss(tester, binding);
    await _captureControllerApi(tester, binding);
    await _captureSideAnchors(tester, binding);
  });
}

Future<void> _captureBasicGuide(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Basic guide',
    waitFor: find.text('Basic target'),
  );
  await _capture(binding, tester, 'device_basic_01');
  await _tap(tester, find.text('Next').hitTestable());
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_basic_02');
  await _hideGuide(tester);
}

Future<void> _capturePointerHint(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Pointer hint',
    waitFor: find.byType(SpotlightGuideTapPointer),
  );
  await _capture(binding, tester, 'device_pointer_hint_01');

  for (int i = 2; i <= 6; i++) {
    await _tap(tester, find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 180));
    await _capture(binding, tester, _numberedName('device_pointer_hint', i));
  }

  await _hideGuide(tester);
}

Future<void> _captureSameStepHints(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(tester, 'Same-step hints', waitFor: find.text('Weight'));
  await _capture(binding, tester, 'device_same_step_hints_01');
  await _hideGuide(tester);
}

Future<void> _captureGroupedAndCustomAnchors(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Large group',
    waitFor: find.text('Repeated id group'),
  );
  await _capture(binding, tester, 'device_anchor_group_01');
  await _hideGuide(tester);

  await _pumpFreshApp(tester);
  await _tapScenario(tester, 'Custom anchor');
  await _pumpUntilFound(tester, find.textContaining('Pick an anchor style'));
  await _capture(binding, tester, 'device_anchor_group_02');
  await _tap(tester, find.text('Sweep'));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_anchor_group_03');
  await _tap(tester, find.text('Arrow'));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_anchor_group_04');
  await _drag(
    tester,
    find.byKey(const ValueKey<String>('custom-anchor-choice-scroll')),
    const Offset(-160, 0),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('None'));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_anchor_group_05');
  await _hideGuide(tester);
}

Future<void> _captureTargetDecoration(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Target decoration',
    waitFor: find.text('Layered target halo'),
  );
  await _capture(binding, tester, 'device_target_decoration_01');

  for (int i = 2; i <= 4; i++) {
    await _tap(tester, find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 180));
    await _capture(
      binding,
      tester,
      _numberedName('device_target_decoration', i),
    );
  }
  await _hideGuide(tester);
}

Future<void> _captureDynamicSteps(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Dynamic steps',
    waitFor: find.text('Always present'),
  );
  await _capture(binding, tester, 'device_dynamic_steps_01');
  await _tap(tester, find.text('Next').hitTestable());
  await tester.pumpAndSettle();
  await _pumpUntilFound(tester, find.text('Optional server target'));
  await _capture(binding, tester, 'device_dynamic_steps_02');
  await _hideGuide(tester);
}

Future<void> _captureSameStepScroll(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Same-step scroll',
    waitFor: find.text('Already visible.'),
  );
  await _hideGuide(tester);

  await _tap(tester, find.byTooltip('Replay guide'));
  await tester.pump();
  await _pumpUntilFound(tester, find.text('Already visible.'));
  await _capture(
    binding,
    tester,
    'device_same_step_scroll_01',
    settle: Duration.zero,
  );
  for (int i = 2; i <= 112; i++) {
    await _pumpFor(tester, const Duration(milliseconds: 16));
    await _capture(
      binding,
      tester,
      _numberedName('device_same_step_scroll', i),
      settle: Duration.zero,
    );
  }
  await _pumpUntilFound(tester, find.text('Offscreen'));
  await _capture(binding, tester, 'device_same_step_scroll_113');
  await _hideGuide(tester);
}

Future<void> _captureLazyTarget(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(tester, 'Lazy target');
  await _pumpUntilFound(
    tester,
    find.text('Lazy list target'),
    timeout: const Duration(seconds: 6),
  );
  await _capture(binding, tester, 'device_lazy_target_intro_01');
  await _hideGuide(tester);

  await _tap(tester, find.byTooltip('Replay guide'));
  await tester.pump();
  await _capture(
    binding,
    tester,
    'device_lazy_target_scroll_01',
    settle: Duration.zero,
  );
  for (int i = 2; i <= 90; i++) {
    await _pumpFor(tester, const Duration(milliseconds: 16));
    await _capture(
      binding,
      tester,
      _numberedName('device_lazy_target_scroll', i),
      settle: Duration.zero,
    );
  }
  await _pumpUntilFound(
    tester,
    find.text('Lazy list target'),
    timeout: const Duration(seconds: 6),
  );
  await _capture(binding, tester, 'device_lazy_target_scroll_91');
  await _hideGuide(tester);
}

Future<void> _captureBarrierDismiss(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Barrier dismiss',
    waitFor: find.text('Tap outside anytime'),
  );
  await _capture(binding, tester, 'device_barrier_dismiss_01');
  await _tapAt(tester, _safeOutsidePoint(tester));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_barrier_dismiss_02');

  await _tap(tester, find.text('Final'));
  await tester.pumpAndSettle();
  await _pumpUntilFound(tester, find.text('Complete-only start'));
  await _capture(binding, tester, 'device_barrier_dismiss_03');
  await _tapAt(tester, _safeOutsidePoint(tester));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_barrier_dismiss_04');
  await _tap(tester, find.text('Next').hitTestable());
  await tester.pumpAndSettle();
  await _pumpUntilFound(tester, find.text('Complete-only final step'));
  await _capture(binding, tester, 'device_barrier_dismiss_05');
  await _tapAt(tester, _safeOutsidePoint(tester));
  await tester.pumpAndSettle();
  await _capture(binding, tester, 'device_barrier_dismiss_06');
}

Future<void> _captureControllerApi(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Controller API',
    waitFor: find.text('Portal steps'),
  );
  await _capture(binding, tester, 'device_controller_01');
  await _hideGuide(tester);
}

Future<void> _captureSideAnchors(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await _pumpScenario(
    tester,
    'Side anchors',
    waitFor: find.text('Horizontal auto: left arrow'),
  );
  await _capture(binding, tester, 'device_side_anchor_left_01');
  await _tap(tester, find.text('Next').hitTestable());
  await tester.pumpAndSettle();
  await _pumpUntilFound(tester, find.text('Horizontal auto: right arrow'));
  await _capture(binding, tester, 'device_side_anchor_right_01');
  await _hideGuide(tester);
}

Future<void> _pumpScenario(
  WidgetTester tester,
  String label, {
  Finder? waitFor,
}) async {
  await _pumpFreshApp(tester);
  await _tapScenario(tester, label);
  if (waitFor != null) {
    await _pumpUntilFound(tester, waitFor);
  }
}

Future<void> _pumpFreshApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(const SpotlightGuideExampleApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await _skipHomeIntro(tester);
}

Future<void> _tapScenario(WidgetTester tester, String label) async {
  final Finder scenarioButton = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(scenarioButton);
  await tester.pumpAndSettle();
  await _tap(tester, scenarioButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const Duration frame = Duration(milliseconds: 16);
  Duration elapsed = Duration.zero;
  while (elapsed < duration) {
    final Duration remaining = duration - elapsed;
    final Duration delta = remaining < frame ? remaining : frame;
    await tester.pump(delta);
    elapsed += delta;
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  const Duration frame = Duration(milliseconds: 50);
  Duration elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(frame);
    elapsed += frame;
  }
  expect(finder, findsWidgets);
}

Future<void> _hideGuide(WidgetTester tester) async {
  final bool finishedWithButton = await _finishCurrentGuide(tester);
  if (!finishedWithButton) {
    await _tapAt(tester, _safeOutsidePoint(tester));
    await tester.pumpAndSettle();
  }
}

Future<void> _skipHomeIntro(WidgetTester tester) async {
  await _tapAt(tester, _safeOutsidePoint(tester));
  await tester.pumpAndSettle();
}

Future<bool> _finishCurrentGuide(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pumpAndSettle();
    final Finder done = find.text('Done').hitTestable();
    if (done.evaluate().isNotEmpty) {
      await _tap(tester, done);
      await tester.pumpAndSettle();
      return true;
    }

    final Finder next = find.text('Next').hitTestable();
    if (next.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      continue;
    }
    await _tap(tester, next);
    await tester.pumpAndSettle();
  }
  return false;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _tapAt(tester, tester.getCenter(finder));
}

Future<void> _tapAt(WidgetTester tester, Offset position) async {
  final int pointer = _nextPointer++;
  final int viewId = tester.view.viewId;
  final bool previousPropagate =
      tester.binding.shouldPropagateDevicePointerEvents;
  tester.binding.shouldPropagateDevicePointerEvents = true;
  tester.binding.handlePointerEventForSource(
    PointerDownEvent(pointer: pointer, position: position, viewId: viewId),
    source: TestBindingEventSource.device,
  );
  await tester.pump(const Duration(milliseconds: 16));
  tester.binding.handlePointerEventForSource(
    PointerUpEvent(pointer: pointer, position: position, viewId: viewId),
    source: TestBindingEventSource.device,
  );
  tester.binding.shouldPropagateDevicePointerEvents = previousPropagate;
  await tester.pump();
}

Future<void> _drag(WidgetTester tester, Finder finder, Offset offset) async {
  final int pointer = _nextPointer++;
  final int viewId = tester.view.viewId;
  final Offset start = tester.getCenter(finder);
  final bool previousPropagate =
      tester.binding.shouldPropagateDevicePointerEvents;
  tester.binding.shouldPropagateDevicePointerEvents = true;
  tester.binding.handlePointerEventForSource(
    PointerDownEvent(pointer: pointer, position: start, viewId: viewId),
    source: TestBindingEventSource.device,
  );
  const int steps = 12;
  for (int i = 1; i <= steps; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    final Offset position = start + offset * (i / steps);
    tester.binding.handlePointerEventForSource(
      PointerMoveEvent(pointer: pointer, position: position, viewId: viewId),
      source: TestBindingEventSource.device,
    );
  }
  await tester.pump(const Duration(milliseconds: 16));
  tester.binding.handlePointerEventForSource(
    PointerUpEvent(pointer: pointer, position: start + offset, viewId: viewId),
    source: TestBindingEventSource.device,
  );
  tester.binding.shouldPropagateDevicePointerEvents = previousPropagate;
  await tester.pump();
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name, {
  Duration settle = const Duration(milliseconds: 60),
}) async {
  await tester.pump();
  if (settle > Duration.zero) {
    await tester.pump(settle);
  }
  await binding.takeScreenshot(name);
}

Offset _safeOutsidePoint(WidgetTester tester) {
  final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
  return Offset(20, size.height - 24);
}

String _numberedName(String prefix, int index) {
  return '${prefix}_${index.toString().padLeft(2, '0')}';
}
