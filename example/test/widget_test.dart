import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:spotlight_guide_example/src/guide_target_ids.dart';
import 'package:spotlight_guide_example/src/pages/side_anchor_page.dart';
import 'package:spotlight_guide_example/src/scenarios/custom_anchor_scenario.dart';
import 'package:spotlight_guide_example/src/scenarios/lazy_target_reveal_scenario.dart';
import 'package:spotlight_guide_example/src/scenarios/pointer_hint_scenario.dart';
import 'package:spotlight_guide_example/src/scenarios/side_anchor_scenario.dart';
import 'package:spotlight_guide_example/src/scenarios/target_decoration_scenario.dart';
import 'package:spotlight_guide_example/src/spotlight_guide_example_app.dart';
import 'package:spotlight_guide_example/src/widgets/guide_hint.dart';

void main() {
  test('lazy target scenario uses automatic vertical placement', () {
    final ScrollController pageController = ScrollController();
    final ScrollController controller = ScrollController();
    addTearDown(pageController.dispose);
    addTearDown(controller.dispose);

    final SpotlightGuideStep step = buildLazyTargetRevealScenario(
      pageController: pageController,
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

  test('side anchor scenario uses horizontal auto placement', () {
    final List<SpotlightGuideStep> steps = buildSideAnchorScenario();

    expect(steps, hasLength(2));
    expect(
      steps.expand((SpotlightGuideStep step) => step.items),
      everyElement(
        isA<SpotlightGuideStepItem>().having(
          (SpotlightGuideStepItem item) => item.placement,
          'placement',
          SpotlightGuidePlacement.horizontalAuto,
        ),
      ),
    );
  });

  test('pointer hint scenario uses the built-in tap pointer', () {
    final List<SpotlightGuideStep> steps = buildPointerHintScenario();

    expect(steps, hasLength(greaterThanOrEqualTo(5)));
    expect(
      steps.map((SpotlightGuideStep step) => step.items.single.targetId),
      containsAll(<String>[
        pointerLeftOfTargetId,
        pointerAboveTargetId,
        pointerCustomAssetId,
        pointerEdgeAnchorId,
        pointerAutoSideId,
        pointerDirectAnchorId,
      ]),
    );
    expect(
      steps.map((SpotlightGuideStep step) => step.items.single.placement),
      containsAll(<SpotlightGuidePlacement>[
        SpotlightGuidePlacement.start,
        SpotlightGuidePlacement.top,
        SpotlightGuidePlacement.verticalAuto,
        SpotlightGuidePlacement.right,
        SpotlightGuidePlacement.horizontalAuto,
      ]),
    );
    expect(
      steps[2].items.single.placement,
      SpotlightGuidePlacement.verticalAuto,
    );
    expect(steps.last.items.single.targetId, pointerDirectAnchorId);
    expect(
      steps.last.items.single.placement,
      SpotlightGuidePlacement.verticalAuto,
    );
    expect(
      steps.first.items.single.targetAnchorPosition.anchor,
      SpotlightGuideAnchor.center,
    );
  });

  test('target decoration scenario uses layered target rings', () {
    final SpotlightGuideStep step = buildTargetDecorationScenario().first;
    final SpotlightGuideTargetDecoration decoration =
        step.items.single.targetDecoration;

    expect(decoration.shape, isA<SpotlightGuideRoundedRectShape>());
    expect(decoration.layers, hasLength(2));
    expect(decoration.layers.first, isA<SpotlightGuideTargetRingLayer>());
    expect(decoration.layers.last, isA<SpotlightGuideTargetRingLayer>());
  });

  test('target decoration scenario includes a blurred glow layer', () {
    final SpotlightGuideStep step = buildTargetDecorationScenario()[1];
    final SpotlightGuideTargetDecoration decoration =
        step.items.single.targetDecoration;

    expect(step.items.single.targetId, targetDecorationSoftGlowId);
    expect(decoration.shape, isA<SpotlightGuideRoundedRectShape>());
    expect(decoration.layers, hasLength(1));
    final SpotlightGuideTargetGlowLayer layer =
        decoration.layers.single as SpotlightGuideTargetGlowLayer;
    expect(layer.blurRadius, greaterThanOrEqualTo(16));
    expect(layer.spreadRadius, 0);
  });

  test('target decoration scenario includes an oval glow layer', () {
    final SpotlightGuideStep step = buildTargetDecorationScenario()[2];
    final SpotlightGuideTargetDecoration decoration =
        step.items.single.targetDecoration;

    expect(step.items.single.targetId, targetDecorationGlowId);
    expect(decoration.shape, isA<SpotlightGuideOvalShape>());
    expect(decoration.layers, hasLength(2));
    expect(decoration.layers.first, isA<SpotlightGuideTargetGlowLayer>());
    expect(decoration.layers.last, isA<SpotlightGuideTargetRingLayer>());
  });

  test('target decoration scenario includes a dashed outline layer', () {
    final SpotlightGuideStep step = buildTargetDecorationScenario()[3];
    final SpotlightGuideTargetDecoration decoration =
        step.items.single.targetDecoration;

    expect(step.items.single.targetId, targetDecorationDashedId);
    expect(decoration.shape, isA<SpotlightGuideRoundedRectShape>());
    expect(decoration.layers, hasLength(1));
    expect(decoration.layers.single, isA<SpotlightGuideTargetOutlineLayer>());
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
    expect(find.text('None'), findsOneWidget);

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

    await tester.drag(
      find.byKey(const ValueKey<String>('custom-anchor-choice-scroll')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('custom-anchor-none-selected')),
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
    expect(find.text('Pointer hint'), findsOneWidget);
    expect(find.text('Same-step hints'), findsOneWidget);
    expect(find.text('Same-step scroll'), findsOneWidget);
    expect(find.text('Lazy target'), findsOneWidget);
    expect(find.text('Barrier dismiss'), findsOneWidget);
    expect(find.text('Target decoration'), findsOneWidget);
    expect(find.text('Dynamic steps'), findsOneWidget);
    expect(find.text('Side anchors'), findsOneWidget);
    expect(find.text('Large group'), findsOneWidget);
    expect(find.text('Custom anchor'), findsOneWidget);
    expect(find.text('Controller API'), findsOneWidget);
  });

  testWidgets('pointer hint page shows the built-in pointer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Pointer hint');

    expect(find.text('Pointer hint'), findsWidgets);
    expect(find.byType(SpotlightGuideTapPointer), findsOneWidget);
    expect(find.byType(SpotlightGuideTextHint), findsOneWidget);
    expect(find.byType(SpotlightGuideBubbleHint), findsOneWidget);
    expect(find.text('Right-pointing pointer'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('Pointer'), findsOneWidget);

    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('right-pointing-pointer-slot')),
    );
    final Rect handRect = tester.getRect(find.byType(SpotlightGuideTapPointer));
    final Rect connectorRect = tester.getRect(
      find.byKey(const ValueKey<String>('right-pointing-pointer-connector')),
    );
    final Rect targetRect = tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SpotlightGuideTarget &&
            widget.id == pointerLeftOfTargetId,
      ),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final dynamic bubble = tester.renderObject(
      find.byType(SpotlightGuideBubble),
    );
    final SpotlightGuideBubbleDecoration bubbleDecoration =
        bubble.effectiveDecoration as SpotlightGuideBubbleDecoration;
    final SpotlightGuideAnchorGeometry anchorGeometry =
        bubbleDecoration.effectiveAnchorGeometry!;
    final double safeInset = bubbleDecoration.anchorSafeInset;
    const double pointerHandSize = 64;

    expect(
      handRect.center.dy,
      moreOrLessEquals(targetRect.center.dy, epsilon: 8),
      reason:
          'pointer=$pointerRect hand=$handRect target=$targetRect '
          'bubble=$bubbleRect',
    );
    expect(handRect.right, lessThan(targetRect.left));
    expect(
      connectorRect.center.dx,
      moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
    );
    expect(
      connectorRect.top,
      moreOrLessEquals(pointerRect.top + pointerHandSize, epsilon: 0.5),
    );
    expect(bubbleRect.top, greaterThanOrEqualTo(pointerRect.bottom - 0.5));
    expect(bubbleRect.top, greaterThanOrEqualTo(targetRect.bottom - 0.5));
    expect(anchorGeometry.direction, SpotlightGuideDirection.up);
    expect(anchorGeometry.offset, greaterThanOrEqualTo(safeInset));
    expect(
      anchorGeometry.offset,
      lessThanOrEqualTo(bubbleRect.width - safeInset),
    );
    expect(
      bubbleRect.left + anchorGeometry.offset,
      moreOrLessEquals(pointerRect.center.dx, epsilon: 1),
    );
    expect(bubbleRect.top, greaterThanOrEqualTo(connectorRect.bottom - 0.5));
    expect(
      _tapPointerRotation(tester),
      moreOrLessEquals(math.pi / 2, epsilon: 0.001),
    );

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Top pointer'), findsOneWidget);
    final SpotlightGuideTapPointer topPointer = tester.widget(
      find.byType(SpotlightGuideTapPointer),
    );
    expect(topPointer.color, const Color(0xFFFFFFFF));
    expect(topPointer.ringColor, const Color(0xBFFFFFFF));
    expect(
      _tapPointerRotation(tester),
      moreOrLessEquals(math.pi, epsilon: 0.001),
    );
  });

  testWidgets('pointer hint page keeps every pointer close to its target', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Pointer hint');

    const List<String> titles = <String>[
      'Right-pointing pointer',
      'Top pointer',
      'Custom pointer widget',
      'Edge anchored pointer',
      'Auto side pointer',
    ];

    for (int index = 0; index < titles.length; index += 1) {
      final SpotlightGuideTextHint hint = tester.widget(
        find.byType(SpotlightGuideTextHint),
      );
      expect(hint.title, titles[index]);
      expect(hint.guide.pointer?.targetGap, 4);

      if (index < titles.length - 1) {
        await tester.tap(find.text('Next').hitTestable());
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets(
    'custom pointer bottom bubble keeps action buttons hit-testable',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SpotlightGuideExampleApp());
      await tester.pumpAndSettle();

      await _finishCurrentGuide(tester);
      await _openScenario(tester, 'Pointer hint');

      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Custom pointer widget'), findsOneWidget);
      expect(find.text('Next').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Edge anchored pointer'), findsOneWidget);
    },
  );

  testWidgets('pointer hint tap pointers rotate from the built-in hand pose', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Pointer hint');

    const Map<String, double> expectedRotations = <String, double>{
      'Right-pointing pointer': math.pi / 2,
      'Top pointer': math.pi,
      'Edge anchored pointer': -math.pi / 2,
      'Auto side pointer': -math.pi / 2,
    };

    for (int index = 0; index < 5; index += 1) {
      final SpotlightGuideTextHint hint = tester.widget(
        find.byType(SpotlightGuideTextHint),
      );
      final double? expectedRotation = expectedRotations[hint.title];
      if (expectedRotation != null) {
        expect(
          _tapPointerRotation(tester),
          moreOrLessEquals(expectedRotation, epsilon: 0.001),
          reason: hint.title,
        );
      }

      if (index < 4) {
        await tester.tap(find.text('Next').hitTestable());
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('pointer edge anchor bubble stays inside phone margin', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    await _finishCurrentGuide(tester);
    await _openScenario(tester, 'Pointer hint');
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
    }

    final SpotlightGuideTextHint hint = tester.widget(
      find.byType(SpotlightGuideTextHint),
    );
    expect(hint.title, 'Edge anchored pointer');

    final Rect pointerRect = tester.getRect(
      find.byType(SpotlightGuideTapPointer),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final dynamic bubble = tester.renderObject(
      find.byType(SpotlightGuideBubble),
    );
    final SpotlightGuideBubbleDecoration bubbleDecoration =
        bubble.effectiveDecoration as SpotlightGuideBubbleDecoration;
    final SpotlightGuideAnchorGeometry anchorGeometry =
        bubbleDecoration.effectiveAnchorGeometry!;

    expect(
      bubbleRect.left,
      greaterThanOrEqualTo(kExampleGuideMargin.left - 0.5),
    );
    expect(
      bubbleRect.right,
      lessThanOrEqualTo(430 - kExampleGuideMargin.right + 0.5),
    );
    expect(
      bubbleRect.top + anchorGeometry.offset,
      moreOrLessEquals(pointerRect.top + 12, epsilon: 1),
    );
    expect(anchorGeometry.direction, SpotlightGuideDirection.left);
  });

  testWidgets('side anchor page target cards do not overflow on tall phones', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: SideAnchorPage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Left arrow'), findsWidgets);
    expect(find.text('Right arrow'), findsWidgets);

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('barrier tap skips the home intro', (WidgetTester tester) async {
    await tester.pumpWidget(const SpotlightGuideExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Use the built-in text hint for the smallest happy path.'),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();

    expect(
      find.text('Use the built-in text hint for the smallest happy path.'),
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

double _tapPointerRotation(WidgetTester tester) {
  final Transform transform = tester.widget(
    find.byWidgetPredicate(
      (Widget widget) =>
          widget is Transform && widget.child is SpotlightGuideTapPointer,
    ),
  );
  final List<double> storage = transform.transform.storage;
  return math.atan2(storage[1], storage[0]);
}
