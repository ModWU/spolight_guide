import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Target registration and target geometry tests.
///
/// Run this file when changing [SpotlightGuideTarget],
/// [SpotlightGuideStepItem.targetId], [SpotlightGuideStepItem.targetIds],
/// [SpotlightGuideStepItem.anchorTargetId], [SpotlightGuideStepItem.targetKey],
/// or portal refresh behavior for targets that appear and disappear after the
/// guide has started.
void main() {
  testWidgets('renders multiple hints in the same step', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('hint-a', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'b',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('hint-b', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('hint-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('hint-b')), findsOneWidget);
    expect(contexts['hint-a']?.itemTotal, 2);
    expect(contexts['hint-b']?.itemTotal, 2);
    expect(contexts['hint-a']?.stepTargetRects.length, 2);
    expect(contexts['hint-b']?.stepTargetRects.length, 2);
  });

  testWidgets('one hint can spotlight multiple targets', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>['a', 'b'],
              anchorTargetId: 'b',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('multi-target', contexts),
            ),
          ),
        ],
      ),
    );

    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('multi-target')), findsOneWidget);
    expect(contexts['multi-target']?.targetRects.length, 2);
    expect(contexts['multi-target']?.stepTargetRects.length, 2);
    final SpotlightGuideStepContext guide = contexts['multi-target']!;
    // The default fixture has target `b` at (240,360) 80x50. The highlighted
    // holes include both targets, but the anchor rect should be `b`.
    expect(guide.targetRect.left, moreOrLessEquals(240, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(360, epsilon: 0.5));
    expect(guide.targetRect.width, moreOrLessEquals(80, epsilon: 0.5));
    expect(guide.targetRect.height, moreOrLessEquals(50, epsilon: 0.5));
  });

  testWidgets('duplicate target ids are treated as one target group', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: const <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'duplicate',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            Positioned(
              left: 220,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'duplicate',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'duplicate',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('duplicate-id', contexts),
            ),
          ),
        ],
      ),
    );

    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('duplicate-id')), findsOneWidget);
    expect(contexts['duplicate-id']?.targetRects.length, 2);
    expect(contexts['duplicate-id']?.targetRect.width, greaterThan(200));
  });

  testWidgets('duplicate anchor target ids resolve as an anchor group', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: const <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'repeated-anchor',
                child: SizedBox(
                  width: 40,
                  height: 20,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            Positioned(
              left: 260,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'repeated-anchor',
                child: SizedBox(
                  width: 40,
                  height: 20,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
            Positioned(
              left: 140,
              top: 160,
              child: SpotlightGuideTarget(
                id: 'supporting-target',
                child: SizedBox(
                  width: 40,
                  height: 20,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>[
                'supporting-target',
                'repeated-anchor',
                'repeated-anchor',
              ],
              anchorTargetId: 'repeated-anchor',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('duplicate-anchor', contexts),
            ),
          ),
        ],
      ),
    );

    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['duplicate-anchor']!;
    expect(
      find.byKey(const ValueKey<String>('duplicate-anchor')),
      findsOneWidget,
    );
    expect(guide.targetRects.length, 3);
    expect(guide.targetRect.left, moreOrLessEquals(40, epsilon: 0.5));
    expect(guide.targetRect.right, moreOrLessEquals(300, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(40, epsilon: 0.5));
    expect(guide.targetRect.height, moreOrLessEquals(20, epsilon: 0.5));
  });

  testWidgets('duplicate target group can choose an anchor by anchorId', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: const <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'duplicate-card',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            Positioned(
              left: 220,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'duplicate-card',
                anchorId: 'selected-card',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'duplicate-card',
              anchorTargetId: 'selected-card',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('anchor-id', contexts),
            ),
          ),
        ],
      ),
    );

    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['anchor-id']!;
    expect(find.byKey(const ValueKey<String>('anchor-id')), findsOneWidget);
    expect(guide.targetRects.length, 2);
    expect(guide.targetRect.left, moreOrLessEquals(220, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(40, epsilon: 0.5));
    expect(guide.targetRect.width, moreOrLessEquals(80, epsilon: 0.5));
    expect(guide.targetRect.height, moreOrLessEquals(40, epsilon: 0.5));
  });

  testWidgets('removing anchorId rebuilds with the target group anchor', (
    tester,
  ) async {
    final List<SpotlightGuideStateDetails> states =
        <SpotlightGuideStateDetails>[];
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    bool useAnchorId = true;
    int hintBuilds = 0;

    Widget buildApp() {
      return guideApp(
        onStateChanged: states.add,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'dynamic-card',
                anchorId: useAnchorId ? 'dynamic-anchor' : null,
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            const Positioned(
              left: 220,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'dynamic-card',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'dynamic-card',
              anchorTargetId: 'dynamic-anchor',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    hintBuilds++;
                    contexts['dynamic-anchor'] = guide;
                    return Text(
                      'left=${guide.targetRect.left.round()}, '
                      'width=${guide.targetRect.width.round()}',
                      key: const ValueKey<String>('dynamic-anchor-hint'),
                    );
                  },
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(find.text('left=40, width=80'), findsOneWidget);
    expect(contexts['dynamic-anchor']?.targetRects.length, 2);
    final int buildsBeforeRemoval = hintBuilds;

    useAnchorId = false;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(find.text('left=40, width=260'), findsOneWidget);
    expect(hintBuilds, greaterThan(buildsBeforeRemoval));
    expect(contexts['dynamic-anchor']?.targetRects.length, 2);
    expect(
      states.any(
        (SpotlightGuideStateDetails state) =>
            state.reason == SpotlightGuideStateChangeReason.targetsChanged,
      ),
      isTrue,
    );
  });

  testWidgets('targetKey can position a hint without a registered target id', (
    tester,
  ) async {
    final GlobalKey targetKey = GlobalKey();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 180,
              top: 210,
              child: SizedBox(
                key: targetKey,
                width: 70,
                height: 30,
                child: const ColoredBox(color: Colors.green),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetKey: targetKey,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('target-key', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['target-key']!;
    final Rect targetRect = tester.getRect(find.byKey(targetKey));
    expect(find.byKey(const ValueKey<String>('target-key')), findsOneWidget);
    expect(guide.targetRect, targetRect);
  });

  testWidgets('missing target can appear later and then disappear', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    bool showTarget = false;

    Widget buildApp() {
      return guideApp(
        controller: controller,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
        child: optionalTargetStack(
          showTarget: showTarget,
          id: 'late',
          left: 260,
          top: 160,
          width: 70,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'late',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('late-target'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    controller.reset();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('late-target')), findsNothing);
    expect(controller.isShowing, isTrue);

    showTarget = true;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('late-target')), findsOneWidget);

    showTarget = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('late-target')), findsNothing);

    showTarget = true;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('late-target')), findsOneWidget);
  });

  testWidgets(
    'missing target wait does not block page taps after preparation',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      int childTaps = 0;

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
          child: GestureDetector(
            key: const ValueKey<String>('missing-wait-child'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              childTaps++;
            },
            child: const SizedBox.expand(),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'late-never',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('late-never-hint'),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('late-never-hint')),
        findsNothing,
      );
      expect(controller.isShowing, isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('missing-wait-child')),
      );
      await tester.pump();

      expect(childTaps, 1);
    },
  );

  testWidgets('target removal rebuilds visible hints and notifies state', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<SpotlightGuideStateDetails> states =
        <SpotlightGuideStateDetails>[];
    bool showSecondTarget = true;
    int firstHintBuilds = 0;

    Widget buildApp() {
      return guideApp(
        controller: controller,
        onStateChanged: states.add,
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'stable-target',
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            if (showSecondTarget)
              const Positioned(
                left: 240,
                top: 360,
                child: SpotlightGuideTarget(
                  id: 'removable-target',
                  child: SizedBox(
                    width: 80,
                    height: 50,
                    child: ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'stable-target',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      firstHintBuilds++;
                      return Text(
                        'stable-build-$firstHintBuilds',
                        key: const ValueKey<String>('stable-hint'),
                      );
                    },
              ),
              SpotlightGuideStepItem(
                targetId: 'removable-target',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('removable-hint'),
              ),
            ],
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    controller.reset();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('stable-hint')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('removable-hint')),
      findsOneWidget,
    );
    final int buildsAfterShow = firstHintBuilds;

    showSecondTarget = false;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('stable-hint')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('removable-hint')), findsNothing);
    expect(firstHintBuilds, greaterThan(buildsAfterShow));
    expect(
      states.any(
        (SpotlightGuideStateDetails state) =>
            state.reason == SpotlightGuideStateChangeReason.targetsChanged &&
            state.index == 0 &&
            state.total == 1 &&
            state.resolvedItemCount == 1,
      ),
      isTrue,
    );
  });

  testWidgets('enabled toggle keeps the child subtree mounted', (tester) async {
    int initCount = 0;

    await tester.pumpWidget(
      guideApp(
        enabled: false,
        child: CountingTargetStack(
          onInit: () {
            initCount++;
          },
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('toggle-hint'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(initCount, 1);
    expect(find.byKey(const ValueKey<String>('toggle-hint')), findsNothing);

    await tester.pumpWidget(
      guideApp(
        enabled: true,
        child: CountingTargetStack(
          onInit: () {
            initCount++;
          },
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('toggle-hint'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(initCount, 1);
    expect(find.byKey(const ValueKey<String>('toggle-hint')), findsOneWidget);
  });

  testWidgets('a disabled target is not available for placement', (
    tester,
  ) async {
    await tester.pumpWidget(
      guideApp(
        child: const Stack(
          children: <Widget>[
            Positioned(
              left: 120,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'disabled',
                enabled: false,
                child: SizedBox(
                  width: 60,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'disabled',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('disabled-target'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('disabled-target')), findsNothing);
  });

  testWidgets('toggling target enabled registers and unregisters it', (
    tester,
  ) async {
    Widget buildApp({required bool targetEnabled}) {
      return guideApp(
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 120,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'toggle-target',
                enabled: targetEnabled,
                child: const SizedBox(
                  width: 60,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'toggle-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('target-enabled-toggle'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp(targetEnabled: false));
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('target-enabled-toggle')),
      findsNothing,
    );

    await tester.pumpWidget(buildApp(targetEnabled: true));
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('target-enabled-toggle')),
      findsOneWidget,
    );
  });

  testWidgets('one missing id in targetIds prevents the hint from showing', (
    tester,
  ) async {
    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>['a', 'never-registered'],
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('partial-multi-target'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('partial-multi-target')),
      findsNothing,
    );
  });

  testWidgets('missing target default removes it from the active sequence', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'never-registered',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('missing-skip-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'b',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('missing-skip-1'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('missing-skip-0')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('missing-skip-1')),
      findsOneWidget,
    );
    expect(controller.index, 0);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
  });

  testWidgets('removed target with skip behavior updates active sequence', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<SpotlightGuideStateDetails> states =
        <SpotlightGuideStateDetails>[];
    bool showFirstTarget = true;

    Widget buildApp() {
      return guideApp(
        controller: controller,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
        onStateChanged: states.add,
        child: Stack(
          children: <Widget>[
            if (showFirstTarget)
              const Positioned(
                left: 40,
                top: 40,
                child: SpotlightGuideTarget(
                  id: 'first-removable',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
            const Positioned(
              left: 240,
              top: 360,
              child: SpotlightGuideTarget(
                id: 'second-stable',
                child: SizedBox(
                  width: 80,
                  height: 50,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'first-removable',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('first-removable-hint'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'second-stable',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('second-stable-hint'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    controller.reset();
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('first-removable-hint')),
      findsOneWidget,
    );

    showFirstTarget = false;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('first-removable-hint')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('second-stable-hint')),
      findsOneWidget,
    );
    expect(controller.index, 0);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
    expect(
      states.any(
        (SpotlightGuideStateDetails state) =>
            state.reason == SpotlightGuideStateChangeReason.targetsChanged &&
            state.index == 0 &&
            state.total == 1 &&
            state.resolvedItemCount == 1,
      ),
      isTrue,
    );
    expect(
      states.any(
        (SpotlightGuideStateDetails state) =>
            state.reason == SpotlightGuideStateChangeReason.shown &&
            state.index == 0 &&
            state.total == 1 &&
            state.resolvedItemCount == 1,
      ),
      isTrue,
    );
  });

  testWidgets('future target removal rebuilds the current hint metadata', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<SpotlightGuideStateDetails> states =
        <SpotlightGuideStateDetails>[];
    bool showThirdTarget = true;
    int secondHintBuilds = 0;

    Widget buildApp() {
      return guideApp(
        controller: controller,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
        onStateChanged: states.add,
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'future-first',
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            const Positioned(
              left: 80,
              top: 180,
              child: SpotlightGuideTarget(
                id: 'future-second',
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ),
            if (showThirdTarget)
              const Positioned(
                left: 120,
                top: 320,
                child: SpotlightGuideTarget(
                  id: 'future-third',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'future-first',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('future-first-hint'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'future-second',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    secondHintBuilds++;
                    return Text(
                      'step=${guide.index + 1}/${guide.total}, '
                      'last=${guide.isLast}',
                      key: const ValueKey<String>('future-second-hint'),
                    );
                  },
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'future-third',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('future-third-hint'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    controller.reset();
    await pumpGuide(tester);
    controller.next();
    await pumpGuide(tester);

    expect(find.text('step=2/3, last=false'), findsOneWidget);
    expect(controller.index, 1);
    expect(controller.total, 3);
    final int buildsBeforeRemoval = secondHintBuilds;

    showThirdTarget = false;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(find.text('step=2/2, last=true'), findsOneWidget);
    expect(secondHintBuilds, greaterThan(buildsBeforeRemoval));
    expect(controller.index, 1);
    expect(controller.total, 2);
    expect(controller.isLast, isTrue);
    expect(
      states.any(
        (SpotlightGuideStateDetails state) =>
            state.reason == SpotlightGuideStateChangeReason.targetsChanged &&
            state.index == 1 &&
            state.total == 2 &&
            state.isLast,
      ),
      isTrue,
    );
  });

  testWidgets('all missing skipped targets hide without onFinish', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'never-registered',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('all-missing-skip'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('all-missing-skip')),
      findsNothing,
    );
    expect(controller.isShowing, isFalse);
    expect(finishCount, 0);
  });

  testWidgets('item can wait for a late target when portal default skips', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    bool showTarget = false;

    Widget buildApp() {
      return guideApp(
        controller: controller,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
        child: optionalTargetStack(
          showTarget: showTarget,
          id: 'late-wait',
          left: 260,
          top: 160,
          width: 70,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'late-wait',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
              hintBuilder: hint('late-wait-hint'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    controller.reset();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('late-wait-hint')), findsNothing);
    expect(controller.isShowing, isTrue);

    showTarget = true;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('late-wait-hint')),
      findsOneWidget,
    );
    expect(controller.isShowing, isTrue);
  });

  testWidgets('unknown anchorTargetId falls back to the union rect', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>['a', 'b'],
              anchorTargetId: 'not-in-list',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('anchor-fallback', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['anchor-fallback']!;
    // The default fixture has target `a` at (40,40) 100x40 and `b` at
    // (240,360) 80x50. The anchor rect should be their union.
    expect(guide.targetRect.left, moreOrLessEquals(40, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(40, epsilon: 0.5));
    expect(guide.targetRect.right, moreOrLessEquals(320, epsilon: 0.5));
    expect(guide.targetRect.bottom, moreOrLessEquals(410, epsilon: 0.5));
  });

  testWidgets('an item without a target highlights the whole portal child', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('whole-child', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['whole-child']!;
    expect(find.byKey(const ValueKey<String>('whole-child')), findsOneWidget);
    expect(guide.targetRect.left, moreOrLessEquals(0, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(0, epsilon: 0.5));
    expect(
      guide.targetRect.width,
      moreOrLessEquals(guide.overlaySize.width, epsilon: 0.5),
    );
    expect(
      guide.targetRect.height,
      moreOrLessEquals(guide.overlaySize.height, epsilon: 0.5),
    );
  });
}
