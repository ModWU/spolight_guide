import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:spotlight_guide_example/src/scenarios/custom_anchor_scenario.dart';
import 'package:spotlight_guide_example/src/scenarios/lazy_target_reveal_scenario.dart';
import 'package:spotlight_guide_example/src/spotlight_guide_example_app.dart';

void main() {
  test('lazy target scenario uses automatic vertical placement', () {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    final SpotlightGuideStep step = buildLazyTargetRevealScenario(
      historyController: controller,
    ).single;

    expect(step.items.single.placement, SpotlightGuidePlacement.verticalAuto);
  });

  test('custom anchor scenario uses a non-triangle Bezier anchor', () {
    final SpotlightGuideStep step = buildCustomAnchorScenario().single;
    final SpotlightGuideStepItem item = step.items.single;

    expect(item.decoration.anchor, isNot(isA<SpotlightGuideTriangleAnchor>()));
    expect(item.targetAnchorPosition.anchor, SpotlightGuideAnchor.center);
    expect(item.targetAnchorPosition.offset, 0);
  });

  testWidgets('custom anchor selector switches arrow styles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Custom anchor');

    expect(
      find.byKey(const ValueKey<String>('custom-anchor-droplet-selected')),
      findsOneWidget,
    );
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Sweep'), findsOneWidget);
    expect(find.text('Arrow'), findsOneWidget);

    final Finder bubbleHint = find.byType(SpotlightGuideBubbleHint);
    final Size initialSize = tester.getSize(bubbleHint);

    await tester.tap(find.text('Sweep'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('custom-anchor-sweep-selected')),
      findsOneWidget,
    );
    expect(tester.getSize(bubbleHint), initialSize);

    await tester.tap(find.text('Arrow'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('custom-anchor-arrow-selected')),
      findsOneWidget,
    );
    expect(tester.getSize(bubbleHint), initialSize);
  });

  testWidgets('example app renders the scenario entry list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Spotlight Guide Examples'), findsOneWidget);
    expect(find.text('Basic guide'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Same-step hints'), findsOneWidget);
    expect(find.text('Same-step scroll'), findsOneWidget);
    expect(find.text('Lazy target'), findsOneWidget);
    expect(find.text('Barrier dismiss'), findsOneWidget);
    expect(find.text('Dynamic steps'), findsOneWidget);
    expect(find.text('Large group'), findsOneWidget);
    expect(find.text('Custom anchor'), findsOneWidget);
    expect(find.text('Controller API'), findsOneWidget);
  });

  testWidgets('barrier tap skips the home intro', (WidgetTester tester) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Start with the smallest happy path: one target, then next.'),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();

    expect(
      find.text('Start with the smallest happy path: one target, then next.'),
      findsNothing,
    );
  });

  testWidgets('barrier dismiss anytime can close a no-button hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Barrier dismiss');

    expect(find.text('Tap outside anytime'), findsOneWidget);
    expect(find.text('Done').hitTestable(), findsNothing);
    expect(find.text('Next').hitTestable(), findsNothing);

    await tester.tapAt(const Offset(20, 590));
    await tester.pumpAndSettle();

    expect(find.text('Tap outside anytime'), findsNothing);
  });

  testWidgets('barrier dismiss onComplete waits until the final step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Barrier dismiss');
    await tester.tapAt(const Offset(20, 590));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Final'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Outside taps are ignored while'),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(20, 590));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Outside taps are ignored while'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Complete-only final step'), findsOneWidget);
    expect(find.text('Done').hitTestable(), findsNothing);

    await tester.tapAt(const Offset(20, 590));
    await tester.pumpAndSettle();

    expect(find.text('Complete-only final step'), findsNothing);
  });

  testWidgets('same-step hints can dismiss on barrier after all hints show', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);

    await _openScenario(tester, 'Same-step hints');
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);

    await tester.tapAt(const Offset(20, 590));
    await tester.pumpAndSettle();

    expect(find.text('Weight'), findsNothing);
    expect(find.text('Cost'), findsNothing);
    expect(find.text('Price'), findsNothing);
  });

  testWidgets('runtime reset restarts dynamic steps from the top target', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);

    await _openScenario(tester, 'Dynamic steps');
    expect(find.text('Always present'), findsOneWidget);

    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();
    expect(find.text('Always present'), findsOneWidget);

    await _finishCurrentGuide(tester);
    expect(find.text('Always present'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Reset'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Always present'), findsOneWidget);
    expect(find.text('Optional server target'), findsNothing);
  });
}

Future<void> _openScenario(WidgetTester tester, String label) async {
  final Finder button = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _finishCurrentGuide(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pumpAndSettle();
    final Finder done = find.text('Done').hitTestable();
    if (done.evaluate().isNotEmpty) {
      await tester.tap(done);
      await tester.pumpAndSettle();
      return;
    }

    final Finder next = find.text('Next').hitTestable();
    if (next.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      continue;
    }
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}
