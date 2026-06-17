import 'dart:async';

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Reveal and scroll preparation tests.
///
/// Run this file when changing [SpotlightGuideRevealOptions],
/// [SpotlightGuideAutoScrollOptions], [SpotlightGuideStep.onReveal],
/// [SpotlightGuideStepItem.onReveal], default `Scrollable.ensureVisible`
/// behavior, lazy-list handling, or same-step multi-item auto scroll.
void main() {
  testWidgets('default reveal scrolls an already built target into view', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 1050,
                  child: SpotlightGuideTarget(
                    id: 'scroll-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'scroll-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              placement: SpotlightGuidePlacement.top,
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
                alignment: 1,
              ),
              hintBuilder: hint('scroll-reveal', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['scroll-reveal']!;
    expect(scrollController.offset, greaterThan(0));
    expect(find.byKey(const ValueKey<String>('scroll-reveal')), findsOneWidget);
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets('default reveal does not scroll a fully visible target', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 300,
                  child: SpotlightGuideTarget(
                    id: 'visible-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'visible-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
                alignment: 0.5,
              ),
              hintBuilder: hint('visible-target'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey<String>('visible-target')),
      findsOneWidget,
    );
  });

  testWidgets('default reveal reserves item-level pointer space', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 330,
                  child: SpotlightGuideTarget(
                    id: 'pointer-space-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'pointer-space-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              placement: SpotlightGuidePlacement.bottom,
              gap: 24,
              pointer: const SpotlightGuidePointer(
                size: Size(56, 96),
                targetGap: 12,
                child: SizedBox(
                  key: ValueKey<String>('item-level-pointer'),
                  width: 56,
                  height: 96,
                ),
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
                alignment: 0.5,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer-space'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 180, height: 120),
                    );
                  },
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['pointer-space']!;
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('item-level-pointer')),
      findsOneWidget,
    );
    expect(guide.pointer, isNotNull);
    expect(
      guide.hintRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height - guide.margin.bottom + 0.5),
    );
  });

  testWidgets('always reveal policy can realign a visible target', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 300,
                  child: SpotlightGuideTarget(
                    id: 'always-visible-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'always-visible-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                scrollPolicy: SpotlightGuideRevealScrollPolicy.always,
                duration: Duration.zero,
                alignment: 0.5,
              ),
              hintBuilder: hint('always-visible-target'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('always-visible-target')),
      findsOneWidget,
    );
  });

  testWidgets('large target group does not scroll when anchor is visible', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: horizontalGroupedTargets(
          controller: scrollController,
          contentWidth: 1400,
          groupId: 'wide-summary',
          anchorId: 'wide-summary-anchor',
          groupWidth: 1200,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>['wide-summary', 'wide-summary-anchor'],
              anchorTargetId: 'wide-summary-anchor',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              hintBuilder: hint('wide-summary-hint', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['wide-summary-hint']!;
    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey<String>('wide-summary-hint')),
      findsOneWidget,
    );
    expect(guide.targetRect.left, moreOrLessEquals(300, epsilon: 0.5));
    expect(guide.targetRect.right, moreOrLessEquals(420, epsilon: 0.5));
    expect(guide.targetRects.length, 2);
  });

  testWidgets('large repeated target group can reveal by anchorId', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: 250,
    );
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1400,
            height: 600,
            child: Stack(
              children: const <Widget>[
                Positioned(
                  left: 0,
                  top: 120,
                  child: SpotlightGuideTarget(
                    id: 'repeated-summary-card',
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
                Positioned(
                  left: 320,
                  top: 120,
                  child: SpotlightGuideTarget(
                    id: 'repeated-summary-card',
                    anchorId: 'selected-summary-card',
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
                Positioned(
                  left: 1000,
                  top: 120,
                  child: SpotlightGuideTarget(
                    id: 'repeated-summary-card',
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: ColoredBox(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'repeated-summary-card',
              anchorTargetId: 'selected-summary-card',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              hintBuilder: hint('anchor-id-reveal', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['anchor-id-reveal']!;
    expect(scrollController.offset, 250);
    expect(
      find.byKey(const ValueKey<String>('anchor-id-reveal')),
      findsOneWidget,
    );
    expect(guide.targetRects.length, 2);
    expect(guide.targetRect.left, moreOrLessEquals(70, epsilon: 0.5));
    expect(guide.targetRect.width, moreOrLessEquals(80, epsilon: 0.5));
  });

  testWidgets(
    'default target policy scrolls a compact partially hidden group',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController(
        initialScrollOffset: 100,
      );
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: horizontalGroupedTargets(
            controller: scrollController,
            groupId: 'default-policy-summary',
            anchorId: 'default-policy-summary-anchor',
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetIds: const <Object>[
                  'default-policy-summary',
                  'default-policy-summary-anchor',
                ],
                anchorTargetId: 'default-policy-summary-anchor',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: hint('default-policy-summary-hint'),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      expect(scrollController.offset, lessThan(100));
      expect(
        find.byKey(const ValueKey<String>('default-policy-summary-hint')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'highlighted area target policy scrolls a partially hidden group',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController(
        initialScrollOffset: 100,
      );
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: horizontalGroupedTargets(
            controller: scrollController,
            groupId: 'policy-summary',
            anchorId: 'policy-summary-anchor',
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetIds: const <Object>[
                  'policy-summary',
                  'policy-summary-anchor',
                ],
                anchorTargetId: 'policy-summary-anchor',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  targetPolicy:
                      SpotlightGuideRevealTargetPolicy.highlightedArea,
                  duration: Duration.zero,
                ),
                hintBuilder: hint('policy-summary-hint'),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      expect(scrollController.offset, lessThan(100));
      expect(
        find.byKey(const ValueKey<String>('policy-summary-hint')),
        findsOneWidget,
      );
    },
  );

  testWidgets('anchor target policy avoids scrolling a visible anchor', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: 100,
    );
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: horizontalGroupedTargets(
          controller: scrollController,
          groupId: 'anchor-policy-summary',
          anchorId: 'anchor-policy-summary-anchor',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>[
                'anchor-policy-summary',
                'anchor-policy-summary-anchor',
              ],
              anchorTargetId: 'anchor-policy-summary-anchor',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                targetPolicy:
                    SpotlightGuideRevealTargetPolicy.anchorTarget,
                duration: Duration.zero,
              ),
              hintBuilder: hint('anchor-policy-summary-hint'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, 100);
    expect(
      find.byKey(const ValueKey<String>('anchor-policy-summary-hint')),
      findsOneWidget,
    );
  });

  testWidgets(
    'unavailable anchor target falls back to highlighted area reveal',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController(
        initialScrollOffset: 100,
      );
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: horizontalGroupedTargets(
            controller: scrollController,
            groupId: 'fallback-policy-summary',
            anchorId: 'fallback-policy-summary-anchor',
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetIds: const <Object>[
                  'fallback-policy-summary',
                  'fallback-policy-summary-anchor',
                ],
                anchorTargetId: 'not-in-this-highlighted-group',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: hint('fallback-policy-summary-hint'),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      expect(scrollController.offset, lessThan(100));
      expect(
        find.byKey(const ValueKey<String>('fallback-policy-summary-hint')),
        findsOneWidget,
      );
    },
  );

  testWidgets('default reveal also works for targetKey targets', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final GlobalKey targetKey = GlobalKey();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 1050,
                  child: SizedBox(
                    key: targetKey,
                    width: 100,
                    height: 50,
                    child: const ColoredBox(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetKey: targetKey,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              placement: SpotlightGuidePlacement.top,
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
                alignment: 1,
              ),
              hintBuilder: hint('key-scroll-reveal', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['key-scroll-reveal']!;
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('key-scroll-reveal')),
      findsOneWidget,
    );
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets('targetIds reveal ends on anchorTargetId', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: const SizedBox(
            width: 1300,
            height: 600,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 220,
                  child: SpotlightGuideTarget(
                    id: 'summary-area',
                    child: SizedBox(
                      width: 220,
                      height: 80,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
                Positioned(
                  left: 1120,
                  top: 220,
                  child: SpotlightGuideTarget(
                    id: 'summary-cost',
                    child: SizedBox(
                      width: 90,
                      height: 80,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              // Anchor id is intentionally first to verify reveal still ends
              // on it after revealing the non-anchor target.
              targetIds: const <Object>['summary-cost', 'summary-area'],
              anchorTargetId: 'summary-cost',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              placement: SpotlightGuidePlacement.top,
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration(milliseconds: 250),
                alignment: 0.5,
              ),
              hintBuilder: hint('target-ids-anchor-reveal', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide =
        contexts['target-ids-anchor-reveal']!;
    expect(scrollController.offset, greaterThan(0));
    expect(guide.targetRect.left, greaterThanOrEqualTo(0));
    expect(guide.targetRect.right, lessThanOrEqualTo(guide.overlaySize.width));
    expect(
      find.byKey(const ValueKey<String>('target-ids-anchor-reveal')),
      findsOneWidget,
      reason:
          'targetIds reveal should keep the hint visible after animated '
          'scrolling moves the anchor target',
    );
  });

  testWidgets('default reveal works with every fixed placement', (
    tester,
  ) async {
    final List<RevealPlacementCase> cases = <RevealPlacementCase>[
      const RevealPlacementCase(
        label: 'reveal-top',
        placement: SpotlightGuidePlacement.top,
        scrollDirection: Axis.vertical,
      ),
      const RevealPlacementCase(
        label: 'reveal-bottom',
        placement: SpotlightGuidePlacement.bottom,
        scrollDirection: Axis.vertical,
      ),
      const RevealPlacementCase(
        label: 'reveal-left',
        placement: SpotlightGuidePlacement.left,
        scrollDirection: Axis.horizontal,
      ),
      const RevealPlacementCase(
        label: 'reveal-right',
        placement: SpotlightGuidePlacement.right,
        scrollDirection: Axis.horizontal,
      ),
    ];

    for (final RevealPlacementCase placementCase in cases) {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(placementCase.label),
          controller: controller,
          child: singleScrollableTarget(
            id: placementCase.label,
            controller: scrollController,
            scrollDirection: placementCase.scrollDirection,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: placementCase.label,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                placement: placementCase.placement,
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: hint(placementCase.label, contexts),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[placementCase.label]!;
      expect(scrollController.offset, greaterThan(0));
      expect(guide.placement, placementCase.placement);
      expect(guide.targetRect.left, greaterThanOrEqualTo(0));
      expect(guide.targetRect.top, greaterThanOrEqualTo(0));
      expect(
        guide.targetRect.right,
        lessThanOrEqualTo(guide.overlaySize.width),
      );
      expect(
        guide.targetRect.bottom,
        lessThanOrEqualTo(guide.overlaySize.height),
      );
    }
  });

  testWidgets(
    'default reveal realigns a visible target when fixed hint needs space',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 1200,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 300,
                    child: SpotlightGuideTarget(
                      id: 'visible-top-target',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'visible-top-target',
                placement: SpotlightGuidePlacement.top,
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: sizedHint('visible-top-hint', 180, 140, contexts),
              ),
            ),
          ],
        ),
      );

      scrollController.jumpTo(260);
      await tester.pump();

      controller.reset();
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['visible-top-hint']!;
      expect(scrollController.offset, lessThan(260));
      expect(guide.placement, SpotlightGuidePlacement.top);
      expect(guide.hintRect.top, greaterThanOrEqualTo(guide.margin.top));
      expect(guide.hintRect.bottom, lessThanOrEqualTo(guide.targetRect.top));
    },
  );

  testWidgets(
    'previous realigns visible target when the previous hint needs space',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 1200,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 300,
                    child: SpotlightGuideTarget(
                      id: 'previous-top-target',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    top: 780,
                    child: SpotlightGuideTarget(
                      id: 'later-target',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'previous-top-target',
                placement: SpotlightGuidePlacement.top,
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: sizedHint('previous-top-hint', 180, 140, contexts),
              ),
            ),
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'later-target',
                placement: SpotlightGuidePlacement.bottom,
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: hint('later-hint', contexts),
              ),
            ),
          ],
        ),
      );

      controller.showPortal(index: 1);
      await pumpGuide(tester);
      scrollController.jumpTo(260);
      await tester.pump();

      controller.previous();
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['previous-top-hint']!;
      expect(scrollController.offset, lessThan(260));
      expect(guide.placement, SpotlightGuidePlacement.top);
      expect(guide.hintRect.top, greaterThanOrEqualTo(guide.margin.top));
      expect(guide.hintRect.bottom, lessThanOrEqualTo(guide.targetRect.top));
    },
  );

  testWidgets(
    'default reveal handles nested scrollables before showing the hint',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController outerController = ScrollController();
      final ScrollController innerController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(outerController.dispose);
      addTearDown(innerController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: outerController,
            child: SizedBox(
              height: 1200,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 260),
                  SizedBox(
                    height: 220,
                    child: SingleChildScrollView(
                      controller: innerController,
                      child: const SizedBox(
                        height: 900,
                        child: Stack(
                          children: <Widget>[
                            Positioned(
                              left: 40,
                              top: 300,
                              child: SpotlightGuideTarget(
                                id: 'nested-visible-target',
                                child: SizedBox(
                                  width: 100,
                                  height: 50,
                                  child: ColoredBox(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 720),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'nested-visible-target',
                placement: SpotlightGuidePlacement.top,
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                ),
                hintBuilder: sizedHint('nested-hint', 180, 140, contexts),
              ),
            ),
          ],
        ),
      );

      outerController.jumpTo(220);
      innerController.jumpTo(260);
      await tester.pump();

      controller.reset();
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['nested-hint']!;
      expect(innerController.offset, lessThan(260));
      expect(guide.hintRect.top, greaterThanOrEqualTo(guide.margin.top));
      expect(guide.hintRect.bottom, lessThanOrEqualTo(guide.targetRect.top));
    },
  );

  testWidgets('same-step scroll reveals hidden vertical items', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'vertical-first',
          secondId: 'vertical-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration(milliseconds: 120),
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'vertical-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('vertical-first', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'vertical-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('vertical-second', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 12; i++) {
      await tester.pump();
    }
    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey<String>('vertical-first')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('vertical-second')), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    final SpotlightGuideStepContext guide = contexts['vertical-second']!;
    expect(scrollController.offset, greaterThan(0));
    expect(find.byKey(const ValueKey<String>('vertical-first')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('vertical-second')),
      findsOneWidget,
    );
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets(
    'same-step scroll defers a later item onReveal until its turn',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      int secondRevealCount = 0;
      double? scrollOffsetWhenRevealed;
      bool? hadTargetBeforeReveal;
      addTearDown(scrollController.dispose);

      // Both targets are mounted (a same-step overlay needs every target
      // present), but the second one is far down and offscreen.
      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 1400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 40,
                    child: SpotlightGuideTarget(
                      id: 'defer-first',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    top: 1150,
                    child: SpotlightGuideTarget(
                      id: 'defer-second',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              // Default centered alignment keeps the near-top first target at
              // offset 0 (it cannot scroll above the top), which isolates the
              // later scroll to the deferred second item.
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: const SpotlightGuideAutoScrollOptions(
                interval: Duration(milliseconds: 120),
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'defer-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('defer-first', contexts),
                ),
                SpotlightGuideStepItem(
                  targetId: 'defer-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  onReveal: (SpotlightGuideRevealContext context) {
                    secondRevealCount++;
                    hadTargetBeforeReveal = context.hasTargetContext;
                    scrollOffsetWhenRevealed = scrollController.offset;
                  },
                  hintBuilder: hint('defer-second', contexts),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      // Pump zero-duration frames so the first hint measures and renders
      // without advancing the fake clock (which would fire the 120ms timer).
      for (int i = 0; i < 12; i++) {
        await tester.pump();
      }

      // The first item is shown immediately. The second item's onReveal is
      // deferred, so it has not run and nothing has scrolled away from the
      // first hint yet.
      expect(find.byKey(const ValueKey<String>('defer-first')), findsOneWidget);
      expect(secondRevealCount, 0);
      expect(scrollController.offset, 0);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      // After the interval the deferred onReveal runs once, while the page is
      // still at the first item (offset 0), and then the default reveal scrolls
      // the second item into view.
      expect(secondRevealCount, 1);
      expect(hadTargetBeforeReveal, isTrue);
      expect(scrollOffsetWhenRevealed, 0);
      expect(scrollController.offset, greaterThan(0));
      final SpotlightGuideStepContext guide = contexts['defer-second']!;
      expect(guide.targetRect.top, greaterThanOrEqualTo(0));
      expect(
        guide.targetRect.bottom,
        lessThanOrEqualTo(guide.overlaySize.height),
      );
    },
  );

  testWidgets('same-step hides hints while a lazy later target is revealed', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    int secondRevealCount = 0;
    bool? hadTargetBeforeReveal;
    addTearDown(scrollController.dispose);

    // The first target is in a fixed header (always mounted); the second is a
    // lazy list row that is not built until its onReveal scrolls to it.
    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: Column(
          children: <Widget>[
            const SpotlightGuideTarget(
              id: 'partial-first',
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ColoredBox(color: Colors.red),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemExtent: 50,
                itemCount: 80,
                itemBuilder: (BuildContext context, int index) {
                  final Widget row = SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ColoredBox(
                      color: index.isEven ? Colors.blue : Colors.green,
                    ),
                  );
                  if (index == 60) {
                    return SpotlightGuideTarget(
                      id: 'partial-second',
                      child: row,
                    );
                  }
                  return row;
                },
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration(milliseconds: 120),
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'partial-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('partial-first', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'partial-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                onReveal: (SpotlightGuideRevealContext context) async {
                  secondRevealCount++;
                  hadTargetBeforeReveal = context.hasTargetContext;
                  await context.scrollToIndex(
                    controller: scrollController,
                    index: 60,
                    itemExtent: 50,
                    alignment: 0.1,
                    duration: const Duration(milliseconds: 450),
                    settleFrames: 2,
                  );
                },
                hintBuilder: hint('partial-second', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 12; i++) {
      await tester.pump();
    }

    // The first hint renders even though the second target is not built yet.
    expect(find.byKey(const ValueKey<String>('partial-first')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('partial-second')), findsNothing);
    expect(secondRevealCount, 0);
    // The step total is still reported as 2 even while only one item renders.
    expect(contexts['partial-first']!.itemTotal, 2);

    await tester.pump(const Duration(milliseconds: 120));
    for (int i = 0; i < 8; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 120));

    expect(secondRevealCount, 1);
    expect(hadTargetBeforeReveal, isFalse);
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('partial-first')),
      findsNothing,
      reason:
          'the outgoing hint should be hidden while a lazy later target '
          'is being revealed',
    );
    expect(
      find.byKey(const ValueKey<String>('partial-second')),
      findsNothing,
      reason: 'the lazy hint should wait until reveal scrolling settles',
    );

    await tester.pumpAndSettle();

    // After the interval the lazy target is built and revealed; focus moves
    // to the later item instead of keeping the outgoing hint on screen.
    expect(secondRevealCount, 1);
    expect(hadTargetBeforeReveal, isFalse);
    expect(scrollController.offset, greaterThan(0));
    expect(find.byKey(const ValueKey<String>('partial-first')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('partial-second')),
      findsOneWidget,
    );
  });

  testWidgets('same-step scroll refreshes after manual item reveal', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'manual-first',
          secondId: 'manual-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration(milliseconds: 120),
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'manual-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('manual-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'manual-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  enabled: false,
                ),
                onReveal: (SpotlightGuideRevealContext context) {
                  scrollController.jumpTo(900);
                },
                hintBuilder: hint('manual-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 12; i++) {
      await tester.pump();
    }

    expect(find.byKey(const ValueKey<String>('manual-first')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('manual-second')), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('manual-first')), findsNothing);
    expect(find.byKey(const ValueKey<String>('manual-second')), findsOneWidget);
  });

  testWidgets('same-step scroll shows only one hint at a time', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'focus-first',
          secondId: 'focus-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration(milliseconds: 120),
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'focus-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('focus-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'focus-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('focus-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    bool sawBothHints = false;
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find
              .byKey(const ValueKey<String>('focus-first'))
              .evaluate()
              .isNotEmpty &&
          find
              .byKey(const ValueKey<String>('focus-second'))
              .evaluate()
              .isNotEmpty) {
        sawBothHints = true;
      }
    }
    await tester.pumpAndSettle();

    expect(sawBothHints, isFalse);
    expect(scrollController.offset, greaterThan(0));
    expect(find.byKey(const ValueKey<String>('focus-first')), findsNothing);
    expect(find.byKey(const ValueKey<String>('focus-second')), findsOneWidget);
  });

  testWidgets('onItemChanged reports focused item indices', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<int> focusedIndices = <int>[];
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'callback-first',
          secondId: 'callback-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              interval: const Duration(milliseconds: 120),
              onItemChanged:
                  (SpotlightGuideAutoScrollContext ctx) {
                    recordAutoScrollIndex(focusedIndices, ctx);
                  },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'callback-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('callback-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'callback-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('callback-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 12; i++) {
      await tester.pump();
    }
    expect(focusedIndices, <int>[0]);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(focusedIndices, <int>[0, 1]);
    expect(focusedIndices.toSet().length, 2);
  });

  testWidgets(
    'onItemChanged does not run when every item is already visible',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final List<int> focusedIndices = <int>[];

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                onItemChanged:
                    (SpotlightGuideAutoScrollContext ctx) {
                      recordAutoScrollIndex(focusedIndices, ctx);
                    },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'flush-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('flush-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'flush-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('flush-second'),
                ),
              ],
            ),
          ],
          child: const Stack(
            children: <Widget>[
              Positioned(
                left: 40,
                top: 40,
                child: SpotlightGuideTarget(
                  id: 'flush-first',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 560,
                child: SpotlightGuideTarget(
                  id: 'flush-second',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      expect(focusedIndices, isEmpty);
    },
  );

  testWidgets('same-step scroll reveals hidden horizontal items', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          firstId: 'horizontal-first',
          secondId: 'horizontal-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration(milliseconds: 120),
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'horizontal-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                placement: SpotlightGuidePlacement.right,
                hintBuilder: hint('horizontal-first', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'horizontal-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                placement: SpotlightGuidePlacement.left,
                hintBuilder: hint('horizontal-second', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 12; i++) {
      await tester.pump();
    }
    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey<String>('horizontal-first')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('horizontal-second')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    final SpotlightGuideStepContext guide = contexts['horizontal-second']!;
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('horizontal-first')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('horizontal-second')),
      findsOneWidget,
    );
    expect(guide.targetRect.left, greaterThanOrEqualTo(0));
    expect(guide.targetRect.right, lessThanOrEqualTo(guide.overlaySize.width));
  });

  testWidgets(
    'item reveal can build a lazy list target before default reveal',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      int revealCount = 0;
      bool? hadTargetBeforeReveal;
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: ListView.builder(
            controller: scrollController,
            itemExtent: 50,
            itemCount: 80,
            itemBuilder: (BuildContext context, int index) {
              final Widget row = SizedBox(
                width: double.infinity,
                height: 50,
                child: ColoredBox(
                  color: index.isEven ? Colors.red : Colors.blue,
                ),
              );
              if (index == 60) {
                return SpotlightGuideTarget(id: 'lazy-target', child: row);
              }
              return row;
            },
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'lazy-target',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                  alignment: 0,
                ),
                onReveal: (SpotlightGuideRevealContext context) {
                  revealCount++;
                  hadTargetBeforeReveal = context.hasTargetContext;
                  scrollController.jumpTo(60 * 50);
                },
                hintBuilder: hint('lazy-reveal', contexts),
              ),
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['lazy-reveal']!;
      expect(revealCount, 1);
      expect(hadTargetBeforeReveal, isFalse);
      expect(find.byKey(const ValueKey<String>('lazy-reveal')), findsOneWidget);
      expect(guide.targetRect.top, greaterThanOrEqualTo(0));
      expect(
        guide.targetRect.bottom,
        lessThanOrEqualTo(guide.overlaySize.height),
      );
    },
  );

  testWidgets('item reveal scrollToIndex helper can build a lazy target', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    int revealCount = 0;
    bool? hadTargetBeforeReveal;
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: ListView.builder(
          controller: scrollController,
          itemExtent: 50,
          itemCount: 80,
          itemBuilder: (BuildContext context, int index) {
            final Widget row = SizedBox(
              width: double.infinity,
              height: 50,
              child: ColoredBox(color: index.isEven ? Colors.red : Colors.blue),
            );
            if (index == 60) {
              return SpotlightGuideTarget(id: 'lazy-helper-target', child: row);
            }
            return row;
          },
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'lazy-helper-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
                alignment: 0,
              ),
              onReveal: (SpotlightGuideRevealContext context) async {
                revealCount++;
                hadTargetBeforeReveal = context.hasTargetContext;
                await context.scrollToIndex(
                  controller: scrollController,
                  index: 60,
                  itemExtent: 50,
                  alignment: 0.1,
                  duration: const Duration(milliseconds: 450),
                  settleFrames: 2,
                );
              },
              hintBuilder: hint('lazy-helper-reveal', contexts),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 8; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 120));

    expect(revealCount, 1);
    expect(hadTargetBeforeReveal, isFalse);
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('lazy-helper-reveal')),
      findsNothing,
      reason: 'lazy target hints should wait until reveal scrolling settles',
    );

    await tester.pumpAndSettle();

    final SpotlightGuideStepContext guide = contexts['lazy-helper-reveal']!;
    expect(revealCount, 1);
    expect(hadTargetBeforeReveal, isFalse);
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('lazy-helper-reveal')),
      findsOneWidget,
    );
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets('step reveal can build a lazy target before item layout', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    int stepRevealCount = 0;
    bool? hadTargetBeforeStepReveal;
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: ListView.builder(
          controller: scrollController,
          itemExtent: 50,
          itemCount: 80,
          itemBuilder: (BuildContext context, int index) {
            final Widget row = SizedBox(
              width: double.infinity,
              height: 50,
              child: ColoredBox(color: index.isEven ? Colors.red : Colors.blue),
            );
            if (index == 62) {
              return SpotlightGuideTarget(id: 'step-lazy-target', child: row);
            }
            return row;
          },
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            onReveal: (SpotlightGuideRevealContext context) {
              stepRevealCount++;
              hadTargetBeforeStepReveal = context.hasTargetContext;
              scrollController.jumpTo(62 * 50);
            },
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'step-lazy-target',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                revealOptions: const SpotlightGuideRevealOptions(
                  duration: Duration.zero,
                  alignment: 0,
                ),
                hintBuilder: hint('step-lazy-reveal', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['step-lazy-reveal']!;
    expect(stepRevealCount, 1);
    expect(hadTargetBeforeStepReveal, isFalse);
    expect(
      find.byKey(const ValueKey<String>('step-lazy-reveal')),
      findsOneWidget,
    );
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets('step reveal runs before item reveal callbacks', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<String> events = <String>[];
    bool? stepItemWasNull;
    bool? stepItemIndexWasNull;
    bool? stepHadTargetContext;
    bool? itemWasNotNull;
    bool? itemHadTargetContext;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            onReveal: (SpotlightGuideRevealContext context) {
              events.add('step');
              stepItemWasNull = context.item == null;
              stepItemIndexWasNull = context.itemIndex == null;
              stepHadTargetContext = context.hasTargetContext;
            },
            revealOptions: const SpotlightGuideRevealOptions(enabled: false),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                onReveal: (SpotlightGuideRevealContext context) {
                  events.add('item-${context.itemIndex}');
                  itemWasNotNull = context.item != null;
                  itemHadTargetContext = context.hasTargetContext;
                },
                hintBuilder: hint('ordered-reveal'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(events, <String>['step', 'item-0']);
    expect(stepItemWasNull, isTrue);
    expect(stepItemIndexWasNull, isTrue);
    expect(stepHadTargetContext, isTrue);
    expect(itemWasNotNull, isTrue);
    expect(itemHadTargetContext, isTrue);
    expect(
      find.byKey(const ValueKey<String>('ordered-reveal')),
      findsOneWidget,
    );
  });

  testWidgets('disabled reveal options do not auto-scroll available targets', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 1050,
                  child: SpotlightGuideTarget(
                    id: 'no-auto-scroll-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'no-auto-scroll-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(enabled: false),
              hintBuilder: hint('no-auto-scroll'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey<String>('no-auto-scroll')),
      findsOneWidget,
    );
  });

  testWidgets('finish cancels a pending async item reveal', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Completer<void> completer = Completer<void>();
    int revealCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              onReveal: (SpotlightGuideRevealContext context) {
                revealCount++;
                return completer.future;
              },
              hintBuilder: hint('cancelled-item-reveal'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    for (int i = 0; i < 4 && revealCount == 0; i++) {
      await tester.pump();
    }
    expect(revealCount, 1);
    expect(
      find.byKey(const ValueKey<String>('cancelled-item-reveal')),
      findsNothing,
    );

    controller.finish();
    completer.complete();
    await pumpGuide(tester);

    expect(controller.isShowing, isFalse);
    expect(
      find.byKey(const ValueKey<String>('cancelled-item-reveal')),
      findsNothing,
    );
  });

  testWidgets('onStepWillShow runs before step and item reveal callbacks', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<String> events = <String>[];

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          events.add('will-show');
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            onReveal: (SpotlightGuideRevealContext context) {
              events.add('step');
            },
            revealOptions: const SpotlightGuideRevealOptions(enabled: false),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                onReveal: (SpotlightGuideRevealContext context) {
                  events.add('item');
                },
                hintBuilder: hint('full-reveal-order'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(events, <String>['will-show', 'step', 'item']);
  });

  testWidgets('item reveal options are inherited from the step', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: SingleChildScrollView(
          controller: scrollController,
          child: const SizedBox(
            height: 1200,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 40,
                  top: 1050,
                  child: SpotlightGuideTarget(
                    id: 'inherit-reveal-target',
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            // Disabled at the step level and the item does not override it, so
            // no automatic scrolling should happen.
            revealOptions: const SpotlightGuideRevealOptions(enabled: false),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'inherit-reveal-target',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('inherit-reveal'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, 0);
  });

  testWidgets('disabled auto scroll reveals every item up front', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'static-first',
          secondId: 'static-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              enabled: false,
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'static-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('static-first', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'static-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('static-second', contexts),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    // With auto scroll disabled, the reveal pipeline ensures every item is
    // visible up front instead of waiting for a delayed timer. The last item
    // wins the final scroll position.
    final SpotlightGuideStepContext guide = contexts['static-second']!;
    expect(scrollController.offset, greaterThan(0));
    expect(guide.targetRect.top, greaterThanOrEqualTo(0));
    expect(
      guide.targetRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height),
    );
  });

  testWidgets(
    'a target flush to the viewport edge does not trigger auto scroll',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: const Stack(
            children: <Widget>[
              Positioned(
                left: 40,
                top: 40,
                child: SpotlightGuideTarget(
                  id: 'flush-first',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
              // Bottom edge sits exactly on the 600px overlay edge.
              Positioned(
                left: 40,
                top: 560,
                child: SpotlightGuideTarget(
                  id: 'flush-second',
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
            SpotlightGuideStep(
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'flush-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('flush-first', contexts),
                ),
                SpotlightGuideStepItem(
                  targetId: 'flush-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('flush-second', contexts),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);

      // The edge-flush second item counts as fully visible, so no same-step
      // auto-scroll timer is scheduled. If a timer leaked, this test would
      // fail on teardown with a pending-timer error.
      expect(find.byKey(const ValueKey<String>('flush-first')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('flush-second')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'same-step scroll reveals a target taller than the viewport',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 2000,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 40,
                    child: SpotlightGuideTarget(
                      id: 'tall-first',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  // Taller than the 600px overlay: it can never be fully
                  // contained, only overlapped once scroll brings it in.
                  Positioned(
                    left: 40,
                    top: 1000,
                    child: SpotlightGuideTarget(
                      id: 'tall-second',
                      child: SizedBox(
                        width: 100,
                        height: 800,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: const SpotlightGuideAutoScrollOptions(
                interval: Duration(milliseconds: 120),
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'tall-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('tall-first', contexts),
                ),
                SpotlightGuideStepItem(
                  targetId: 'tall-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('tall-second', contexts),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      for (int i = 0; i < 12; i++) {
        await tester.pump();
      }
      expect(find.byKey(const ValueKey<String>('tall-first')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tall-second')), findsNothing);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      // Regression: the strict "fully contained" rule kept the oversized target
      // hidden forever. Auto scroll brings part of it into view and the hint now
      // appears, overlapping the viewport.
      expect(scrollController.offset, greaterThan(0));
      expect(find.byKey(const ValueKey<String>('tall-second')), findsOneWidget);
      final SpotlightGuideStepContext guide = contexts['tall-second']!;
      expect(
        guide.targetRect.overlaps(Offset.zero & guide.overlaySize),
        isTrue,
      );
    },
  );

  testWidgets(
    'default reveal presentation hides the hint while target scrolls',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 2000,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 1050,
                    child: SpotlightGuideTarget(
                      id: 'motion-target',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'motion-target',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  revealOptions: const SpotlightGuideRevealOptions(
                    duration: Duration(milliseconds: 250),
                    alignment: 0.5,
                  ),
                  hintBuilder: hint('motion-target', contexts),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(scrollController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey<String>('motion-target')),
        findsNothing,
        reason:
            'the default strategy hides hints until reveal scrolling settles',
      );
      expect(contexts.containsKey('motion-target'), isFalse);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('motion-target')),
        findsOneWidget,
      );
      final SpotlightGuideStepContext guide = contexts['motion-target']!;
      expect(guide.targetRect.top, greaterThanOrEqualTo(0));
      expect(
        guide.targetRect.bottom,
        lessThanOrEqualTo(guide.overlaySize.height),
      );
    },
  );

  testWidgets(
    'live reveal strategy rebuilds the overlay while the target scrolls',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final List<double> targetTopsDuringScroll = <double>[];
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          revealStrategy:
              const SpotlightGuideLiveReveal(),
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 2000,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 1050,
                    child: SpotlightGuideTarget(
                      id: 'live-motion-target',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'live-motion-target',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  revealOptions: const SpotlightGuideRevealOptions(
                    duration: Duration(milliseconds: 250),
                    alignment: 0.5,
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        targetTopsDuringScroll.add(guide.targetRect.top);
                        return hint('live-motion-target')(context, guide);
                      },
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(scrollController.offset, greaterThan(0));
      expect(
        targetTopsDuringScroll.toSet().length,
        greaterThan(1),
        reason:
            'the live strategy keeps rebuilding during the scroll animation so '
            'the spotlight hole tracks the moving target',
      );
      expect(
        find.byKey(const ValueKey<String>('live-motion-target')),
        findsOneWidget,
        reason:
            'moving target geometry must not clear the measured hint size and '
            'leave only the spotlight hole visible',
      );
    },
  );

  testWidgets(
    'same-step scroll hides the outgoing hint during animated reveal',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: multiItemScrollableTargets(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            firstId: 'motion-first',
            secondId: 'motion-second',
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration(milliseconds: 250),
                alignment: 0.5,
              ),
              autoScrollOptions: const SpotlightGuideAutoScrollOptions(
                interval: Duration(milliseconds: 200),
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'motion-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('motion-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'motion-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('motion-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      for (int i = 0; i < 12; i++) {
        await tester.pump();
      }
      expect(
        find.byKey(const ValueKey<String>('motion-first')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('motion-second')), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        find.byKey(const ValueKey<String>('motion-first')),
        findsNothing,
        reason:
            'the outgoing hint should be hidden before auto-scroll moves it '
            'toward the viewport edge',
      );
      expect(
        find.byKey(const ValueKey<String>('motion-second')),
        findsNothing,
        reason: 'the next hint should wait until reveal scrolling completes',
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('motion-first')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('motion-second')),
        findsOneWidget,
      );
    },
  );
}
