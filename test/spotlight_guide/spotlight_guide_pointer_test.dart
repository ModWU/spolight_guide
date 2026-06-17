import 'dart:math' as math;

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Pointer and arrow anchor relationship tests.
///
/// Run this file when changing [SpotlightGuideBubbleHint],
/// [SpotlightGuidePointer], or the rule that target anchor
/// controls the arrow directly when no pointer is supplied.
void main() {
  test('pointer direction constructors use up as the zero pose', () {
    expect(
      const SpotlightGuidePointerDirection.up().radians,
      moreOrLessEquals(0, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.up(0).radians,
      moreOrLessEquals(0, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.upRight().radians,
      moreOrLessEquals(math.pi / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.upRight(0).radians,
      moreOrLessEquals(math.pi / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.upRight(math.pi / 2).radians,
      moreOrLessEquals(math.pi * 3 / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.right().radians,
      moreOrLessEquals(math.pi / 2, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.downRight().radians,
      moreOrLessEquals(math.pi * 3 / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.down().radians,
      moreOrLessEquals(math.pi, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.downLeft().radians,
      moreOrLessEquals(-math.pi * 3 / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.left().radians,
      moreOrLessEquals(-math.pi / 2, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.upLeft().radians,
      moreOrLessEquals(-math.pi / 4, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.right(math.pi / 2).radians,
      moreOrLessEquals(math.pi, epsilon: 0.001),
    );
    expect(
      const SpotlightGuidePointerDirection.left(math.pi / 2).radians,
      moreOrLessEquals(0, epsilon: 0.001),
    );
  });

  test('pointer visual offset resolves physical and directional values', () {
    const SpotlightGuidePointerOffset physical =
        SpotlightGuidePointerOffset.physical(left: 2, right: 7, up: 3, down: 9);
    expect(physical.resolve(TextDirection.ltr), const Offset(5, 6));
    expect(physical.resolve(TextDirection.rtl), const Offset(5, 6));

    const SpotlightGuidePointerOffset directional =
        SpotlightGuidePointerOffset.directional(
          start: 2,
          end: 7,
          up: 3,
          down: 9,
        );
    expect(directional.resolve(TextDirection.ltr), const Offset(5, 6));
    expect(directional.resolve(TextDirection.rtl), const Offset(-5, 6));
  });

  testWidgets(
    'pointer builder receives resolved direction and original child',
    (tester) async {
      final List<
        ({
          SpotlightGuidePlacement placement,
          SpotlightGuideDirection direction,
          double rotation,
          double targetLeft,
          double targetTop,
        })
      >
      cases =
          <
            ({
              SpotlightGuidePlacement placement,
              SpotlightGuideDirection direction,
              double rotation,
              double targetLeft,
              double targetTop,
            })
          >[
            (
              placement: SpotlightGuidePlacement.bottom,
              direction: SpotlightGuideDirection.up,
              rotation: 0,
              targetLeft: 320,
              targetTop: 120,
            ),
            (
              placement: SpotlightGuidePlacement.top,
              direction: SpotlightGuideDirection.down,
              rotation: math.pi,
              targetLeft: 320,
              targetTop: 420,
            ),
            (
              placement: SpotlightGuidePlacement.left,
              direction: SpotlightGuideDirection.right,
              rotation: math.pi / 2,
              targetLeft: 560,
              targetTop: 260,
            ),
            (
              placement: SpotlightGuidePlacement.right,
              direction: SpotlightGuideDirection.left,
              rotation: -math.pi / 2,
              targetLeft: 80,
              targetTop: 260,
            ),
          ];

      for (final testCase in cases) {
        final List<SpotlightGuidePointerContext> pointerContexts =
            <SpotlightGuidePointerContext>[];
        final String label = 'builder-${testCase.placement.name}';
        final ValueKey<String> builderKey = ValueKey<String>('$label-builder');
        final ValueKey<String> childKey = ValueKey<String>('$label-child');

        await tester.pumpWidget(
          guideApp(
            appKey: ValueKey<String>(label),
            child: singleTargetStack(
              id: 'a',
              left: testCase.targetLeft,
              top: testCase.targetTop,
              width: 92,
              height: 58,
            ),
            steps: <SpotlightGuideStep>[
              SpotlightGuideStep.item(
                SpotlightGuideStepItem(
                  targetId: 'a',
                  placement: testCase.placement,
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  pointer: SpotlightGuidePointer(
                    size: const Size(28, 28),
                    child: SizedBox(key: childKey, width: 28, height: 28),
                    builder:
                        (
                          BuildContext context,
                          SpotlightGuidePointerContext pointer,
                          Widget child,
                        ) {
                          pointerContexts.add(pointer);
                          return KeyedSubtree(key: builderKey, child: child);
                        },
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: const SizedBox(width: 92, height: 44),
                        );
                      },
                ),
              ),
            ],
          ),
        );
        await pumpGuide(tester);

        expect(find.byKey(builderKey), findsOneWidget);
        expect(find.byKey(childKey), findsOneWidget);
        final SpotlightGuidePointerContext pointerContext =
            pointerContexts.last;
        expect(pointerContext.targetDirection, testCase.direction);
        expect(
          pointerContext.targetRotation,
          moreOrLessEquals(testCase.rotation, epsilon: 0.001),
        );
        expect(
          pointerContext.rotationToTarget(),
          moreOrLessEquals(testCase.rotation, epsilon: 0.001),
        );
        expect(
          pointerContext.rotationToTarget(
            from: const SpotlightGuidePointerDirection.left(),
          ),
          moreOrLessEquals(
            _normalizeRotation(testCase.rotation + math.pi / 2),
            epsilon: 0.001,
          ),
        );
        expect(
          pointerContext.rotationToTarget(
            from: const SpotlightGuidePointerDirection.left(math.pi / 4),
          ),
          moreOrLessEquals(
            _normalizeRotation(testCase.rotation + math.pi / 4),
            epsilon: 0.001,
          ),
        );
        expect(pointerContext.placement, testCase.placement);
      }
    },
  );

  testWidgets('pointer direction offsets mirror across opposite placements', (
    tester,
  ) async {
    final Map<SpotlightGuidePlacement, SpotlightGuidePointerContext> contexts =
        <SpotlightGuidePlacement, SpotlightGuidePointerContext>{};
    final List<
      ({SpotlightGuidePlacement placement, double targetLeft, double targetTop})
    >
    cases =
        <
          ({
            SpotlightGuidePlacement placement,
            double targetLeft,
            double targetTop,
          })
        >[
          (
            placement: SpotlightGuidePlacement.bottom,
            targetLeft: 320,
            targetTop: 120,
          ),
          (
            placement: SpotlightGuidePlacement.top,
            targetLeft: 320,
            targetTop: 420,
          ),
          (
            placement: SpotlightGuidePlacement.left,
            targetLeft: 560,
            targetTop: 260,
          ),
          (
            placement: SpotlightGuidePlacement.right,
            targetLeft: 80,
            targetTop: 260,
          ),
        ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>('mirrored-${testCase.placement.name}'),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: 92,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                pointer: SpotlightGuidePointer(
                  size: const Size(28, 28),
                  child: const SizedBox(width: 28, height: 28),
                  builder:
                      (
                        BuildContext context,
                        SpotlightGuidePointerContext pointer,
                        Widget child,
                      ) {
                        contexts[testCase.placement] = pointer;
                        return child;
                      },
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 92, height: 44),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);
    }

    expect(
      contexts[SpotlightGuidePlacement.left]!.rotationToTarget(
        from: const SpotlightGuidePointerDirection.right(math.pi / 2),
      ),
      moreOrLessEquals(-math.pi / 2, epsilon: 0.001),
    );
    expect(
      contexts[SpotlightGuidePlacement.right]!.rotationToTarget(
        from: const SpotlightGuidePointerDirection.right(math.pi / 2),
      ),
      moreOrLessEquals(math.pi / 2, epsilon: 0.001),
    );
    expect(
      contexts[SpotlightGuidePlacement.bottom]!.rotationToTarget(
        from: const SpotlightGuidePointerDirection.up(math.pi / 2),
      ),
      moreOrLessEquals(-math.pi / 2, epsilon: 0.001),
    );
    expect(
      contexts[SpotlightGuidePlacement.top]!.rotationToTarget(
        from: const SpotlightGuidePointerDirection.up(math.pi / 2),
      ),
      moreOrLessEquals(math.pi / 2, epsilon: 0.001),
    );
  });

  testWidgets('pointer builder sees resolved auto and RTL directions', (
    tester,
  ) async {
    final List<
      ({
        String label,
        SpotlightGuidePlacement placement,
        TextDirection textDirection,
        double targetLeft,
        double targetTop,
        SpotlightGuidePlacement expectedPlacement,
        SpotlightGuideDirection expectedDirection,
      })
    >
    cases =
        <
          ({
            String label,
            SpotlightGuidePlacement placement,
            TextDirection textDirection,
            double targetLeft,
            double targetTop,
            SpotlightGuidePlacement expectedPlacement,
            SpotlightGuideDirection expectedDirection,
          })
        >[
          (
            label: 'vertical-auto-bottom',
            placement: SpotlightGuidePlacement.verticalAuto,
            textDirection: TextDirection.ltr,
            targetLeft: 320,
            targetTop: 30,
            expectedPlacement: SpotlightGuidePlacement.bottom,
            expectedDirection: SpotlightGuideDirection.up,
          ),
          (
            label: 'vertical-auto-top',
            placement: SpotlightGuidePlacement.verticalAuto,
            textDirection: TextDirection.ltr,
            targetLeft: 320,
            targetTop: 500,
            expectedPlacement: SpotlightGuidePlacement.top,
            expectedDirection: SpotlightGuideDirection.down,
          ),
          (
            label: 'rtl-start',
            placement: SpotlightGuidePlacement.start,
            textDirection: TextDirection.rtl,
            targetLeft: 120,
            targetTop: 260,
            expectedPlacement: SpotlightGuidePlacement.right,
            expectedDirection: SpotlightGuideDirection.left,
          ),
        ];

    for (final testCase in cases) {
      final List<SpotlightGuidePointerContext> pointerContexts =
          <SpotlightGuidePointerContext>[];

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          textDirection: testCase.textDirection,
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: 92,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                pointer: SpotlightGuidePointer(
                  size: const Size(28, 28),
                  child: const SizedBox(width: 28, height: 28),
                  builder:
                      (
                        BuildContext context,
                        SpotlightGuidePointerContext pointer,
                        Widget child,
                      ) {
                        pointerContexts.add(pointer);
                        return child;
                      },
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 92, height: 44),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuidePointerContext pointerContext = pointerContexts.last;
      expect(pointerContext.placement, testCase.expectedPlacement);
      expect(pointerContext.targetDirection, testCase.expectedDirection);
      expect(pointerContext.textDirection, testCase.textDirection);
    }
  });

  testWidgets('pointer builder exposes bubble direction after bubbleSide', (
    tester,
  ) async {
    final List<SpotlightGuidePointerContext> pointerContexts =
        <SpotlightGuidePointerContext>[];

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 560,
          top: 260,
          width: 92,
          height: 58,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.left,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              pointer: SpotlightGuidePointer(
                size: const Size(28, 28),
                bubbleSide: SpotlightGuideBubbleSide.bottom,
                child: const SizedBox(width: 28, height: 28),
                builder:
                    (
                      BuildContext context,
                      SpotlightGuidePointerContext pointer,
                      Widget child,
                    ) {
                      pointerContexts.add(pointer);
                      return child;
                    },
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 92, height: 44),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuidePointerContext pointerContext = pointerContexts.last;
    expect(pointerContext.targetDirection, SpotlightGuideDirection.right);
    expect(pointerContext.bubbleDirection, SpotlightGuideDirection.down);
    expect(
      pointerContext.bubbleRotation,
      moreOrLessEquals(math.pi, epsilon: 0.001),
    );
    expect(
      pointerContext.rotationToBubble(
        from: const SpotlightGuidePointerDirection.right(),
      ),
      moreOrLessEquals(math.pi / 2, epsilon: 0.001),
    );
    expect(pointerContext.bubbleAnchorDirection, SpotlightGuideDirection.up);
    expect(pointerContext.bubbleSide, SpotlightGuideBubbleSide.bottom);
  });

  testWidgets('text hint can include the built-in tap pointer', (tester) async {
    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              pointer: const SpotlightGuidePointer.tap(),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideTextHint(
                      guide: guide,
                      title: 'Pointer title',
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byType(SpotlightGuideTextHint), findsOneWidget);
    expect(find.byType(SpotlightGuideTapPointer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubble hint paints pointer below the bubble by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 300,
          top: 160,
          width: 80,
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
              decoration: const SpotlightGuideBubbleDecoration(
                border: BorderSide(color: Color(0xFF112233), width: 3),
              ),
              pointer: const SpotlightGuidePointer(
                size: Size(24, 24),
                child: SizedBox(
                  key: ValueKey<String>('pointer-on-border'),
                  width: 24,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('pointer-on-border')),
      findsOneWidget,
    );
    expect(find.byType(SpotlightGuideBubble), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubble hint can paint pointer above the bubble', (tester) async {
    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 300,
          top: 160,
          width: 80,
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
              pointer: const SpotlightGuidePointer(
                paintOrder: SpotlightGuidePointerPaintOrder.aboveBubble,
                size: Size(24, 24),
                child: SizedBox(
                  key: ValueKey<String>('above-bubble-pointer'),
                  width: 24,
                  height: 24,
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('above-bubble-pointer')),
      findsOneWidget,
    );
    expect(find.byType(SpotlightGuideBubble), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer chain aligns with target anchor on every fixed side', (
    tester,
  ) async {
    const double gap = 12;
    final List<_PointerChainCase> cases = <_PointerChainCase>[
      const _PointerChainCase(
        label: 'bottom-chain',
        placement: SpotlightGuidePlacement.bottom,
        targetLeft: 320,
        targetTop: 120,
      ),
      const _PointerChainCase(
        label: 'top-chain',
        placement: SpotlightGuidePlacement.top,
        targetLeft: 320,
        targetTop: 420,
      ),
      const _PointerChainCase(
        label: 'left-chain',
        placement: SpotlightGuidePlacement.left,
        targetLeft: 560,
        targetTop: 260,
      ),
      const _PointerChainCase(
        label: 'right-chain',
        placement: SpotlightGuidePlacement.right,
        targetLeft: 80,
        targetTop: 260,
      ),
    ];

    for (final _PointerChainCase testCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${testCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: 92,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                pointer: SpotlightGuidePointer(
                  size: testCase.pointerSize,
                  child: SizedBox(
                    key: pointerKey,
                    width: testCase.pointerSize.width,
                    height: testCase.pointerSize.height,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[testCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 92, height: 44),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[testCase.label]!;
      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      switch (guide.anchorDirection) {
        case SpotlightGuideDirection.up:
          expect(
            pointerRect.center.dx,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
          expect(
            pointerRect.top,
            moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
            reason:
                '${testCase.label}: pointer=$pointerRect target=${guide.targetRect} hint=${guide.hintRect}',
          );
          expect(
            bubbleRect.top,
            moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.down:
          expect(
            pointerRect.center.dx,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
          expect(
            pointerRect.bottom,
            moreOrLessEquals(guide.targetRect.top, epsilon: 0.5),
            reason:
                '${testCase.label}: pointer=$pointerRect target=${guide.targetRect} hint=${guide.hintRect}',
          );
          expect(
            bubbleRect.bottom,
            moreOrLessEquals(pointerRect.top - gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.left:
          expect(
            pointerRect.center.dy,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
          expect(
            pointerRect.left,
            moreOrLessEquals(guide.targetRect.right, epsilon: 0.5),
            reason:
                '${testCase.label}: pointer=$pointerRect target=${guide.targetRect} hint=${guide.hintRect}',
          );
          expect(
            bubbleRect.left,
            moreOrLessEquals(pointerRect.right + gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.right:
          expect(
            pointerRect.center.dy,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
          expect(
            pointerRect.right,
            moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
            reason:
                '${testCase.label}: pointer=$pointerRect target=${guide.targetRect} hint=${guide.hintRect}',
          );
          expect(
            bubbleRect.right,
            moreOrLessEquals(pointerRect.left - gap, epsilon: 0.5),
          );
      }
    }
  });

  testWidgets(
    'pointerAnchorPosition only moves the pointer target contact on every side',
    (tester) async {
      final List<SpotlightGuideAnchorPosition> pointerAnchors =
          <SpotlightGuideAnchorPosition>[
            const SpotlightGuideAnchorPosition.start(),
            const SpotlightGuideAnchorPosition.center(),
            const SpotlightGuideAnchorPosition.end(),
          ];
      final List<_PointerChainCase> cases = <_PointerChainCase>[
        const _PointerChainCase(
          label: 'bottom-pointer-anchor',
          placement: SpotlightGuidePlacement.bottom,
          targetLeft: 320,
          targetTop: 120,
        ),
        const _PointerChainCase(
          label: 'top-pointer-anchor',
          placement: SpotlightGuidePlacement.top,
          targetLeft: 320,
          targetTop: 420,
        ),
        const _PointerChainCase(
          label: 'left-pointer-anchor',
          placement: SpotlightGuidePlacement.left,
          targetLeft: 560,
          targetTop: 260,
        ),
        const _PointerChainCase(
          label: 'right-pointer-anchor',
          placement: SpotlightGuidePlacement.right,
          targetLeft: 80,
          targetTop: 260,
        ),
      ];

      for (final _PointerChainCase testCase in cases) {
        for (final SpotlightGuideAnchorPosition pointerAnchor
            in pointerAnchors) {
          final String label = '${testCase.label}-${pointerAnchor.anchor.name}';
          final Map<String, SpotlightGuideStepContext> contexts =
              <String, SpotlightGuideStepContext>{};
          final ValueKey<String> pointerKey = ValueKey<String>(
            '$label-pointer',
          );

          await tester.pumpWidget(
            guideApp(
              appKey: ValueKey<String>(label),
              child: singleTargetStack(
                id: 'a',
                left: testCase.targetLeft,
                top: testCase.targetTop,
                width: 92,
                height: 58,
              ),
              steps: <SpotlightGuideStep>[
                SpotlightGuideStep.item(
                  SpotlightGuideStepItem(
                    targetId: 'a',
                    placement: testCase.placement,
                    targetDecoration: const SpotlightGuideTargetDecoration(
                      padding: EdgeInsets.zero,
                    ),
                    gap: 10,
                    pointer: SpotlightGuidePointer(
                      size: testCase.pointerSize,
                      pointerAnchorPosition: pointerAnchor,
                      child: SizedBox(
                        key: pointerKey,
                        width: testCase.pointerSize.width,
                        height: testCase.pointerSize.height,
                        child: const ColoredBox(color: Colors.yellow),
                      ),
                    ),
                    hintBuilder:
                        (
                          BuildContext context,
                          SpotlightGuideStepContext guide,
                        ) {
                          contexts[label] = guide;
                          return SpotlightGuideBubbleHint(
                            guide: guide,
                            child: const SizedBox(width: 92, height: 44),
                          );
                        },
                  ),
                ),
              ],
            ),
          );
          await pumpGuide(tester);

          final SpotlightGuideStepContext guide = contexts[label]!;
          final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
          final Rect bubbleRect = tester.getRect(
            find.byType(SpotlightGuideBubble),
          );
          final SpotlightGuideAnchorGeometry anchorGeometry =
              _bubbleAnchorGeometry(tester);
          final bool horizontalAnchorAxis =
              guide.anchorDirection == SpotlightGuideDirection.up ||
              guide.anchorDirection == SpotlightGuideDirection.down;
          final double pointerTargetAxis = _pointerAnchorAxisPosition(
            pointerRect,
            pointerAnchor,
            isHorizontalAxis: horizontalAnchorAxis,
            textDirection: TextDirection.ltr,
          );
          final double targetAxis = horizontalAnchorAxis
              ? guide.targetAnchorPoint.dx
              : guide.targetAnchorPoint.dy;

          _expectPointerMainAxisTouchesTarget(pointerRect, guide);
          expect(
            pointerTargetAxis,
            moreOrLessEquals(targetAxis, epsilon: 0.5),
            reason: label,
          );
          expect(
            _bubbleAnchorGlobalAxis(bubbleRect, anchorGeometry),
            moreOrLessEquals(
              horizontalAnchorAxis
                  ? pointerRect.center.dx
                  : pointerRect.center.dy,
              epsilon: 0.5,
            ),
            reason: '$label bubble anchor should stay on pointer center',
          );
        }
      }
    },
  );

  testWidgets('pointer can use its child size when size is omitted', (
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
              pointer: const SpotlightGuidePointer(
                child: SizedBox(
                  key: ValueKey<String>('auto-size-pointer'),
                  width: 34,
                  height: 22,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['auto-size'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['auto-size']!;
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('auto-size-pointer')),
    );

    expect(pointerRect.size, const Size(34, 22));
    expect(pointerRect.top, moreOrLessEquals(guide.targetRect.bottom));
    expect(
      pointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

  testWidgets(
    'natural pointer size changes are hidden until the layout is stable',
    (tester) async {
      bool pointerLoaded = false;
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      Widget buildApp() {
        return guideApp(
          barrier: const SpotlightGuideBarrierStyle(blurSigma: 1),
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
                pointer: SpotlightGuidePointer(
                  child: SizedBox(
                    key: const ValueKey<String>('unstable-natural-pointer'),
                    width: 68,
                    height: pointerLoaded ? 102 : 0,
                    child: const ColoredBox(color: Colors.orange),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['unstable-natural'] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(
                          key: ValueKey<String>('unstable-natural-hint'),
                          width: 180,
                          height: 72,
                          child: ColoredBox(color: Colors.white),
                        ),
                      );
                    },
              ),
            ),
          ],
        );
      }

      await tester.pumpWidget(buildApp());
      await pumpGuide(tester);
      expect(
        find
            .byKey(const ValueKey<String>('unstable-natural-hint'))
            .hitTestable(),
        findsNothing,
      );
      expect(
        barrierClipPath(
          tester,
          contexts['unstable-natural']!.overlaySize,
        ).contains(contexts['unstable-natural']!.targetRect.center),
        isTrue,
        reason:
            'The target hole should not be exposed before the hint is ready.',
      );

      pointerLoaded = true;
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(
        find
            .byKey(const ValueKey<String>('unstable-natural-hint'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        barrierClipPath(
          tester,
          contexts['unstable-natural']!.overlaySize,
        ).contains(contexts['unstable-natural']!.targetRect.center),
        isFalse,
        reason: 'The target hole and hint should appear together once stable.',
      );
    },
  );

  testWidgets('explicit pointer size keeps the bubble visible while the child '
      'has a transient zero natural size', (tester) async {
    bool pointerLoaded = false;

    Widget buildApp() {
      return guideApp(
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
              pointer: SpotlightGuidePointer(
                size: const Size(68, 102),
                child: SizedBox(
                  key: const ValueKey<String>('stable-slot-pointer'),
                  width: 68,
                  height: pointerLoaded ? 102 : 0,
                  child: const ColoredBox(color: Colors.orange),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(
                        key: ValueKey<String>('stable-slot-hint'),
                        width: 180,
                        height: 72,
                        child: ColoredBox(color: Colors.white),
                      ),
                    );
                  },
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('stable-slot-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('stable-slot-pointer'))),
      const Size(68, 102),
    );

    pointerLoaded = true;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('stable-slot-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('stable-slot-pointer'))),
      const Size(68, 102),
    );
  });

  testWidgets(
    'signed pointer targetGap moves the pointer from the target on every side',
    (tester) async {
      const double pointerToBubbleGap = 8;
      final List<double> targetGaps = <double>[0, 14, -6];
      final List<_PointerChainCase> cases = <_PointerChainCase>[
        const _PointerChainCase(
          label: 'bottom-target-gap',
          placement: SpotlightGuidePlacement.bottom,
          targetLeft: 320,
          targetTop: 120,
        ),
        const _PointerChainCase(
          label: 'top-target-gap',
          placement: SpotlightGuidePlacement.top,
          targetLeft: 320,
          targetTop: 420,
        ),
        const _PointerChainCase(
          label: 'left-target-gap',
          placement: SpotlightGuidePlacement.left,
          targetLeft: 560,
          targetTop: 260,
        ),
        const _PointerChainCase(
          label: 'right-target-gap',
          placement: SpotlightGuidePlacement.right,
          targetLeft: 80,
          targetTop: 260,
        ),
      ];

      for (final double targetGap in targetGaps) {
        for (final _PointerChainCase testCase in cases) {
          final String label = '${testCase.label}-$targetGap';
          final Map<String, SpotlightGuideStepContext> contexts =
              <String, SpotlightGuideStepContext>{};
          final ValueKey<String> pointerKey = ValueKey<String>(
            '$label-pointer',
          );

          await tester.pumpWidget(
            guideApp(
              appKey: ValueKey<String>(label),
              child: singleTargetStack(
                id: 'a',
                left: testCase.targetLeft,
                top: testCase.targetTop,
                width: 92,
                height: 58,
              ),
              steps: <SpotlightGuideStep>[
                SpotlightGuideStep.item(
                  SpotlightGuideStepItem(
                    targetId: 'a',
                    placement: testCase.placement,
                    targetDecoration: const SpotlightGuideTargetDecoration(
                      padding: EdgeInsets.zero,
                    ),
                    gap: pointerToBubbleGap,
                    pointer: SpotlightGuidePointer(
                      targetGap: targetGap,
                      size: testCase.pointerSize,
                      child: SizedBox(
                        key: pointerKey,
                        width: testCase.pointerSize.width,
                        height: testCase.pointerSize.height,
                        child: const ColoredBox(color: Colors.yellow),
                      ),
                    ),
                    hintBuilder:
                        (
                          BuildContext context,
                          SpotlightGuideStepContext guide,
                        ) {
                          contexts[label] = guide;
                          return SpotlightGuideBubbleHint(
                            guide: guide,
                            child: const SizedBox(width: 92, height: 44),
                          );
                        },
                  ),
                ),
              ],
            ),
          );
          await pumpGuide(tester);

          final SpotlightGuideStepContext guide = contexts[label]!;
          final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
          final Rect bubbleRect = tester.getRect(
            find.byType(SpotlightGuideBubble),
          );
          switch (guide.anchorDirection) {
            case SpotlightGuideDirection.up:
              expect(
                pointerRect.top,
                moreOrLessEquals(
                  guide.targetRect.bottom + targetGap,
                  epsilon: 0.5,
                ),
              );
              expect(
                bubbleRect.top,
                moreOrLessEquals(
                  pointerRect.bottom + pointerToBubbleGap,
                  epsilon: 0.5,
                ),
              );
            case SpotlightGuideDirection.down:
              expect(
                pointerRect.bottom,
                moreOrLessEquals(
                  guide.targetRect.top - targetGap,
                  epsilon: 0.5,
                ),
              );
              expect(
                bubbleRect.bottom,
                moreOrLessEquals(
                  pointerRect.top - pointerToBubbleGap,
                  epsilon: 0.5,
                ),
              );
            case SpotlightGuideDirection.left:
              expect(
                pointerRect.left,
                moreOrLessEquals(
                  guide.targetRect.right + targetGap,
                  epsilon: 0.5,
                ),
              );
              expect(
                bubbleRect.left,
                moreOrLessEquals(
                  pointerRect.right + pointerToBubbleGap,
                  epsilon: 0.5,
                ),
              );
            case SpotlightGuideDirection.right:
              expect(
                pointerRect.right,
                moreOrLessEquals(
                  guide.targetRect.left - targetGap,
                  epsilon: 0.5,
                ),
              );
              expect(
                bubbleRect.right,
                moreOrLessEquals(
                  pointerRect.left - pointerToBubbleGap,
                  epsilon: 0.5,
                ),
              );
          }
        }
      }
    },
  );

  testWidgets(
    'pointer resolves physical and semantic horizontal sides in RTL',
    (tester) async {
      final List<
        ({
          SpotlightGuidePlacement placement,
          SpotlightGuidePlacement expected,
          SpotlightGuideDirection direction,
        })
      >
      cases =
          <
            ({
              SpotlightGuidePlacement placement,
              SpotlightGuidePlacement expected,
              SpotlightGuideDirection direction,
            })
          >[
            (
              placement: SpotlightGuidePlacement.left,
              expected: SpotlightGuidePlacement.left,
              direction: SpotlightGuideDirection.right,
            ),
            (
              placement: SpotlightGuidePlacement.right,
              expected: SpotlightGuidePlacement.right,
              direction: SpotlightGuideDirection.left,
            ),
            (
              placement: SpotlightGuidePlacement.start,
              expected: SpotlightGuidePlacement.right,
              direction: SpotlightGuideDirection.left,
            ),
            (
              placement: SpotlightGuidePlacement.end,
              expected: SpotlightGuidePlacement.left,
              direction: SpotlightGuideDirection.right,
            ),
          ];

      for (final testCase in cases) {
        final String label = 'rtl-pointer-${testCase.placement.name}';
        final Map<String, SpotlightGuideStepContext> contexts =
            <String, SpotlightGuideStepContext>{};
        final ValueKey<String> pointerKey = ValueKey<String>('$label-pointer');

        await tester.pumpWidget(
          guideApp(
            appKey: ValueKey<String>(label),
            textDirection: TextDirection.rtl,
            child: singleTargetStack(
              id: 'a',
              left: 340,
              top: 260,
              width: 100,
              height: 60,
            ),
            steps: <SpotlightGuideStep>[
              SpotlightGuideStep.item(
                SpotlightGuideStepItem(
                  targetId: 'a',
                  placement: testCase.placement,
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  pointer: SpotlightGuidePointer(
                    size: const Size(28, 40),
                    child: SizedBox(
                      key: pointerKey,
                      width: 28,
                      height: 40,
                      child: const ColoredBox(color: Colors.yellow),
                    ),
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        contexts[label] = guide;
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: const SizedBox(width: 90, height: 40),
                        );
                      },
                ),
              ),
            ],
          ),
        );
        await pumpGuide(tester);

        final SpotlightGuideStepContext guide = contexts[label]!;
        final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
        expect(guide.placement, testCase.expected);
        expect(guide.anchorDirection, testCase.direction);
        expect(
          pointerRect.center.dy,
          moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
        );
        if (testCase.expected == SpotlightGuidePlacement.right) {
          expect(
            pointerRect.left,
            moreOrLessEquals(guide.targetRect.right, epsilon: 0.5),
          );
        } else {
          expect(
            pointerRect.right,
            moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
          );
        }
      }
    },
  );

  testWidgets('pointer can stay decorative while bubble anchors to target', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 130,
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
              gap: 16,
              pointer: const SpotlightGuidePointer(
                anchorMode: SpotlightGuidePointerAnchorMode.target,
                size: Size(36, 36),
                child: SizedBox(
                  key: ValueKey<String>('decorative-pointer'),
                  width: 36,
                  height: 36,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['decorative'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(
                        key: ValueKey<String>('direct-bubble-child'),
                        width: 100,
                        height: 40,
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['decorative']!;
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('decorative-pointer')),
    );

    expect(bubbleRect.top, moreOrLessEquals(guide.hintRect.top, epsilon: 0.5));
    expect(
      bubbleRect.top,
      moreOrLessEquals(guide.targetRect.bottom + guide.gap, epsilon: 0.5),
    );
    expect(
      bubbleRect.left + guide.anchorOffset,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
    expect(
      pointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

  testWidgets('signed pointer gap moves the bubble anchor from the pointer', (
    tester,
  ) async {
    const double gap = -6;
    final List<_PointerChainCase> cases = <_PointerChainCase>[
      const _PointerChainCase(
        label: 'negative-bottom-gap',
        placement: SpotlightGuidePlacement.bottom,
        targetLeft: 320,
        targetTop: 120,
      ),
      const _PointerChainCase(
        label: 'negative-top-gap',
        placement: SpotlightGuidePlacement.top,
        targetLeft: 320,
        targetTop: 420,
      ),
      const _PointerChainCase(
        label: 'negative-left-gap',
        placement: SpotlightGuidePlacement.left,
        targetLeft: 560,
        targetTop: 260,
      ),
      const _PointerChainCase(
        label: 'negative-right-gap',
        placement: SpotlightGuidePlacement.right,
        targetLeft: 80,
        targetTop: 260,
      ),
    ];

    for (final _PointerChainCase testCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${testCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: 92,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                pointer: SpotlightGuidePointer(
                  size: testCase.pointerSize,
                  child: SizedBox(
                    key: pointerKey,
                    width: testCase.pointerSize.width,
                    height: testCase.pointerSize.height,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[testCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 92, height: 44),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[testCase.label]!;
      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      switch (guide.anchorDirection) {
        case SpotlightGuideDirection.up:
          expect(
            pointerRect.top,
            moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
          );
          expect(
            bubbleRect.top,
            moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.down:
          expect(
            pointerRect.bottom,
            moreOrLessEquals(guide.targetRect.top, epsilon: 0.5),
          );
          expect(
            bubbleRect.bottom,
            moreOrLessEquals(pointerRect.top - gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.left:
          expect(
            pointerRect.left,
            moreOrLessEquals(guide.targetRect.right, epsilon: 0.5),
          );
          expect(
            bubbleRect.left,
            moreOrLessEquals(pointerRect.right + gap, epsilon: 0.5),
          );
        case SpotlightGuideDirection.right:
          expect(
            pointerRect.right,
            moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
          );
          expect(
            bubbleRect.right,
            moreOrLessEquals(pointerRect.left - gap, epsilon: 0.5),
          );
      }
    }
  });

  testWidgets('pointer bubble gap does not shrink cross-axis bubble width', (
    tester,
  ) async {
    final Map<double, double> bubbleWidths = <double, double>{};
    final Map<double, double> pointerToBubbleDistances = <double, double>{};

    for (final double gap in <double>[0, 60]) {
      final String label = 'cross-axis-gap-$gap';
      final ValueKey<String> pointerKey = ValueKey<String>('$label-pointer');

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
          child: singleTargetStack(
            id: 'a',
            left: 340,
            top: 220,
            width: 90,
            height: 60,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.left,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                minWidth: 180,
                maxWidth: 300,
                pointer: SpotlightGuidePointer(
                  size: const Size(128, 144),
                  pointerAnchorPosition:
                      const SpotlightGuideAnchorPosition.end(),
                  bubbleSide: SpotlightGuideBubbleSide.bottom,
                  child: SizedBox(
                    key: pointerKey,
                    width: 128,
                    height: 144,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 300, height: 48),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      bubbleWidths[gap] = bubbleRect.width;
      pointerToBubbleDistances[gap] = bubbleRect.top - pointerRect.bottom;
    }

    expect(bubbleWidths[0], moreOrLessEquals(300, epsilon: 0.5));
    expect(bubbleWidths[60], moreOrLessEquals(bubbleWidths[0]!, epsilon: 0.5));
    expect(
      pointerToBubbleDistances[60]! - pointerToBubbleDistances[0]!,
      moreOrLessEquals(60, epsilon: 0.5),
    );
  });

  testWidgets('pointer gap uses the hint edge when the bubble has no anchor', (
    tester,
  ) async {
    const double gap = 18;
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 300,
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
              decoration: const SpotlightGuideBubbleDecoration(
                anchor: SpotlightGuideNoAnchor(),
              ),
              gap: gap,
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                child: SizedBox(
                  key: ValueKey<String>('no-anchor-pointer'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['no-anchor-pointer-gap'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['no-anchor-pointer-gap']!;
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('no-anchor-pointer')),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));

    expect(pointerRect.top, moreOrLessEquals(guide.targetRect.bottom));
    expect(
      pointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
    expect(
      bubbleRect.top,
      moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
    );
  });

  testWidgets('visualOffset does not move the anchor chain on any fixed side', (
    tester,
  ) async {
    const double gap = 10;
    const SpotlightGuidePointerOffset visualOffset =
        SpotlightGuidePointerOffset.physical(right: 7, down: 5);
    final Offset resolvedOffset = visualOffset.resolve(TextDirection.ltr);
    final List<_PointerChainCase> cases = <_PointerChainCase>[
      const _PointerChainCase(
        label: 'visual-bottom',
        placement: SpotlightGuidePlacement.bottom,
        targetLeft: 320,
        targetTop: 120,
      ),
      const _PointerChainCase(
        label: 'visual-top',
        placement: SpotlightGuidePlacement.top,
        targetLeft: 320,
        targetTop: 420,
      ),
      const _PointerChainCase(
        label: 'visual-left',
        placement: SpotlightGuidePlacement.left,
        targetLeft: 560,
        targetTop: 260,
      ),
      const _PointerChainCase(
        label: 'visual-right',
        placement: SpotlightGuidePlacement.right,
        targetLeft: 80,
        targetTop: 260,
      ),
    ];

    for (final _PointerChainCase testCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${testCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: 92,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                pointer: SpotlightGuidePointer(
                  size: testCase.pointerSize,
                  visualOffset: visualOffset,
                  child: SizedBox(
                    key: pointerKey,
                    width: testCase.pointerSize.width,
                    height: testCase.pointerSize.height,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[testCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 92, height: 44),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[testCase.label]!;
      final Rect visualPointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      switch (guide.anchorDirection) {
        case SpotlightGuideDirection.up:
          final double slotTop = guide.targetRect.bottom;
          expect(
            visualPointerRect.center.dx,
            moreOrLessEquals(
              guide.targetAnchorPoint.dx + resolvedOffset.dx,
              epsilon: 0.5,
            ),
          );
          expect(
            visualPointerRect.top,
            moreOrLessEquals(slotTop + resolvedOffset.dy, epsilon: 0.5),
          );
          expect(
            bubbleRect.top,
            moreOrLessEquals(
              slotTop + testCase.pointerSize.height + gap,
              epsilon: 0.5,
            ),
          );
          expect(
            bubbleRect.left + guide.anchorOffset,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
        case SpotlightGuideDirection.down:
          final double slotBottom = guide.targetRect.top;
          expect(
            visualPointerRect.center.dx,
            moreOrLessEquals(
              guide.targetAnchorPoint.dx + resolvedOffset.dx,
              epsilon: 0.5,
            ),
          );
          expect(
            visualPointerRect.bottom,
            moreOrLessEquals(slotBottom + resolvedOffset.dy, epsilon: 0.5),
          );
          expect(
            bubbleRect.bottom,
            moreOrLessEquals(
              slotBottom - testCase.pointerSize.height - gap,
              epsilon: 0.5,
            ),
          );
          expect(
            bubbleRect.left + guide.anchorOffset,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
        case SpotlightGuideDirection.left:
          final double slotLeft = guide.targetRect.right;
          expect(
            visualPointerRect.center.dy,
            moreOrLessEquals(
              guide.targetAnchorPoint.dy + resolvedOffset.dy,
              epsilon: 0.5,
            ),
          );
          expect(
            visualPointerRect.left,
            moreOrLessEquals(slotLeft + resolvedOffset.dx, epsilon: 0.5),
          );
          expect(
            bubbleRect.left,
            moreOrLessEquals(
              slotLeft + testCase.pointerSize.width + gap,
              epsilon: 0.5,
            ),
          );
          expect(
            bubbleRect.top + guide.anchorOffset,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
        case SpotlightGuideDirection.right:
          final double slotRight = guide.targetRect.left;
          expect(
            visualPointerRect.center.dy,
            moreOrLessEquals(
              guide.targetAnchorPoint.dy + resolvedOffset.dy,
              epsilon: 0.5,
            ),
          );
          expect(
            visualPointerRect.right,
            moreOrLessEquals(slotRight + resolvedOffset.dx, epsilon: 0.5),
          );
          expect(
            bubbleRect.right,
            moreOrLessEquals(
              slotRight - testCase.pointerSize.width - gap,
              epsilon: 0.5,
            ),
          );
          expect(
            bubbleRect.top + guide.anchorOffset,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
      }
    }
  });

  testWidgets('directional visualOffset mirrors horizontally in RTL', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
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
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                visualOffset: SpotlightGuidePointerOffset.directional(
                  end: 6,
                  up: 3,
                ),
                child: SizedBox(
                  key: ValueKey<String>('rtl-visual-offset-pointer'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['rtl-visual-offset'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['rtl-visual-offset']!;
    final Rect visualPointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('rtl-visual-offset-pointer')),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));

    expect(
      visualPointerRect.center.dx,
      moreOrLessEquals(guide.targetAnchorPoint.dx - 6, epsilon: 0.5),
    );
    expect(
      visualPointerRect.top,
      moreOrLessEquals(guide.targetRect.bottom - 3, epsilon: 0.5),
    );
    expect(
      bubbleRect.left + guide.anchorOffset,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

  testWidgets('bubbleSide controls the bubble side after pointer placement', (
    tester,
  ) async {
    const double gap = 10;
    final List<_BubbleSideCase> cases = <_BubbleSideCase>[
      const _BubbleSideCase(
        label: 'bubble-below-side-pointer',
        stepPlacement: SpotlightGuidePlacement.left,
        bubbleSide: SpotlightGuideBubbleSide.bottom,
        expectedAnchorDirection: SpotlightGuideDirection.up,
        targetLeft: 520,
        targetTop: 220,
        targetWidth: 120,
        targetHeight: 96,
        pointerSize: Size(36, 36),
      ),
      const _BubbleSideCase(
        label: 'bubble-above-side-pointer',
        stepPlacement: SpotlightGuidePlacement.left,
        bubbleSide: SpotlightGuideBubbleSide.top,
        expectedAnchorDirection: SpotlightGuideDirection.down,
        targetLeft: 520,
        targetTop: 260,
        targetWidth: 120,
        targetHeight: 96,
        pointerSize: Size(36, 36),
      ),
      const _BubbleSideCase(
        label: 'bubble-left-below-pointer',
        stepPlacement: SpotlightGuidePlacement.bottom,
        bubbleSide: SpotlightGuideBubbleSide.left,
        expectedAnchorDirection: SpotlightGuideDirection.right,
        targetLeft: 300,
        targetTop: 120,
        targetWidth: 128,
        targetHeight: 70,
        pointerSize: Size(34, 34),
      ),
      const _BubbleSideCase(
        label: 'bubble-right-below-pointer',
        stepPlacement: SpotlightGuidePlacement.bottom,
        bubbleSide: SpotlightGuideBubbleSide.right,
        expectedAnchorDirection: SpotlightGuideDirection.left,
        targetLeft: 300,
        targetTop: 120,
        targetWidth: 128,
        targetHeight: 70,
        pointerSize: Size(34, 34),
      ),
    ];

    for (final _BubbleSideCase testCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${testCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: testCase.targetWidth,
            height: testCase.targetHeight,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.stepPlacement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                pointer: SpotlightGuidePointer(
                  size: testCase.pointerSize,
                  bubbleSide: testCase.bubbleSide,
                  child: SizedBox(
                    key: pointerKey,
                    width: testCase.pointerSize.width,
                    height: testCase.pointerSize.height,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[testCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 96, height: 42),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[testCase.label]!;
      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      final SpotlightGuideAnchorGeometry anchorGeometry = _bubbleAnchorGeometry(
        tester,
      );

      expect(anchorGeometry.direction, testCase.expectedAnchorDirection);
      switch (testCase.bubbleSide) {
        case SpotlightGuideBubbleSide.bottom:
          expect(
            pointerRect.right,
            moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
          );
          expect(
            pointerRect.center.dy,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
          expect(
            bubbleRect.top,
            moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
          );
          expect(
            bubbleRect.left + anchorGeometry.offset,
            moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
          );
        case SpotlightGuideBubbleSide.top:
          expect(
            pointerRect.right,
            moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
          );
          expect(
            pointerRect.center.dy,
            moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
          );
          expect(
            bubbleRect.bottom,
            moreOrLessEquals(pointerRect.top - gap, epsilon: 0.5),
          );
          expect(
            bubbleRect.left + anchorGeometry.offset,
            moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
          );
        case SpotlightGuideBubbleSide.left:
          expect(
            pointerRect.top,
            moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
          );
          expect(
            pointerRect.center.dx,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
          expect(
            bubbleRect.right,
            moreOrLessEquals(pointerRect.left - gap, epsilon: 0.5),
          );
          expect(
            bubbleRect.top + anchorGeometry.offset,
            moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
          );
        case SpotlightGuideBubbleSide.right:
          expect(
            pointerRect.top,
            moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
          );
          expect(
            pointerRect.center.dx,
            moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
          );
          expect(
            bubbleRect.left,
            moreOrLessEquals(pointerRect.right + gap, epsilon: 0.5),
          );
          expect(
            bubbleRect.top + anchorGeometry.offset,
            moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
          );
        case SpotlightGuideBubbleSide.start ||
            SpotlightGuideBubbleSide.end ||
            SpotlightGuideBubbleSide.along:
          fail('semantic and along placements are not used by this case');
      }
    }
  });

  testWidgets('same-axis bubbleSide matches along geometry', (tester) async {
    const double gap = 10;
    final List<_SameAxisBubbleSideCase> cases = <_SameAxisBubbleSideCase>[
      const _SameAxisBubbleSideCase(
        label: 'top',
        placement: SpotlightGuidePlacement.top,
        bubbleSide: SpotlightGuideBubbleSide.top,
        targetLeft: 300,
        targetTop: 420,
        targetWidth: 128,
        targetHeight: 70,
        pointerSize: Size(88, 42),
      ),
      const _SameAxisBubbleSideCase(
        label: 'bottom',
        placement: SpotlightGuidePlacement.bottom,
        bubbleSide: SpotlightGuideBubbleSide.bottom,
        targetLeft: 300,
        targetTop: 90,
        targetWidth: 128,
        targetHeight: 70,
        pointerSize: Size(88, 42),
      ),
      const _SameAxisBubbleSideCase(
        label: 'left',
        placement: SpotlightGuidePlacement.left,
        bubbleSide: SpotlightGuideBubbleSide.left,
        targetLeft: 560,
        targetTop: 250,
        targetWidth: 120,
        targetHeight: 86,
        pointerSize: Size(42, 88),
      ),
      const _SameAxisBubbleSideCase(
        label: 'right',
        placement: SpotlightGuidePlacement.right,
        bubbleSide: SpotlightGuideBubbleSide.right,
        targetLeft: 90,
        targetTop: 250,
        targetWidth: 120,
        targetHeight: 86,
        pointerSize: Size(42, 88),
      ),
    ];

    Future<({Rect bubble, Rect pointer})> pumpLayout(
      _SameAxisBubbleSideCase testCase,
      SpotlightGuideBubbleSide bubbleSide,
    ) async {
      final String label = '${testCase.label}-${bubbleSide.name}';
      final ValueKey<String> pointerKey = ValueKey<String>('$label-pointer');

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
          child: singleTargetStack(
            id: 'a',
            left: testCase.targetLeft,
            top: testCase.targetTop,
            width: testCase.targetWidth,
            height: testCase.targetHeight,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: testCase.placement,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: gap,
                pointer: SpotlightGuidePointer(
                  size: testCase.pointerSize,
                  bubbleSide: bubbleSide,
                  child: SizedBox(
                    key: pointerKey,
                    width: testCase.pointerSize.width,
                    height: testCase.pointerSize.height,
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 112, height: 56),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      return (
        bubble: tester.getRect(find.byType(SpotlightGuideBubble)),
        pointer: tester.getRect(find.byKey(pointerKey)),
      );
    }

    for (final _SameAxisBubbleSideCase testCase in cases) {
      final ({Rect bubble, Rect pointer}) along = await pumpLayout(
        testCase,
        SpotlightGuideBubbleSide.along,
      );
      final ({Rect bubble, Rect pointer}) explicit = await pumpLayout(
        testCase,
        testCase.bubbleSide,
      );

      _expectRectsNearlyEqual(explicit.bubble, along.bubble, <String>[
        'case=${testCase.label} bubble',
      ]);
      _expectRectsNearlyEqual(explicit.pointer, along.pointer, <String>[
        'case=${testCase.label} pointer',
      ]);
    }
  });

  testWidgets('explicit-side pointer bubble stays inside reported hint bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 96,
          top: 360,
          width: 238,
          height: 74,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.verticalAuto,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              margin: const EdgeInsets.all(16),
              minWidth: 180,
              maxWidth: 300,
              pointer: const SpotlightGuidePointer(
                size: Size(88, 42),
                targetGap: 4,
                bubbleSide: SpotlightGuideBubbleSide.bottom,
                child: SizedBox(
                  key: ValueKey<String>('explicit-bottom-pointer'),
                  width: 88,
                  height: 42,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: Center(
                          child: TextButton(
                            key: const ValueKey<String>('explicit-bottom-next'),
                            onPressed: guide.next,
                            child: const Text('Next'),
                          ),
                        ),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final Rect hintRect = tester.getRect(find.byType(SpotlightGuideBubbleHint));
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('explicit-bottom-pointer')),
    );
    final Rect buttonRect = tester.getRect(
      find.byKey(const ValueKey<String>('explicit-bottom-next')),
    );

    final String geometry =
        'hint=$hintRect bubble=$bubbleRect pointer=$pointerRect button=$buttonRect';
    expect(
      hintRect.left,
      lessThanOrEqualTo(bubbleRect.left + 0.5),
      reason: geometry,
    );
    expect(
      hintRect.top,
      lessThanOrEqualTo(bubbleRect.top + 0.5),
      reason: geometry,
    );
    expect(
      hintRect.right,
      greaterThanOrEqualTo(bubbleRect.right - 0.5),
      reason: geometry,
    );
    expect(
      hintRect.bottom,
      greaterThanOrEqualTo(bubbleRect.bottom - 0.5),
      reason: geometry,
    );
    expect(hintRect.contains(pointerRect.center), isTrue, reason: geometry);
    expect(hintRect.contains(buttonRect.center), isTrue, reason: geometry);
    expect(
      find.byKey(const ValueKey<String>('explicit-bottom-next')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('bubbleSide start and end resolve against Directionality', (
    tester,
  ) async {
    final List<_SemanticBubbleSideCase> cases = <_SemanticBubbleSideCase>[
      const _SemanticBubbleSideCase(
        label: 'ltr-start-bubble',
        textDirection: TextDirection.ltr,
        bubbleSide: SpotlightGuideBubbleSide.start,
        expectedAnchorDirection: SpotlightGuideDirection.right,
      ),
      const _SemanticBubbleSideCase(
        label: 'ltr-end-bubble',
        textDirection: TextDirection.ltr,
        bubbleSide: SpotlightGuideBubbleSide.end,
        expectedAnchorDirection: SpotlightGuideDirection.left,
      ),
      const _SemanticBubbleSideCase(
        label: 'rtl-start-bubble',
        textDirection: TextDirection.rtl,
        bubbleSide: SpotlightGuideBubbleSide.start,
        expectedAnchorDirection: SpotlightGuideDirection.left,
      ),
      const _SemanticBubbleSideCase(
        label: 'rtl-end-bubble',
        textDirection: TextDirection.rtl,
        bubbleSide: SpotlightGuideBubbleSide.end,
        expectedAnchorDirection: SpotlightGuideDirection.right,
      ),
    ];

    for (final _SemanticBubbleSideCase testCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      final ValueKey<String> pointerKey = ValueKey<String>(
        '${testCase.label}-pointer',
      );

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(testCase.label),
          textDirection: testCase.textDirection,
          child: singleTargetStack(
            id: 'a',
            left: 300,
            top: 120,
            width: 128,
            height: 70,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                gap: 8,
                pointer: SpotlightGuidePointer(
                  size: const Size(34, 34),
                  bubbleSide: testCase.bubbleSide,
                  child: SizedBox(
                    key: pointerKey,
                    width: 34,
                    height: 34,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[testCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 96, height: 42),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      final SpotlightGuideAnchorGeometry anchorGeometry = _bubbleAnchorGeometry(
        tester,
      );
      final bool bubbleIsOnLeft =
          testCase.expectedAnchorDirection == SpotlightGuideDirection.right;

      expect(anchorGeometry.direction, testCase.expectedAnchorDirection);
      if (bubbleIsOnLeft) {
        expect(bubbleRect.right, lessThanOrEqualTo(pointerRect.left - 7.5));
        expect(
          bubbleRect.top + anchorGeometry.offset,
          moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
        );
      } else {
        expect(bubbleRect.left, greaterThanOrEqualTo(pointerRect.right + 7.5));
        expect(
          bubbleRect.top + anchorGeometry.offset,
          moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
        );
      }
      expect(
        contexts[testCase.label]!.placement,
        SpotlightGuidePlacement.bottom,
      );
    }
  });

  testWidgets(
    'targetAnchorPosition resolves on pointer while pointerAnchorPosition places pointer',
    (tester) async {
      final List<_PointerAnchorRtlCase> cases = <_PointerAnchorRtlCase>[
        const _PointerAnchorRtlCase(
          label: 'rtl-pointer-start',
          pointerAnchorPosition: SpotlightGuideAnchorPosition.start(),
        ),
        const _PointerAnchorRtlCase(
          label: 'rtl-pointer-end',
          pointerAnchorPosition: SpotlightGuideAnchorPosition.end(),
        ),
      ];

      for (final _PointerAnchorRtlCase testCase in cases) {
        final Map<String, SpotlightGuideStepContext> contexts =
            <String, SpotlightGuideStepContext>{};
        final ValueKey<String> pointerKey = ValueKey<String>(
          '${testCase.label}-pointer',
        );

        await tester.pumpWidget(
          guideApp(
            appKey: ValueKey<String>(testCase.label),
            textDirection: TextDirection.rtl,
            child: singleTargetStack(
              id: 'a',
              left: 300,
              top: 120,
              width: 128,
              height: 70,
            ),
            steps: <SpotlightGuideStep>[
              SpotlightGuideStep.item(
                SpotlightGuideStepItem(
                  targetId: 'a',
                  placement: SpotlightGuidePlacement.bottom,
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  targetAnchorPosition: testCase.pointerAnchorPosition,
                  pointer: SpotlightGuidePointer(
                    size: const Size(40, 24),
                    pointerAnchorPosition: testCase.pointerAnchorPosition,
                    bubbleSide: SpotlightGuideBubbleSide.bottom,
                    child: SizedBox(
                      key: pointerKey,
                      width: 40,
                      height: 24,
                      child: const ColoredBox(color: Colors.yellow),
                    ),
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        contexts[testCase.label] = guide;
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: const SizedBox(width: 96, height: 42),
                        );
                      },
                ),
              ),
            ],
          ),
        );
        await pumpGuide(tester);

        final SpotlightGuideStepContext guide = contexts[testCase.label]!;
        final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
        final Rect bubbleRect = tester.getRect(
          find.byType(SpotlightGuideBubble),
        );
        final SpotlightGuideAnchorGeometry anchorGeometry =
            _bubbleAnchorGeometry(tester);
        final double pointerTargetX = _pointerAnchorAxisPosition(
          pointerRect,
          testCase.pointerAnchorPosition,
          isHorizontalAxis: true,
          textDirection: TextDirection.rtl,
        );
        final double bubbleAnchorX = _pointerAnchorAxisPosition(
          pointerRect,
          guide.targetAnchorPosition,
          isHorizontalAxis: true,
          textDirection: TextDirection.rtl,
        );

        expect(
          pointerTargetX,
          moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
        );
        expect(
          bubbleRect.left + anchorGeometry.offset,
          moreOrLessEquals(bubbleAnchorX, epsilon: 0.5),
        );
        expect(anchorGeometry.direction, SpotlightGuideDirection.up);
      }
    },
  );

  testWidgets(
    'targetAnchorPosition center offset moves bubble anchor without moving pointer',
    (tester) async {
      final List<_PointerTargetAnchorOffsetCase> cases =
          <_PointerTargetAnchorOffsetCase>[
            const _PointerTargetAnchorOffsetCase(
              label: 'bottom-positive',
              placement: SpotlightGuidePlacement.bottom,
              targetLeft: 300,
              targetTop: 120,
              anchorPosition: SpotlightGuideAnchorPosition.center(9),
            ),
            const _PointerTargetAnchorOffsetCase(
              label: 'top-negative',
              placement: SpotlightGuidePlacement.top,
              targetLeft: 300,
              targetTop: 420,
              anchorPosition: SpotlightGuideAnchorPosition.center(-7),
            ),
            const _PointerTargetAnchorOffsetCase(
              label: 'left-positive',
              placement: SpotlightGuidePlacement.left,
              targetLeft: 560,
              targetTop: 250,
              anchorPosition: SpotlightGuideAnchorPosition.center(11),
            ),
            const _PointerTargetAnchorOffsetCase(
              label: 'right-negative',
              placement: SpotlightGuidePlacement.right,
              targetLeft: 80,
              targetTop: 250,
              anchorPosition: SpotlightGuideAnchorPosition.center(-5),
            ),
            const _PointerTargetAnchorOffsetCase(
              label: 'rtl-bottom-positive',
              placement: SpotlightGuidePlacement.bottom,
              targetLeft: 300,
              targetTop: 120,
              textDirection: TextDirection.rtl,
              anchorPosition: SpotlightGuideAnchorPosition.center(9),
            ),
          ];

      for (final _PointerTargetAnchorOffsetCase testCase in cases) {
        final Map<String, SpotlightGuideStepContext> contexts =
            <String, SpotlightGuideStepContext>{};
        final ValueKey<String> pointerKey = ValueKey<String>(
          '${testCase.label}-pointer',
        );

        await tester.pumpWidget(
          guideApp(
            appKey: ValueKey<String>(testCase.label),
            textDirection: testCase.textDirection,
            child: singleTargetStack(
              id: 'a',
              left: testCase.targetLeft,
              top: testCase.targetTop,
              width: 100,
              height: 60,
            ),
            steps: <SpotlightGuideStep>[
              SpotlightGuideStep.item(
                SpotlightGuideStepItem(
                  targetId: 'a',
                  placement: testCase.placement,
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  targetAnchorPosition: testCase.anchorPosition,
                  gap: 10,
                  pointer: SpotlightGuidePointer(
                    size: const Size(40, 28),
                    child: SizedBox(
                      key: pointerKey,
                      width: 40,
                      height: 28,
                      child: const ColoredBox(color: Colors.yellow),
                    ),
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        contexts[testCase.label] = guide;
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: const SizedBox(width: 110, height: 44),
                        );
                      },
                ),
              ),
            ],
          ),
        );
        await pumpGuide(tester);

        final SpotlightGuideStepContext guide = contexts[testCase.label]!;
        final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
        final Rect bubbleRect = tester.getRect(
          find.byType(SpotlightGuideBubble),
        );
        final SpotlightGuideAnchorGeometry anchorGeometry =
            _bubbleAnchorGeometry(tester);
        final bool horizontalAnchorAxis =
            guide.anchorDirection == SpotlightGuideDirection.up ||
            guide.anchorDirection == SpotlightGuideDirection.down;
        final double pointerTargetAxis = horizontalAnchorAxis
            ? pointerRect.center.dx
            : pointerRect.center.dy;
        final double targetCenterAxis = horizontalAnchorAxis
            ? guide.targetRect.center.dx
            : guide.targetRect.center.dy;
        final double pointerAnchorAxis = _pointerAnchorAxisPosition(
          pointerRect,
          testCase.anchorPosition,
          isHorizontalAxis: horizontalAnchorAxis,
          textDirection: testCase.textDirection,
        );

        expect(
          pointerTargetAxis,
          moreOrLessEquals(targetCenterAxis, epsilon: 0.5),
          reason: '${testCase.label}: pointer should stay on target center',
        );
        expect(
          _bubbleAnchorGlobalAxis(bubbleRect, anchorGeometry),
          moreOrLessEquals(pointerAnchorAxis, epsilon: 0.5),
          reason:
              '${testCase.label}: bubble anchor should use targetAnchorPosition on pointer',
        );
      }
    },
  );

  testWidgets('anchor safety expands bubble without moving the pointer', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 260,
          top: 120,
          width: 120,
          height: 64,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              targetAnchorPosition: const SpotlightGuideAnchorPosition.start(),
              decoration: const SpotlightGuideBubbleDecoration(
                borderRadius: 28,
              ),
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                pointerAnchorPosition: SpotlightGuideAnchorPosition.start(),
                bubbleSide: SpotlightGuideBubbleSide.bottom,
                child: SizedBox(
                  key: ValueKey<String>('safe-pointer'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['safe-pointer'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 24, height: 24),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['safe-pointer']!;
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('safe-pointer')),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final SpotlightGuideBubbleDecoration bubbleDecoration = _bubbleDecoration(
      tester,
    );
    final SpotlightGuideAnchorGeometry anchorGeometry =
        bubbleDecoration.effectiveAnchorGeometry!;
    final double safeInset = bubbleDecoration.anchorSafeInset;

    expect(
      pointerRect.left,
      moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
    );
    expect(anchorGeometry.offset, greaterThanOrEqualTo(safeInset));
    expect(
      anchorGeometry.offset,
      lessThanOrEqualTo(bubbleRect.width - safeInset),
    );
    expect(bubbleRect.width, greaterThanOrEqualTo(safeInset * 2 - 0.5));
    expect(
      bubbleRect.left + anchorGeometry.offset,
      moreOrLessEquals(pointerRect.left, epsilon: 0.5),
    );
  });

  testWidgets('anchorMode target ignores bubbleSide for bubble layout', (
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
              gap: 14,
              pointer: const SpotlightGuidePointer(
                anchorMode: SpotlightGuidePointerAnchorMode.target,
                bubbleSide: SpotlightGuideBubbleSide.bottom,
                size: Size(36, 24),
                child: SizedBox(
                  key: ValueKey<String>('target-mode-pointer'),
                  width: 36,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['target-anchor-mode'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['target-anchor-mode']!;
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final SpotlightGuideAnchorGeometry anchorGeometry = _bubbleAnchorGeometry(
      tester,
    );

    expect(anchorGeometry.direction, guide.anchorDirection);
    expect(
      bubbleRect.top,
      moreOrLessEquals(guide.targetRect.bottom + guide.gap, epsilon: 0.5),
    );
    expect(
      bubbleRect.left + anchorGeometry.offset,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
  });

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
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                child: SizedBox(
                  key: ValueKey<String>('pointer'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
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
                pointer: SpotlightGuidePointer(
                  size: const Size(24, 40),
                  child: SizedBox(
                    key: pointerKey,
                    width: 24,
                    height: 40,
                    child: const ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts[placementCase.label] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
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
      guide.hintRect.left + guide.anchorOffset,
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
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                child: SizedBox(
                  key: ValueKey<String>('pointer-top'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer-top'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
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
    expect(guide.anchorDirection, SpotlightGuideDirection.down);
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

  testWidgets('pointer anchor position end aligns pointer end to the target', (
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
              pointer: const SpotlightGuidePointer(
                size: Size(40, 24),
                pointerAnchorPosition: SpotlightGuideAnchorPosition.end(),
                child: SizedBox(
                  key: ValueKey<String>('pointer-end'),
                  width: 40,
                  height: 24,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['pointer-end'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
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
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    final SpotlightGuideAnchorGeometry anchorGeometry = _bubbleAnchorGeometry(
      tester,
    );
    // With an end pointer anchor in LTR, the pointer's right edge aligns with
    // the target anchor. The bubble anchor still aims at the pointer center.
    expect(
      pointerRect.right,
      moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
    );
    expect(
      bubbleRect.left + anchorGeometry.offset,
      moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
    );
  });

  testWidgets(
    'pointer hint is stable on the first visible frame after reveal scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              width: 390,
              height: 1200,
              child: Stack(
                children: const <Widget>[
                  Positioned(
                    left: 120,
                    top: 48,
                    child: SpotlightGuideTarget(
                      id: 'start',
                      child: SizedBox(
                        width: 96,
                        height: 48,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 920,
                    child: SpotlightGuideTarget(
                      id: 'edge',
                      child: SizedBox(
                        width: 92,
                        height: 58,
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
                targetId: 'start',
                placement: SpotlightGuidePlacement.bottom,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: SizedBox(
                          width: 120,
                          height: 52,
                          child: Center(
                            child: TextButton(
                              key: const ValueKey<String>('stable-next-button'),
                              onPressed: guide.next,
                              child: const Text('Next'),
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'edge',
                placement: SpotlightGuidePlacement.right,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                targetAnchorPosition: const SpotlightGuideAnchorPosition.start(
                  12,
                ),
                margin: const EdgeInsets.all(18),
                minWidth: 180,
                maxWidth: 300,
                gap: 10,
                pointer: const SpotlightGuidePointer(
                  size: Size(32, 48),
                  targetGap: 4,
                  child: SizedBox(
                    key: ValueKey<String>('stable-edge-pointer'),
                    width: 32,
                    height: 48,
                    child: ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 112, height: 72),
                      );
                    },
              ),
            ),
          ],
        ),
      );

      controller.showPortal();
      await pumpGuide(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('stable-next-button')).hitTestable(),
      );

      final List<_PointerVisibleGeometry> visibleFrames =
          <_PointerVisibleGeometry>[];
      final List<String> frameDebug = <String>[];
      for (int frame = 0; frame < 90 && visibleFrames.length < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final Finder pointerFinder = find.byKey(
          const ValueKey<String>('stable-edge-pointer'),
        );
        if (pointerFinder.evaluate().isEmpty ||
            _hintOpacityFor(tester, pointerFinder) < 1) {
          continue;
        }
        final _PointerVisibleGeometry geometry = _pointerVisibleGeometry(
          tester,
          pointerFinder,
        );
        visibleFrames.add(geometry);
        frameDebug.add(
          'frame=$frame scroll=${scrollController.offset} '
          'pointer=${geometry.pointer} bubble=${geometry.bubble} '
          'anchor=${geometry.anchorDirection}/${geometry.anchorOffset}',
        );
      }

      expect(scrollController.offset, greaterThan(0));
      expect(visibleFrames, hasLength(4));
      final _PointerVisibleGeometry first = visibleFrames.first;
      for (final _PointerVisibleGeometry frame in visibleFrames.skip(1)) {
        _expectRectsNearlyEqual(frame.pointer, first.pointer, frameDebug);
        _expectRectsNearlyEqual(frame.bubble, first.bubble, frameDebug);
        expect(
          frame.anchorDirection,
          first.anchorDirection,
          reason: 'anchor direction should not change after the hint appears',
        );
        expect(
          frame.anchorOffset,
          moreOrLessEquals(first.anchorOffset, epsilon: 0.5),
          reason: 'anchor offset should not shift after the hint appears',
        );
      }
    },
  );
}

class _PointerChainCase {
  const _PointerChainCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
    required this.targetTop,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
  final double targetTop;

  Size get pointerSize {
    return switch (placement) {
      SpotlightGuidePlacement.top ||
      SpotlightGuidePlacement.bottom => const Size(40, 28),
      SpotlightGuidePlacement.left ||
      SpotlightGuidePlacement.right => const Size(28, 40),
      SpotlightGuidePlacement.auto ||
      SpotlightGuidePlacement.verticalAuto ||
      SpotlightGuidePlacement.horizontalAuto ||
      SpotlightGuidePlacement.start ||
      SpotlightGuidePlacement.end => throw StateError(
        'Only fixed placements are supported by this pointer chain test.',
      ),
    };
  }
}

class _PointerTargetAnchorOffsetCase {
  const _PointerTargetAnchorOffsetCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
    required this.targetTop,
    required this.anchorPosition,
    this.textDirection = TextDirection.ltr,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
  final double targetTop;
  final SpotlightGuideAnchorPosition anchorPosition;
  final TextDirection textDirection;
}

class _BubbleSideCase {
  const _BubbleSideCase({
    required this.label,
    required this.stepPlacement,
    required this.bubbleSide,
    required this.expectedAnchorDirection,
    required this.targetLeft,
    required this.targetTop,
    required this.targetWidth,
    required this.targetHeight,
    required this.pointerSize,
  });

  final String label;
  final SpotlightGuidePlacement stepPlacement;
  final SpotlightGuideBubbleSide bubbleSide;
  final SpotlightGuideDirection expectedAnchorDirection;
  final double targetLeft;
  final double targetTop;
  final double targetWidth;
  final double targetHeight;
  final Size pointerSize;
}

class _SameAxisBubbleSideCase {
  const _SameAxisBubbleSideCase({
    required this.label,
    required this.placement,
    required this.bubbleSide,
    required this.targetLeft,
    required this.targetTop,
    required this.targetWidth,
    required this.targetHeight,
    required this.pointerSize,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final SpotlightGuideBubbleSide bubbleSide;
  final double targetLeft;
  final double targetTop;
  final double targetWidth;
  final double targetHeight;
  final Size pointerSize;
}

class _SemanticBubbleSideCase {
  const _SemanticBubbleSideCase({
    required this.label,
    required this.textDirection,
    required this.bubbleSide,
    required this.expectedAnchorDirection,
  });

  final String label;
  final TextDirection textDirection;
  final SpotlightGuideBubbleSide bubbleSide;
  final SpotlightGuideDirection expectedAnchorDirection;
}

class _PointerAnchorRtlCase {
  const _PointerAnchorRtlCase({
    required this.label,
    required this.pointerAnchorPosition,
  });

  final String label;
  final SpotlightGuideAnchorPosition pointerAnchorPosition;
}

SpotlightGuideBubbleDecoration _bubbleDecoration(WidgetTester tester) {
  final dynamic bubble = tester.renderObject(find.byType(SpotlightGuideBubble));
  return bubble.effectiveDecoration as SpotlightGuideBubbleDecoration;
}

SpotlightGuideAnchorGeometry _bubbleAnchorGeometry(WidgetTester tester) {
  return _bubbleDecoration(tester).effectiveAnchorGeometry!;
}

void _expectPointerMainAxisTouchesTarget(
  Rect pointerRect,
  SpotlightGuideStepContext guide,
) {
  switch (guide.anchorDirection) {
    case SpotlightGuideDirection.up:
      expect(pointerRect.top, moreOrLessEquals(guide.targetRect.bottom));
    case SpotlightGuideDirection.down:
      expect(pointerRect.bottom, moreOrLessEquals(guide.targetRect.top));
    case SpotlightGuideDirection.left:
      expect(pointerRect.left, moreOrLessEquals(guide.targetRect.right));
    case SpotlightGuideDirection.right:
      expect(pointerRect.right, moreOrLessEquals(guide.targetRect.left));
  }
}

double _pointerAnchorAxisPosition(
  Rect pointerRect,
  SpotlightGuideAnchorPosition position, {
  required bool isHorizontalAxis,
  required TextDirection textDirection,
}) {
  final bool reverse = isHorizontalAxis && textDirection == TextDirection.rtl;
  return switch (position.anchor) {
    SpotlightGuideAnchorAlignment.center =>
      (isHorizontalAxis ? pointerRect.center.dx : pointerRect.center.dy) +
          (reverse ? -position.offset : position.offset),
    SpotlightGuideAnchorAlignment.start =>
      isHorizontalAxis
          ? reverse
                ? pointerRect.right - position.offset
                : pointerRect.left + position.offset
          : pointerRect.top + position.offset,
    SpotlightGuideAnchorAlignment.end =>
      isHorizontalAxis
          ? reverse
                ? pointerRect.left + position.offset
                : pointerRect.right - position.offset
          : pointerRect.bottom - position.offset,
  };
}

double _bubbleAnchorGlobalAxis(
  Rect bubbleRect,
  SpotlightGuideAnchorGeometry anchorGeometry,
) {
  return switch (anchorGeometry.direction) {
    SpotlightGuideDirection.up ||
    SpotlightGuideDirection.down => bubbleRect.left + anchorGeometry.offset,
    SpotlightGuideDirection.left ||
    SpotlightGuideDirection.right => bubbleRect.top + anchorGeometry.offset,
  };
}

class _PointerVisibleGeometry {
  const _PointerVisibleGeometry({
    required this.pointer,
    required this.bubble,
    required this.anchorDirection,
    required this.anchorOffset,
  });

  final Rect pointer;
  final Rect bubble;
  final SpotlightGuideDirection anchorDirection;
  final double anchorOffset;
}

_PointerVisibleGeometry _pointerVisibleGeometry(
  WidgetTester tester,
  Finder pointerFinder,
) {
  final SpotlightGuideAnchorGeometry anchorGeometry = _bubbleAnchorGeometry(
    tester,
  );
  return _PointerVisibleGeometry(
    pointer: tester.getRect(pointerFinder),
    bubble: tester.getRect(find.byType(SpotlightGuideBubble)),
    anchorDirection: anchorGeometry.direction,
    anchorOffset: anchorGeometry.offset,
  );
}

double _hintOpacityFor(WidgetTester tester, Finder finder) {
  final Iterable<Element> opacityElements = find
      .ancestor(of: finder, matching: find.byType(Opacity))
      .evaluate();
  for (final Element element in opacityElements) {
    final Opacity opacity = element.widget as Opacity;
    if (opacity.opacity == 0 || opacity.opacity == 1) {
      return opacity.opacity;
    }
  }
  return 1;
}

void _expectRectsNearlyEqual(
  Rect actual,
  Rect expected, [
  List<String> debug = const <String>[],
]) {
  final String reason = debug.join('\n');
  expect(
    actual.left,
    moreOrLessEquals(expected.left, epsilon: 0.5),
    reason: reason,
  );
  expect(
    actual.top,
    moreOrLessEquals(expected.top, epsilon: 0.5),
    reason: reason,
  );
  expect(
    actual.right,
    moreOrLessEquals(expected.right, epsilon: 0.5),
    reason: reason,
  );
  expect(
    actual.bottom,
    moreOrLessEquals(expected.bottom, epsilon: 0.5),
    reason: reason,
  );
}

double _normalizeRotation(double radians) {
  final double fullTurn = math.pi * 2;
  double normalized = radians % fullTurn;
  if (normalized > math.pi) {
    normalized -= fullTurn;
  } else if (normalized <= -math.pi) {
    normalized += fullTurn;
  }
  return normalized;
}
