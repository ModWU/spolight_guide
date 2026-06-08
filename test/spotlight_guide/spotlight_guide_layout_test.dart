import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Placement, constraints, safe-area, and RTL layout tests.
///
/// Run this file when changing [SpotlightGuidePlacement],
/// [SpotlightGuideAnchorPosition], margin resolution, min/max sizing, target
/// padding, arrow safe-area handling, or the measured-size cache in the overlay
/// layout.
void main() {
  testWidgets('target anchor start follows text direction', (tester) async {
    final Map<String, SpotlightGuideStepContext> ltrContexts =
        <String, SpotlightGuideStepContext>{};
    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.ltr,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.start(
                10,
              ),
              hintBuilder: hint('ltr-anchor', ltrContexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    final SpotlightGuideStepContext ltrContext = ltrContexts['ltr-anchor']!;
    expect(
      ltrContext.targetAnchorPoint.dx,
      moreOrLessEquals(ltrContext.targetRect.left + 10, epsilon: 0.5),
    );

    final Map<String, SpotlightGuideStepContext> rtlContexts =
        <String, SpotlightGuideStepContext>{};
    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.start(
                10,
              ),
              hintBuilder: hint('rtl-anchor', rtlContexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    final SpotlightGuideStepContext rtlContext = rtlContexts['rtl-anchor']!;
    expect(
      rtlContext.targetAnchorPoint.dx,
      moreOrLessEquals(rtlContext.targetRect.right - 10, epsilon: 0.5),
    );
  });

  testWidgets('fixed placements resolve expected arrow directions', (
    tester,
  ) async {
    final Map<SpotlightGuidePlacement, SpotlightGuideIndicatorDirection>
    expectedDirections =
        <SpotlightGuidePlacement, SpotlightGuideIndicatorDirection>{
          SpotlightGuidePlacement.top: SpotlightGuideIndicatorDirection.down,
          SpotlightGuidePlacement.bottom: SpotlightGuideIndicatorDirection.up,
          SpotlightGuidePlacement.left: SpotlightGuideIndicatorDirection.right,
          SpotlightGuidePlacement.right: SpotlightGuideIndicatorDirection.left,
        };

    for (final MapEntry<
          SpotlightGuidePlacement,
          SpotlightGuideIndicatorDirection
        >
        entry
        in expectedDirections.entries) {
      const double gap = 18;
      final String label = 'fixed-${entry.key.name}';
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
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
                placement: entry.key,
                targetPadding: EdgeInsets.zero,
                gap: gap,
                hintBuilder: hint(label, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[label]!;
      expect(guide.placement, entry.key);
      expect(guide.indicatorDirection, entry.value);
      switch (entry.key) {
        case SpotlightGuidePlacement.top:
          expect(
            guide.targetRect.top - guide.hintRect.bottom,
            moreOrLessEquals(gap, epsilon: 0.5),
          );
          break;
        case SpotlightGuidePlacement.bottom:
          expect(
            guide.hintRect.top - guide.targetRect.bottom,
            moreOrLessEquals(gap, epsilon: 0.5),
          );
          break;
        case SpotlightGuidePlacement.left:
          expect(
            guide.targetRect.left - guide.hintRect.right,
            moreOrLessEquals(gap, epsilon: 0.5),
          );
          break;
        case SpotlightGuidePlacement.right:
          expect(
            guide.hintRect.left - guide.targetRect.right,
            moreOrLessEquals(gap, epsilon: 0.5),
          );
          break;
        case SpotlightGuidePlacement.auto:
        case SpotlightGuidePlacement.verticalAuto:
        case SpotlightGuidePlacement.horizontalAuto:
        case SpotlightGuidePlacement.start:
        case SpotlightGuidePlacement.end:
          fail('auto placements are not part of this fixed placement test');
      }
    }
  });

  testWidgets('rtl keeps fixed indicator directions physical', (tester) async {
    final Map<SpotlightGuidePlacement, SpotlightGuideIndicatorDirection>
    expectedDirections =
        <SpotlightGuidePlacement, SpotlightGuideIndicatorDirection>{
          SpotlightGuidePlacement.left: SpotlightGuideIndicatorDirection.right,
          SpotlightGuidePlacement.right: SpotlightGuideIndicatorDirection.left,
        };

    for (final MapEntry<
          SpotlightGuidePlacement,
          SpotlightGuideIndicatorDirection
        >
        entry
        in expectedDirections.entries) {
      final String label = 'rtl-fixed-${entry.key.name}';
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
          locale: const Locale('ar'),
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
                placement: entry.key,
                targetPadding: EdgeInsets.zero,
                hintBuilder: hint(label, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[label]!;
      expect(guide.placement, entry.key);
      expect(guide.indicatorDirection, entry.value);
    }
  });

  testWidgets('semantic start and end placements follow text direction', (
    tester,
  ) async {
    final List<
      ({
        TextDirection direction,
        SpotlightGuidePlacement placement,
        SpotlightGuidePlacement expected,
        SpotlightGuideIndicatorDirection arrow,
      })
    >
    cases =
        <
          ({
            TextDirection direction,
            SpotlightGuidePlacement placement,
            SpotlightGuidePlacement expected,
            SpotlightGuideIndicatorDirection arrow,
          })
        >[
          (
            direction: TextDirection.ltr,
            placement: SpotlightGuidePlacement.start,
            expected: SpotlightGuidePlacement.left,
            arrow: SpotlightGuideIndicatorDirection.right,
          ),
          (
            direction: TextDirection.ltr,
            placement: SpotlightGuidePlacement.end,
            expected: SpotlightGuidePlacement.right,
            arrow: SpotlightGuideIndicatorDirection.left,
          ),
          (
            direction: TextDirection.rtl,
            placement: SpotlightGuidePlacement.start,
            expected: SpotlightGuidePlacement.right,
            arrow: SpotlightGuideIndicatorDirection.left,
          ),
          (
            direction: TextDirection.rtl,
            placement: SpotlightGuidePlacement.end,
            expected: SpotlightGuidePlacement.left,
            arrow: SpotlightGuideIndicatorDirection.right,
          ),
        ];

    for (final testCase in cases) {
      final String label =
          '${testCase.direction.name}-${testCase.placement.name}';
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
          textDirection: testCase.direction,
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
                targetPadding: EdgeInsets.zero,
                hintBuilder: hint(label, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[label]!;
      expect(guide.placement, testCase.expected);
      expect(guide.indicatorDirection, testCase.arrow);
    }
  });

  testWidgets('auto placements choose the available side', (tester) async {
    final List<PlacementCase> cases = <PlacementCase>[
      PlacementCase(
        label: 'vertical-bottom',
        placement: SpotlightGuidePlacement.verticalAuto,
        targetLeft: 320,
        targetTop: 20,
        expected: SpotlightGuidePlacement.bottom,
      ),
      PlacementCase(
        label: 'vertical-top',
        placement: SpotlightGuidePlacement.verticalAuto,
        targetLeft: 320,
        targetTop: 520,
        expected: SpotlightGuidePlacement.top,
      ),
      PlacementCase(
        label: 'vertical-near-middle-bottom',
        placement: SpotlightGuidePlacement.verticalAuto,
        targetLeft: 320,
        targetTop: 250,
        expected: SpotlightGuidePlacement.bottom,
      ),
      PlacementCase(
        label: 'horizontal-right',
        placement: SpotlightGuidePlacement.horizontalAuto,
        targetLeft: 20,
        targetTop: 260,
        expected: SpotlightGuidePlacement.right,
      ),
      PlacementCase(
        label: 'horizontal-left',
        placement: SpotlightGuidePlacement.horizontalAuto,
        targetLeft: 700,
        targetTop: 260,
        expected: SpotlightGuidePlacement.left,
      ),
      PlacementCase(
        label: 'horizontal-near-middle-left',
        placement: SpotlightGuidePlacement.horizontalAuto,
        targetLeft: 380,
        targetTop: 260,
        expected: SpotlightGuidePlacement.left,
      ),
      PlacementCase(
        label: 'auto-bottom',
        placement: SpotlightGuidePlacement.auto,
        targetLeft: 320,
        targetTop: 20,
        expected: SpotlightGuidePlacement.bottom,
      ),
      PlacementCase(
        label: 'auto-left',
        placement: SpotlightGuidePlacement.auto,
        targetLeft: 700,
        targetTop: 260,
        expected: SpotlightGuidePlacement.left,
      ),
    ];

    for (final PlacementCase placementCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(placementCase.label),
          child: singleTargetStack(
            id: 'a',
            left: placementCase.targetLeft,
            top: placementCase.targetTop,
            width: 60,
            height: 60,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: placementCase.placement,
                targetPadding: EdgeInsets.zero,
                hintBuilder: hint(placementCase.label, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      expect(contexts[placementCase.label]?.placement, placementCase.expected);
    }
  });

  testWidgets(
    'auto placement uses the full overlay, not the nearest scroll viewport',
    (tester) async {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 120,
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: const <Widget>[
                      Positioned(
                        left: 40,
                        top: 70,
                        child: SpotlightGuideTarget(
                          id: 'nested-scroll-target',
                          child: SizedBox(
                            width: 80,
                            height: 40,
                            child: ColoredBox(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'nested-scroll-target',
                placement: SpotlightGuidePlacement.verticalAuto,
                targetPadding: EdgeInsets.zero,
                hintBuilder: sizedHint('nested-scroll-auto', 180, 80, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['nested-scroll-auto']!;
      expect(guide.placement, SpotlightGuidePlacement.bottom);
      expect(guide.hintRect.top, greaterThan(guide.targetRect.bottom));
      expect(
        guide.overlaySize.height - guide.targetRect.bottom,
        greaterThan(guide.targetRect.top),
        reason:
            'the full-screen overlay has more room below even though the '
            'small scroll viewport has more room above',
      );
    },
  );

  testWidgets('vertical auto moves above a target near the bottom edge', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 520,
          width: 80,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.verticalAuto,
              targetPadding: EdgeInsets.zero,
              hintBuilder: sizedHint('bottom-edge-auto', 220, 120, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['bottom-edge-auto']!;
    expect(guide.placement, SpotlightGuidePlacement.top);
    expect(guide.hintRect.bottom, lessThan(guide.targetRect.top));
    expect(
      guide.hintRect.bottom,
      lessThanOrEqualTo(guide.overlaySize.height - 16),
    );
  });

  testWidgets('rtl mirrors start and end anchor semantics', (tester) async {
    final Map<String, SpotlightGuideStepContext> ltrContexts =
        <String, SpotlightGuideStepContext>{};
    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.ltr,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.end(12),
              hintBuilder: hint('ltr-end', ltrContexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    final SpotlightGuideStepContext ltrGuide = ltrContexts['ltr-end']!;
    expect(
      ltrGuide.targetAnchorPoint.dx,
      moreOrLessEquals(ltrGuide.targetRect.right - 12, epsilon: 0.5),
    );

    final Map<String, SpotlightGuideStepContext> rtlContexts =
        <String, SpotlightGuideStepContext>{};
    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.end(12),
              hintBuilder: hint('rtl-end', rtlContexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    final SpotlightGuideStepContext rtlGuide = rtlContexts['rtl-end']!;
    expect(
      rtlGuide.targetAnchorPoint.dx,
      moreOrLessEquals(rtlGuide.targetRect.left + 12, epsilon: 0.5),
    );
  });

  testWidgets('arabic rtl keeps semantic horizontal anchor behavior', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        child: singleTargetStack(
          id: 'a',
          left: 120,
          top: 120,
          width: 90,
          height: 50,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                targetAnchorPosition: const SpotlightGuideAnchorPosition.start(
                  8,
                ),
                hintBuilder: hint('arabic-start', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                targetAnchorPosition: const SpotlightGuideAnchorPosition.end(8),
                hintBuilder: hint('arabic-end', contexts),
              ),
            ],
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext startGuide = contexts['arabic-start']!;
    final SpotlightGuideStepContext endGuide = contexts['arabic-end']!;
    expect(
      startGuide.targetAnchorPoint.dx,
      moreOrLessEquals(startGuide.targetRect.right - 8, epsilon: 0.5),
    );
    expect(
      endGuide.targetAnchorPoint.dx,
      moreOrLessEquals(endGuide.targetRect.left + 8, epsilon: 0.5),
    );
  });

  testWidgets('directional margin resolves in rtl layouts', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
        child: singleTargetStack(
          id: 'a',
          left: 300,
          top: 120,
          width: 80,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: EdgeInsets.zero,
              margin: const EdgeInsetsDirectional.only(start: 30, end: 10),
              maxWidth: double.infinity,
              hintBuilder: hint('rtl-margin', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['rtl-margin']!;
    expect(guide.hintRect.left, moreOrLessEquals(10, epsilon: 0.5));
    expect(guide.hintRect.right, moreOrLessEquals(770, epsilon: 0.5));
  });

  testWidgets('gap, min/max size, infinity width and margin are respected', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 320,
          top: 160,
          width: 80,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                gap: 24,
                minWidth: 160,
                minHeight: 48,
                hintBuilder: hint('min-size', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                maxWidth: double.infinity,
                hintBuilder: hint('infinity-width', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                maxWidth: 120,
                maxHeight: 40,
                hintBuilder: sizedHint('max-size', 300, 120, contexts),
              ),
            ],
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext minGuide = contexts['min-size']!;
    expect(
      minGuide.hintRect.top,
      moreOrLessEquals(minGuide.targetRect.bottom + 24, epsilon: 0.5),
    );
    expect(minGuide.hintRect.width, moreOrLessEquals(160, epsilon: 0.5));
    expect(minGuide.hintRect.height, moreOrLessEquals(48, epsilon: 0.5));

    final SpotlightGuideStepContext infinityGuide = contexts['infinity-width']!;
    expect(infinityGuide.hintRect.left, moreOrLessEquals(20, epsilon: 0.5));
    expect(infinityGuide.hintRect.width, moreOrLessEquals(760, epsilon: 0.5));

    final SpotlightGuideStepContext maxGuide = contexts['max-size']!;
    expect(maxGuide.hintRect.width, moreOrLessEquals(120, epsilon: 0.5));
    expect(maxGuide.hintRect.height, moreOrLessEquals(40, epsilon: 0.5));
  });

  testWidgets('target padding expands spotlight rects', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 200,
          top: 150,
          width: 50,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: const EdgeInsets.fromLTRB(3, 5, 7, 11),
              hintBuilder: hint('target-padding', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['target-padding']!;
    expect(guide.targetRect.left, moreOrLessEquals(197, epsilon: 0.5));
    expect(guide.targetRect.top, moreOrLessEquals(145, epsilon: 0.5));
    expect(guide.targetRect.right, moreOrLessEquals(257, epsilon: 0.5));
    expect(guide.targetRect.bottom, moreOrLessEquals(201, epsilon: 0.5));
    expect(guide.targetRects.single, guide.targetRect);
    expect(guide.stepTargetRects.single, guide.targetRect);
  });

  testWidgets('min constraints larger than max constraints clamp safely', (
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
          width: 80,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: EdgeInsets.zero,
              minWidth: 300,
              maxWidth: 120,
              minHeight: 100,
              maxHeight: 40,
              hintBuilder: sizedHint('clamped-size', 20, 20, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['clamped-size']!;
    expect(guide.hintRect.width, moreOrLessEquals(120, epsilon: 0.5));
    expect(guide.hintRect.height, moreOrLessEquals(40, epsilon: 0.5));
  });

  testWidgets(
    'decoration anchor safe area keeps connection away from corners',
    (tester) async {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 704,
            top: 140,
            width: 40,
            height: 40,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetPadding: EdgeInsets.zero,
                targetAnchorPosition: const SpotlightGuideAnchorPosition.end(),
                decoration: const SpotlightGuideBubbleDecoration(
                  borderRadius: 18,
                  anchor: SpotlightGuideTriangleAnchor(size: Size(24, 16)),
                ),
                hintBuilder: hint('safe-arrow', contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['safe-arrow']!;
      expect(
        guide.indicatorOffset,
        greaterThanOrEqualTo(guide.indicatorSafeInset),
      );
      expect(
        arrowSideExtent(guide) - guide.indicatorOffset,
        greaterThanOrEqualTo(guide.indicatorSafeInset),
      );
    },
  );

  testWidgets('decoration anchor safe area works for every fixed placement', (
    tester,
  ) async {
    final List<SafeAreaPlacementCase> cases = <SafeAreaPlacementCase>[
      SafeAreaPlacementCase(
        label: 'safe-top',
        placement: SpotlightGuidePlacement.top,
        targetLeft: 704,
        targetTop: 500,
        anchor: const SpotlightGuideAnchorPosition.end(),
      ),
      SafeAreaPlacementCase(
        label: 'safe-bottom',
        placement: SpotlightGuidePlacement.bottom,
        targetLeft: 704,
        targetTop: 40,
        anchor: const SpotlightGuideAnchorPosition.end(),
      ),
      SafeAreaPlacementCase(
        label: 'safe-left',
        placement: SpotlightGuidePlacement.left,
        targetLeft: 700,
        targetTop: 500,
        anchor: const SpotlightGuideAnchorPosition.end(),
      ),
      SafeAreaPlacementCase(
        label: 'safe-right',
        placement: SpotlightGuidePlacement.right,
        targetLeft: 40,
        targetTop: 500,
        anchor: const SpotlightGuideAnchorPosition.end(),
      ),
    ];

    for (final SafeAreaPlacementCase placementCase in cases) {
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};
      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(placementCase.label),
          child: singleTargetStack(
            id: 'a',
            left: placementCase.targetLeft,
            top: placementCase.targetTop,
            width: 40,
            height: 40,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: placementCase.placement,
                targetPadding: EdgeInsets.zero,
                targetAnchorPosition: placementCase.anchor,
                decoration: const SpotlightGuideBubbleDecoration(
                  borderRadius: 18,
                  anchor: SpotlightGuideTriangleAnchor(size: Size(24, 16)),
                ),
                hintBuilder: hint(placementCase.label, contexts),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts[placementCase.label]!;
      expect(guide.placement, placementCase.placement);
      expect(
        guide.indicatorOffset,
        greaterThanOrEqualTo(guide.indicatorSafeInset),
      );
      expect(
        arrowSideExtent(guide) - guide.indicatorOffset,
        greaterThanOrEqualTo(guide.indicatorSafeInset),
      );
    }
  });

  testWidgets('changing item layout clears stale measured size', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    Widget buildWithMaxWidth(double maxWidth) {
      return guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: EdgeInsets.zero,
              maxWidth: maxWidth,
              hintBuilder: sizedHint('dynamic-size', 240, 40, contexts),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildWithMaxWidth(80));
    await pumpGuide(tester);
    expect(
      contexts['dynamic-size']?.hintRect.width,
      moreOrLessEquals(80, epsilon: 0.5),
    );

    await tester.pumpWidget(buildWithMaxWidth(180));
    await pumpGuide(tester);
    expect(
      contexts['dynamic-size']?.hintRect.width,
      moreOrLessEquals(180, epsilon: 0.5),
    );
  });

  testWidgets('infinity max height expands a side-placed hint', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 40,
          top: 270,
          width: 60,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.right,
              targetPadding: EdgeInsets.zero,
              maxHeight: double.infinity,
              hintBuilder: hint('infinity-height', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    // Default margin is 16, so a 600px tall overlay leaves 568px of vertical
    // room after both margins.
    final SpotlightGuideStepContext guide = contexts['infinity-height']!;
    expect(guide.hintRect.top, moreOrLessEquals(16, epsilon: 0.5));
    expect(guide.hintRect.height, moreOrLessEquals(568, epsilon: 0.5));
  });

  testWidgets('negative center anchor offset moves before the center', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 300,
          top: 150,
          width: 100,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.center(
                -12,
              ),
              hintBuilder: hint('negative-center', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['negative-center']!;
    expect(
      guide.targetAnchorPoint.dx,
      moreOrLessEquals(guide.targetRect.center.dx - 12, epsilon: 0.5),
    );
  });

  testWidgets('anchor safety uses connection range instead of visual size', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 650,
          top: 140,
          width: 40,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.bottom,
              targetPadding: EdgeInsets.zero,
              targetAnchorPosition: const SpotlightGuideAnchorPosition.end(),
              decoration: const SpotlightGuideBubbleDecoration(
                borderRadius: 10,
                anchor: _WideVisualNarrowConnectionAnchor(),
              ),
              hintBuilder: hint('safe-connection-range', contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['safe-connection-range']!;
    expect(guide.indicatorSafeInset, moreOrLessEquals(14, epsilon: 0.5));
    expect(guide.indicatorOffset, greaterThanOrEqualTo(14));
    expect(
      arrowSideExtent(guide) - guide.indicatorOffset,
      greaterThanOrEqualTo(14),
    );
  });
}

class _WideVisualNarrowConnectionAnchor extends SpotlightGuideBubbleAnchor {
  const _WideVisualNarrowConnectionAnchor([this.geometry]);

  final SpotlightGuideAnchorGeometry? geometry;

  @override
  Size get preferredSize => const Size(80, 16);

  @override
  double get connectionHalfExtent => 4;

  @override
  EdgeInsetsGeometry padding(SpotlightGuideAnchorGeometry? geometry) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? this.geometry;
    if (resolved == null) {
      return EdgeInsets.zero;
    }
    return switch (resolved.direction) {
      SpotlightGuideIndicatorDirection.up => const EdgeInsets.only(top: 16),
      SpotlightGuideIndicatorDirection.down => const EdgeInsets.only(
        bottom: 16,
      ),
      SpotlightGuideIndicatorDirection.left => const EdgeInsets.only(left: 16),
      SpotlightGuideIndicatorDirection.right => const EdgeInsets.only(
        right: 16,
      ),
    };
  }

  @override
  SpotlightGuideAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? this.geometry;
    if (resolved == null) {
      return null;
    }
    return switch (resolved.direction) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down =>
        SpotlightGuideAnchorConnection.horizontal(
          direction: resolved.direction,
          center: body.left + resolved.offset,
          halfWidth: connectionHalfExtent,
        ),
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right =>
        SpotlightGuideAnchorConnection.vertical(
          direction: resolved.direction,
          center: body.top + resolved.offset,
          halfWidth: connectionHalfExtent,
        ),
    };
  }

  @override
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {}

  @override
  SpotlightGuideBubbleAnchor resolve(SpotlightGuideAnchorGeometry geometry) {
    return _WideVisualNarrowConnectionAnchor(geometry);
  }
}
