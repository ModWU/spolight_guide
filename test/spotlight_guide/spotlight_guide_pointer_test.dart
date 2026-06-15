import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Pointer and arrow anchor relationship tests.
///
/// Run this file when changing [SpotlightGuideBubbleHint],
/// `pointerAnchorPosition`, `bubbleBodyOffset`, or the rule that target anchor
/// controls the arrow directly when no pointer is supplied.
void main() {
  testWidgets('pointer visual anchor stays aligned with target anchor', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 120,
          width: 100,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              gap: 0,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.center(),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      pointerSize: const Size(40, 24),
                      pointerAnchorPosition:
                          const SpotlightGuideAnchorPosition.center(),
                      pointer: const SizedBox(
                        key: ValueKey<String>('pointer'),
                        width: 40,
                        height: 24,
                        child: ColoredBox(color: Colors.yellow),
                      ),
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('pointer')),
    );
    final SpotlightGuideStepContext guide = contexts['pointer']!;
    expect(
      pointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

  testWidgets('pointer visual anchor stays aligned for left and right hints', (
    tester,
  ) async {
    final List<PointerPlacementCase> cases = <PointerPlacementCase>[
      PointerPlacementCase(
        label: 'pointer-left',
        placement: SpotlightGuidePlacement.left,
        targetLeft: 520,
      ),
      PointerPlacementCase(
        label: 'pointer-right',
        placement: SpotlightGuidePlacement.right,
        targetLeft: 80,
      ),
    ];

    for (final PointerPlacementCase placementCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${placementCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(placementCase.label),
          child: singleTargetStack(
            id: 'a',
            left: placementCase.targetLeft,
            top: 250,
            width: 80,
            height: 60,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: placementCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: 0,
                targetAnchorPosition:
                    const SpotlightGuideAnchorPosition.center(),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[placementCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        pointerSize: const Size(24, 40),
                        pointerAnchorPosition:
                            const SpotlightGuideAnchorPosition.center(),
                        pointer: SizedBox(
                          key: pointerKey,
                          width: 24,
                          height: 40,
                          child: const ColoredBox(color: Colors.yellow),
                        ),
                        child: const SizedBox(width: 80, height: 40),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final SpotlightGuideStepContext guide = contexts[placementCase.label]!;
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
      );
    }
  });

  testWidgets('target anchor directly controls arrow when pointer is omitted', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 300,
          top: 120,
          width: 120,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              targetAnchorPosition: const SpotlightGuideAnchorPosition.start(
                20,
              ),
              hintBuilder: hint('no-pointer-anchor', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['no-pointer-anchor']!;
    expect(
      guide.hintRect.left + guide.indicatorOffset,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

  testWidgets('pointer below a top-placed bubble aligns with target anchor', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 460,
          width: 100,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.top,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              gap: 0,
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer-top'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      pointerSize: const Size(40, 24),
                      pointer: const SizedBox(
                        key: ValueKey<String>('pointer-top'),
                        width: 40,
                        height: 24,
                        child: ColoredBox(color: Colors.yellow),
                      ),
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['pointer-top']!;
    expect(guide.indicatorDirection, SpotlightGuideIndicatorDirection.down);
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('pointer-top')),
    );
    expect(
      pointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
    // The pointer sits below the bubble body for a downward arrow.
    expect(pointerRect.top, greaterThan(guide.hintRect.top));
  });

  testWidgets('pointerAnchorPosition end aligns the pointer end to the arrow', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 120,
          width: 100,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              gap: 0,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.center(),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer-end'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      pointerSize: const Size(40, 24),
                      pointerAnchorPosition:
                          const SpotlightGuideAnchorPosition.end(),
                      pointer: const SizedBox(
                        key: ValueKey<String>('pointer-end'),
                        width: 40,
                        height: 24,
                        child: ColoredBox(color: Colors.yellow),
                      ),
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['pointer-end']!;
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('pointer-end')),
    );
    // With an end pointer anchor in LTR, the pointer's right edge aligns with
    // the indicator tip instead of its center.
    expect(
      pointerRect.right,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });
}
