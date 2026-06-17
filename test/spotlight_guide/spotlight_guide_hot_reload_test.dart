import 'dart:async';

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Hot-reload-like rebuild tests.
///
/// Widget tests cannot press the IDE hot reload button, but they can exercise
/// the same state contract: keep the same mounted portal/controller alive and
/// rebuild the parent with changed guide configuration while a step is visible.
void main() {
  testWidgets('parent rebuild preserves active index for portal steps', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('portal-first-old', targetId: 'a', contexts: contexts),
          _step('portal-second-old', targetId: 'b', contexts: contexts),
        ],
      ),
    );

    controller.showPortal(index: 1);
    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('portal-second-old')),
      findsOneWidget,
    );
    expect(controller.index, 1);
    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('portal-second-old')),
      findsOneWidget,
    );
    expect(controller.index, 1);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('portal-first-new', targetId: 'a', contexts: contexts),
          _step(
            'portal-second-new',
            targetId: 'a',
            placement: SpotlightGuidePlacement.bottom,
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('portal-second-old')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('portal-second-new')),
      findsOneWidget,
    );
    expect(controller.index, 1);
    expect(controller.total, 2);
    expect(contexts['portal-second-new']?.targetRect.center.dx, lessThan(160));
  });

  testWidgets(
    'first-step property changes do not jump index or duplicate steps on next',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      int finishCount = 0;

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onFinish: () {
            finishCount++;
          },
          steps: <SpotlightGuideStep>[
            _step(
              'first-before-hot-reload',
              placement: SpotlightGuidePlacement.top,
              contexts: contexts,
            ),
            _step(
              'second-before-hot-reload',
              targetId: 'b',
              contexts: contexts,
            ),
          ],
        ),
      );

      controller.showPortal();
      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('first-before-hot-reload')),
        findsOneWidget,
      );
      expect(controller.index, 0);
      expect(controller.total, 2);
      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onFinish: () {
            finishCount++;
          },
          steps: <SpotlightGuideStep>[
            _step(
              'first-after-hot-reload',
              placement: SpotlightGuidePlacement.bottom,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.end(6),
              gap: 22,
              minWidth: 160,
              maxWidth: 160,
              contexts: contexts,
            ),
            _step(
              'second-after-hot-reload',
              targetId: 'b',
              placement: SpotlightGuidePlacement.left,
              contexts: contexts,
            ),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('first-before-hot-reload')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('first-after-hot-reload')),
        findsOneWidget,
      );
      expect(controller.index, 0);
      expect(controller.total, 2);
      final SpotlightGuideStepContext firstGuide =
          contexts['first-after-hot-reload']!;
      expect(firstGuide.index, 0);
      expect(firstGuide.total, 2);
      expect(firstGuide.placement, SpotlightGuidePlacement.bottom);
      expect(firstGuide.hintRect.width, moreOrLessEquals(160, epsilon: 0.5));

      controller.next();
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('first-after-hot-reload')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('second-after-hot-reload')),
        findsOneWidget,
      );
      expect(controller.index, 1);
      expect(controller.total, 2);
      expect(controller.isLast, isTrue);
      expect(contexts['second-after-hot-reload']?.index, 1);
      expect(contexts['second-after-hot-reload']?.total, 2);

      controller.next();
      await _pumpHotReloadGuide(tester);

      expect(controller.isShowing, isFalse);
      expect(finishCount, 1);
      expect(
        find.byKey(const ValueKey<String>('first-after-hot-reload')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('second-after-hot-reload')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'auto-start first step rebuild does not append a duplicate final step',
    (tester) async {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      int finishCount = 0;

      await tester.pumpWidget(
        guideApp(
          onFinish: () {
            finishCount++;
          },
          steps: <SpotlightGuideStep>[
            _step(
              'auto-first-before',
              placement: SpotlightGuidePlacement.top,
              contexts: contexts,
            ),
            _step('auto-second-before', targetId: 'b', contexts: contexts),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('auto-first-before')),
        findsOneWidget,
      );
      expect(contexts['auto-first-before']?.index, 0);
      expect(contexts['auto-first-before']?.total, 2);

      await tester.pumpWidget(
        guideApp(
          onFinish: () {
            finishCount++;
          },
          steps: <SpotlightGuideStep>[
            _step(
              'auto-first-after',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.all(6),
              ),
              targetAnchorPosition: const SpotlightGuideAnchorPosition.start(4),
              gap: 18,
              contexts: contexts,
            ),
            _step(
              'auto-second-after',
              targetId: 'b',
              placement: SpotlightGuidePlacement.right,
              contexts: contexts,
            ),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('auto-first-before')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('auto-first-after')),
        findsOneWidget,
      );
      expect(contexts['auto-first-after']?.index, 0);
      expect(contexts['auto-first-after']?.total, 2);
      expect(contexts['auto-first-after']?.isLast, isFalse);

      contexts['auto-first-after']!.next();
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('auto-first-after')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('auto-second-after')),
        findsOneWidget,
      );
      expect(contexts['auto-second-after']?.index, 1);
      expect(contexts['auto-second-after']?.total, 2);
      expect(contexts['auto-second-after']?.isLast, isTrue);

      contexts['auto-second-after']!.next();
      await _pumpHotReloadGuide(tester);

      expect(finishCount, 1);
      expect(
        find.byKey(const ValueKey<String>('auto-second-after')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'reassemble cancels in-flight preparation and restarts current step',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final Completer<void> oldPreparation = Completer<void>();
      int oldWillShowCount = 0;
      int newWillShowCount = 0;

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onStepWillShow: (int index, SpotlightGuideStep step) {
            oldWillShowCount++;
            return oldPreparation.future;
          },
          steps: <SpotlightGuideStep>[
            _step('prepare-old-first'),
            _step('prepare-old-second', targetId: 'b'),
          ],
        ),
      );

      controller.showPortal();
      await tester.pump();
      expect(oldWillShowCount, 1);
      expect(
        find.byKey(const ValueKey<String>('prepare-old-first')),
        findsNothing,
      );

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onStepWillShow: (int index, SpotlightGuideStep step) {
            newWillShowCount++;
            return Future<void>.value();
          },
          steps: <SpotlightGuideStep>[
            _step(
              'prepare-new-first',
              placement: SpotlightGuidePlacement.bottom,
              minWidth: 150,
              maxWidth: 150,
            ),
            _step('prepare-new-second', targetId: 'b'),
          ],
        ),
      );
      expect(controller.isShowing, isTrue);

      final dynamic portalState = tester.state(
        find.byType(SpotlightGuidePortal),
      );
      portalState.reassemble();
      await _pumpHotReloadGuide(tester);

      expect(oldWillShowCount, 1);
      expect(newWillShowCount, 1);
      expect(
        find.byKey(const ValueKey<String>('prepare-old-first')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('prepare-new-first')),
        findsOneWidget,
      );
      expect(controller.index, 0);
      expect(controller.total, 2);

      oldPreparation.complete();
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('prepare-new-first')),
        findsOneWidget,
      );
      expect(controller.index, 0);
      expect(controller.total, 2);
    },
  );

  testWidgets('reassemble before parent rebuild still applies latest steps', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('reassemble-order-old-0', contexts: contexts),
          _step('reassemble-order-old-1', targetId: 'b', contexts: contexts),
        ],
      ),
    );

    controller.showPortal(index: 1);
    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('reassemble-order-old-1')),
      findsOneWidget,
    );

    final dynamic portalState = tester.state(find.byType(SpotlightGuidePortal));
    portalState.reassemble();
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('reassemble-order-new-0', contexts: contexts),
          _step(
            'reassemble-order-new-1',
            targetId: 'a',
            placement: SpotlightGuidePlacement.bottom,
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('reassemble-order-old-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('reassemble-order-new-1')),
      findsOneWidget,
    );
    expect(controller.index, 1);
    expect(controller.total, 2);
    expect(
      contexts['reassemble-order-new-1']?.placement,
      SpotlightGuidePlacement.bottom,
    );
  });

  testWidgets(
    'stale parent-rebuild preparation cannot hide the newer visible step',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final Completer<void> oldPreparation = Completer<void>();
      int oldWillShowCount = 0;
      int newWillShowCount = 0;

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onStepWillShow: (int index, SpotlightGuideStep step) {
            oldWillShowCount++;
            return oldPreparation.future;
          },
          steps: <SpotlightGuideStep>[
            _step('stale-rebuild-old-0'),
            _step('stale-rebuild-old-1', targetId: 'b'),
          ],
        ),
      );

      controller.showPortal();
      await tester.pump();
      expect(oldWillShowCount, 1);
      expect(
        find.byKey(const ValueKey<String>('stale-rebuild-old-0')),
        findsNothing,
      );

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onStepWillShow: (int index, SpotlightGuideStep step) {
            newWillShowCount++;
            return Future<void>.value();
          },
          steps: <SpotlightGuideStep>[
            _step(
              'stale-rebuild-new-0',
              placement: SpotlightGuidePlacement.bottom,
            ),
            _step('stale-rebuild-new-1', targetId: 'b'),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);

      expect(oldWillShowCount, 1);
      expect(newWillShowCount, 1);
      expect(
        find.byKey(const ValueKey<String>('stale-rebuild-new-0')),
        findsOneWidget,
      );

      oldPreparation.complete();
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('stale-rebuild-new-0')),
        findsOneWidget,
      );
      expect(controller.index, 0);
      expect(controller.total, 2);
      controller.next();
      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('stale-rebuild-new-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets('current layout-critical item properties update in place', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 280,
          top: 250,
          width: 80,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          _step(
            'layout-old',
            placement: SpotlightGuidePlacement.bottom,
            gap: 8,
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);
    final SpotlightGuideStepContext oldGuide = contexts['layout-old']!;
    expect(oldGuide.placement, SpotlightGuidePlacement.bottom);
    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 280,
          top: 250,
          width: 80,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          _step(
            'layout-new',
            placement: SpotlightGuidePlacement.right,
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.fromLTRB(12, 8, 4, 6),
              shape: SpotlightGuideRoundedRectShape(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            targetAnchorPosition: const SpotlightGuideAnchorPosition.end(10),
            gap: 24,
            margin: const EdgeInsets.all(20),
            minWidth: 140,
            maxWidth: 140,
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(find.byKey(const ValueKey<String>('layout-old')), findsNothing);
    expect(find.byKey(const ValueKey<String>('layout-new')), findsOneWidget);
    final SpotlightGuideStepContext newGuide = contexts['layout-new']!;
    expect(newGuide.placement, SpotlightGuidePlacement.right);
    expect(newGuide.anchorDirection, SpotlightGuideDirection.left);
    expect(newGuide.targetRect.left, moreOrLessEquals(268, epsilon: 0.5));
    expect(newGuide.targetRect.top, moreOrLessEquals(242, epsilon: 0.5));
    expect(newGuide.targetRect.right, moreOrLessEquals(364, epsilon: 0.5));
    expect(newGuide.targetRect.bottom, moreOrLessEquals(316, epsilon: 0.5));
    expect(
      newGuide.hintRect.left - newGuide.targetRect.right,
      moreOrLessEquals(24, epsilon: 0.5),
    );
    expect(newGuide.hintRect.width, moreOrLessEquals(140, epsilon: 0.5));
  });

  testWidgets(
    'pointer configuration can be swapped while the hint is visible',
    (tester) async {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 260,
            top: 190,
            width: 80,
            height: 48,
          ),
          steps: <SpotlightGuideStep>[
            _pointerStep(
              label: 'pointer-old',
              contexts: contexts,
              placement: SpotlightGuidePlacement.bottom,
              pointer: const SpotlightGuidePointer(
                size: Size(24, 24),
                child: SizedBox(
                  key: ValueKey<String>('pointer-old-child'),
                  width: 24,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
            ),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('pointer-old-child')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 260,
            top: 190,
            width: 80,
            height: 48,
          ),
          steps: <SpotlightGuideStep>[
            _pointerStep(
              label: 'pointer-new',
              contexts: contexts,
              placement: SpotlightGuidePlacement.bottom,
              gap: 18,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.center(
                6,
              ),
              pointer: const SpotlightGuidePointer(
                size: Size(40, 32),
                targetGap: 5,
                pointerAnchorPosition: SpotlightGuideAnchorPosition.center(),
                child: SizedBox(
                  key: ValueKey<String>('pointer-new-child'),
                  width: 40,
                  height: 32,
                  child: ColoredBox(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      );
      await _pumpHotReloadGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('pointer-old-child')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('pointer-new-child')),
        findsOneWidget,
      );
      final SpotlightGuideStepContext guide = contexts['pointer-new']!;
      final Rect pointerRect = tester.getRect(
        find.byKey(const ValueKey<String>('pointer-new-child')),
      );
      expect(
        pointerRect.top,
        moreOrLessEquals(guide.targetRect.bottom + 5, epsilon: 0.5),
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
      );
      expect(guide.hintRect.bottom, greaterThan(pointerRect.bottom));
    },
  );

  testWidgets(
    'visible reassemble keeps pointer hint visible while visualOffset changes',
    (tester) async {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      const ValueKey<String> pointerKey = ValueKey<String>(
        'stable-pointer-child',
      );

      Widget buildApp({required bool withVisualOffset}) {
        return guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 260,
            top: 190,
            width: 80,
            height: 48,
          ),
          steps: <SpotlightGuideStep>[
            _pointerStep(
              label: 'stable-pointer',
              contexts: contexts,
              placement: SpotlightGuidePlacement.verticalAuto,
              pointer: SpotlightGuidePointer(
                size: const Size(88, 42),
                targetGap: 4,
                visualOffset: withVisualOffset
                    ? const SpotlightGuidePointerOffset.directional(
                        end: 3,
                        up: 2,
                      )
                    : SpotlightGuidePointerOffset.zero,
                layer: SpotlightGuidePointerLayer.aboveBubble,
                bubbleSide: SpotlightGuideBubbleSide.bottom,
                child: const SizedBox(
                  key: pointerKey,
                  width: 88,
                  height: 42,
                  child: ColoredBox(color: Colors.orange),
                ),
              ),
            ),
          ],
        );
      }

      await tester.pumpWidget(buildApp(withVisualOffset: true));
      await _pumpHotReloadGuide(tester);
      expect(find.byKey(pointerKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('stable-pointer')).hitTestable(),
        findsOneWidget,
      );

      final dynamic portalState = tester.state(
        find.byType(SpotlightGuidePortal),
      );
      portalState.reassemble();
      await tester.pump();
      expect(find.byKey(pointerKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('stable-pointer')).hitTestable(),
        findsOneWidget,
      );

      await tester.pumpWidget(buildApp(withVisualOffset: false));
      await tester.pump();
      expect(find.byKey(pointerKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('stable-pointer')).hitTestable(),
        findsOneWidget,
      );

      await _pumpHotReloadGuide(tester);
      final SpotlightGuideStepContext guide = contexts['stable-pointer']!;
      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      expect(
        pointerRect.top,
        moreOrLessEquals(guide.targetRect.bottom + 4, epsilon: 0.5),
      );
    },
  );

  testWidgets(
    'visible reassemble keeps current step visible when later steps are removed',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      List<SpotlightGuideStep> buildSteps({required int total}) {
        return <SpotlightGuideStep>[
          _step('stable-total-1', contexts: contexts),
          _step('stable-total-2', contexts: contexts),
          _pointerStep(
            label: 'stable-total-3',
            contexts: contexts,
            placement: SpotlightGuidePlacement.verticalAuto,
            pointer: const SpotlightGuidePointer(
              size: Size(88, 42),
              targetGap: 4,
              visualOffset: SpotlightGuidePointerOffset.directional(
                end: 3,
                up: 2,
              ),
              layer: SpotlightGuidePointerLayer.aboveBubble,
              bubbleSide: SpotlightGuideBubbleSide.bottom,
              child: SizedBox(
                key: ValueKey<String>('stable-total-pointer'),
                width: 88,
                height: 42,
                child: ColoredBox(color: Colors.orange),
              ),
            ),
          ),
          _step('stable-total-4', contexts: contexts),
          _step('stable-total-5', contexts: contexts),
          if (total == 6) _step('stable-total-6', contexts: contexts),
        ];
      }

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          steps: buildSteps(total: 6),
        ),
      );
      controller.showPortal(index: 2);
      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('stable-total-3')).hitTestable(),
        findsOneWidget,
      );
      expect(controller.index, 2);
      expect(controller.total, 6);
      expect(contexts['stable-total-3']?.total, 6);

      final dynamic portalState = tester.state(
        find.byType(SpotlightGuidePortal),
      );
      portalState.reassemble();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('stable-total-3')).hitTestable(),
        findsOneWidget,
      );

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          steps: buildSteps(total: 5),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('stable-total-3')).hitTestable(),
        findsOneWidget,
      );
      expect(controller.index, 2);
      expect(controller.total, 5);

      await _pumpHotReloadGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('stable-total-3')).hitTestable(),
        findsOneWidget,
      );
      expect(contexts['stable-total-3']?.total, 5);
    },
  );

  testWidgets('visible guide filters a removed future target from the total', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    bool showSixthTarget = true;

    Widget buildChild() {
      return Stack(
        children: <Widget>[
          const Positioned(
            left: 80,
            top: 120,
            child: SpotlightGuideTarget(
              id: 'stable-target',
              child: SizedBox(
                width: 96,
                height: 44,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
          if (showSixthTarget)
            const Positioned(
              left: 260,
              top: 420,
              child: SpotlightGuideTarget(
                id: 'future-target',
                child: SizedBox(
                  width: 92,
                  height: 48,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
        ],
      );
    }

    List<SpotlightGuideStep> buildSteps() {
      return <SpotlightGuideStep>[
        _step('filtered-total-1', targetId: 'stable-target'),
        _step('filtered-total-2', targetId: 'stable-target'),
        _step(
          'filtered-total-3',
          targetId: 'stable-target',
          contexts: contexts,
        ),
        _step('filtered-total-4', targetId: 'stable-target'),
        _step('filtered-total-5', targetId: 'stable-target'),
        _step('filtered-total-6', targetId: 'future-target'),
      ];
    }

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: buildSteps(),
        child: buildChild(),
      ),
    );
    controller.showPortal(index: 2);
    await _pumpHotReloadGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('filtered-total-3')).hitTestable(),
      findsOneWidget,
    );
    expect(controller.index, 2);
    expect(controller.total, 6);
    expect(contexts['filtered-total-3']?.total, 6);

    showSixthTarget = false;
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: buildSteps(),
        child: buildChild(),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('filtered-total-3')).hitTestable(),
      findsOneWidget,
    );
    expect(controller.index, 2);
    expect(controller.total, 5);

    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('filtered-total-3')).hitTestable(),
      findsOneWidget,
    );
    expect(contexts['filtered-total-3']?.total, 5);
  });

  testWidgets('target geometry and target id changes are picked up mid-guide', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    Widget buildChild({
      required String id,
      required double left,
      required double top,
      required double width,
      required double height,
    }) {
      return singleTargetStack(
        id: id,
        left: left,
        top: top,
        width: width,
        height: height,
      );
    }

    await tester.pumpWidget(
      guideApp(
        child: buildChild(id: 'a', left: 40, top: 60, width: 80, height: 40),
        steps: <SpotlightGuideStep>[
          _step('target-old', targetId: 'a', contexts: contexts),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);
    expect(contexts['target-old']?.targetRect.left, moreOrLessEquals(40));
    await tester.pumpWidget(
      guideApp(
        child: buildChild(id: 'b', left: 300, top: 360, width: 120, height: 70),
        steps: <SpotlightGuideStep>[
          _step('target-new', targetId: 'b', contexts: contexts),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(find.byKey(const ValueKey<String>('target-old')), findsNothing);
    expect(find.byKey(const ValueKey<String>('target-new')), findsOneWidget);
    final SpotlightGuideStepContext guide = contexts['target-new']!;
    expect(guide.targetRect.left, moreOrLessEquals(300, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(360, epsilon: 0.5));
    expect(guide.targetRect.width, moreOrLessEquals(120, epsilon: 0.5));
    expect(guide.targetRect.height, moreOrLessEquals(70, epsilon: 0.5));
  });

  testWidgets('step list shrink clamps active index after rebuild', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('shrink-0', contexts: contexts),
          _step('shrink-1', targetId: 'b', contexts: contexts),
          _step('shrink-2', contexts: contexts),
        ],
      ),
    );

    controller.showPortal(index: 2);
    await _pumpHotReloadGuide(tester);
    expect(find.byKey(const ValueKey<String>('shrink-2')), findsOneWidget);
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('shrink-only', targetId: 'b', contexts: contexts),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(find.byKey(const ValueKey<String>('shrink-2')), findsNothing);
    expect(find.byKey(const ValueKey<String>('shrink-only')), findsOneWidget);
    expect(controller.index, 0);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
    expect(contexts['shrink-only']?.index, 0);
    expect(contexts['shrink-only']?.total, 1);
  });

  testWidgets('runtime controller steps are not replaced by portal rebuilds', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[_step('portal-before-hot-reload')],
      ),
    );

    controller.showSteps(<SpotlightGuideStep>[
      _step('runtime-before-hot-reload'),
    ]);
    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('runtime-before-hot-reload')),
      findsOneWidget,
    );
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          _step('portal-after-hot-reload', targetId: 'b'),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('runtime-before-hot-reload')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('portal-after-hot-reload')),
      findsNothing,
    );

    controller.showPortal();
    await _pumpHotReloadGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('runtime-before-hot-reload')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('portal-after-hot-reload')),
      findsOneWidget,
    );
  });

  testWidgets('barrier and dismiss behavior update while active', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        barrier: const SpotlightGuideBarrierStyle(blurSigma: 0),
        barrierDismissBehavior: SpotlightGuideDismissBehavior.disabled,
        steps: <SpotlightGuideStep>[_step('barrier-hot-reload')],
      ),
    );
    controller.showPortal();
    await _pumpHotReloadGuide(tester);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tapAt(const Offset(760, 560));
    await _pumpHotReloadGuide(tester);
    expect(controller.isShowing, isTrue);
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
        barrierDismissBehavior: SpotlightGuideDismissBehavior.anytime,
        steps: <SpotlightGuideStep>[_step('barrier-hot-reload')],
      ),
    );
    await _pumpHotReloadGuide(tester);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tapAt(const Offset(760, 560));
    await _pumpHotReloadGuide(tester);
    expect(controller.isShowing, isFalse);
  });

  testWidgets('semantic placement and anchor resolve again after RTL rebuild', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.ltr,
        child: singleTargetStack(
          id: 'a',
          left: 280,
          top: 260,
          width: 100,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          _step(
            'rtl-old',
            placement: SpotlightGuidePlacement.start,
            targetAnchorPosition: const SpotlightGuideAnchorPosition.start(10),
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);
    final SpotlightGuideStepContext ltr = contexts['rtl-old']!;
    expect(ltr.placement, SpotlightGuidePlacement.left);
    expect(ltr.anchorDirection, SpotlightGuideDirection.right);
    expect(ltr.targetAnchorPoint.dy, moreOrLessEquals(ltr.targetRect.top + 10));
    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
        child: singleTargetStack(
          id: 'a',
          left: 280,
          top: 260,
          width: 100,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          _step(
            'rtl-new',
            placement: SpotlightGuidePlacement.start,
            targetAnchorPosition: const SpotlightGuideAnchorPosition.start(10),
            contexts: contexts,
          ),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(find.byKey(const ValueKey<String>('rtl-old')), findsNothing);
    expect(find.byKey(const ValueKey<String>('rtl-new')), findsOneWidget);
    final SpotlightGuideStepContext rtl = contexts['rtl-new']!;
    expect(rtl.placement, SpotlightGuidePlacement.right);
    expect(rtl.anchorDirection, SpotlightGuideDirection.left);
    expect(rtl.targetAnchorPoint.dy, moreOrLessEquals(rtl.targetRect.top + 10));
  });

  testWidgets('missing target behavior updates from wait to skip mid-flow', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
        child: optionalTargetStack(
          showTarget: true,
          id: 'available',
          left: 220,
          top: 240,
          width: 90,
          height: 44,
        ),
        steps: <SpotlightGuideStep>[
          _step('missing-wait', targetId: 'missing'),
          _step('available-after-skip', targetId: 'available'),
        ],
      ),
    );
    controller.showPortal();
    await _pumpHotReloadGuide(tester);
    expect(controller.isShowing, isTrue);
    expect(find.byKey(const ValueKey<String>('missing-wait')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('available-after-skip')),
      findsNothing,
    );
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
        child: optionalTargetStack(
          showTarget: true,
          id: 'available',
          left: 220,
          top: 240,
          width: 90,
          height: 44,
        ),
        steps: <SpotlightGuideStep>[
          _step('missing-wait', targetId: 'missing'),
          _step('available-after-skip', targetId: 'available'),
        ],
      ),
    );
    await _pumpHotReloadGuide(tester);

    expect(find.byKey(const ValueKey<String>('missing-wait')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('available-after-skip')),
      findsOneWidget,
    );
    expect(controller.index, 0);
    expect(controller.total, 1);
  });
}

Future<void> _pumpHotReloadGuide(WidgetTester tester) async {
  await pumpGuideFrames(tester, count: 24);
}

SpotlightGuideStep _step(
  String label, {
  Object targetId = 'a',
  SpotlightGuidePlacement placement = SpotlightGuidePlacement.verticalAuto,
  SpotlightGuideTargetDecoration targetDecoration =
      const SpotlightGuideTargetDecoration(padding: EdgeInsets.zero),
  SpotlightGuideAnchorPosition targetAnchorPosition =
      const SpotlightGuideAnchorPosition.center(),
  double gap = 8,
  EdgeInsetsGeometry? margin,
  double? minWidth,
  double? maxWidth,
  Map<String, SpotlightGuideStepContext>? contexts,
}) {
  return SpotlightGuideStep.item(
    SpotlightGuideStepItem(
      targetId: targetId,
      placement: placement,
      targetDecoration: targetDecoration,
      targetAnchorPosition: targetAnchorPosition,
      gap: gap,
      margin: margin,
      minWidth: minWidth,
      maxWidth: maxWidth,
      hintBuilder: sizedHint(label, 80, 32, contexts),
    ),
  );
}

SpotlightGuideStep _pointerStep({
  required String label,
  required SpotlightGuidePointer pointer,
  required Map<String, SpotlightGuideStepContext> contexts,
  SpotlightGuidePlacement placement = SpotlightGuidePlacement.bottom,
  SpotlightGuideAnchorPosition targetAnchorPosition =
      const SpotlightGuideAnchorPosition.center(),
  double gap = 8,
}) {
  return SpotlightGuideStep.item(
    SpotlightGuideStepItem(
      targetId: 'a',
      placement: placement,
      targetDecoration: const SpotlightGuideTargetDecoration(
        padding: EdgeInsets.zero,
      ),
      targetAnchorPosition: targetAnchorPosition,
      gap: gap,
      pointer: pointer,
      hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
        contexts[label] = guide;
        return SpotlightGuideBubbleHint(
          guide: guide,
          child: SizedBox(
            width: 90,
            height: 42,
            child: Center(child: Text(label, key: ValueKey<String>(label))),
          ),
        );
      },
    ),
  );
}
