import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Safety-boundary tests for margin, anchor safe inset, and pointer alignment.
///
/// Keep these separate from the general layout and pointer files so changes to
/// edge handling have one obvious place to verify.
void main() {
  testWidgets(
    'pointer chain keeps bubble inside margin on every fixed placement',
    (tester) async {
      const EdgeInsets margin = EdgeInsets.all(24);
      const double gap = 12;
      const Size pointerSize = Size(40, 40);
      final List<_SafePointerPlacementCase> cases = <_SafePointerPlacementCase>[
        const _SafePointerPlacementCase(
          label: 'bottom-near-right',
          placement: SpotlightGuidePlacement.bottom,
          targetLeft: 650,
          targetTop: 120,
          targetWidth: 60,
          targetHeight: 50,
          bubbleSize: Size(260, 80),
        ),
        const _SafePointerPlacementCase(
          label: 'top-near-left',
          placement: SpotlightGuidePlacement.top,
          targetLeft: 20,
          targetTop: 420,
          targetWidth: 60,
          targetHeight: 50,
          bubbleSize: Size(260, 80),
        ),
        const _SafePointerPlacementCase(
          label: 'left-near-bottom',
          placement: SpotlightGuidePlacement.left,
          targetLeft: 520,
          targetTop: 500,
          targetWidth: 80,
          targetHeight: 60,
          bubbleSize: Size(140, 220),
        ),
        const _SafePointerPlacementCase(
          label: 'right-near-top',
          placement: SpotlightGuidePlacement.right,
          targetLeft: 120,
          targetTop: 20,
          targetWidth: 80,
          targetHeight: 60,
          bubbleSize: Size(140, 220),
        ),
      ];

      for (final _SafePointerPlacementCase testCase in cases) {
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
                  placement: testCase.placement,
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  decoration: const SpotlightGuideBubbleDecoration(
                    borderRadius: 18,
                  ),
                  margin: margin,
                  gap: gap,
                  pointer: SpotlightGuidePointer(
                    size: pointerSize,
                    child: SizedBox(
                      key: pointerKey,
                      width: pointerSize.width,
                      height: pointerSize.height,
                      child: const ColoredBox(color: Colors.yellow),
                    ),
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        contexts[testCase.label] = guide;
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: SizedBox(
                            width: testCase.bubbleSize.width,
                            height: testCase.bubbleSize.height,
                          ),
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
        final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(
          tester,
        );
        final SpotlightGuideBubbleAnchorGeometry anchorGeometry =
            decoration.effectiveAnchorGeometry!;

        _expectBubbleInsideMargin(bubbleRect, guide, reason: testCase.label);
        _expectAnchorInsideSafeInset(
          anchorGeometry,
          bubbleRect,
          decoration.anchorSafeInset,
          reason: testCase.label,
        );
        _expectPointerTouchesTarget(pointerRect, guide, reason: testCase.label);
        _expectBubbleAnchorAlignedToPointer(
          bubbleRect,
          pointerRect,
          anchorGeometry,
          reason: testCase.label,
        );
      }
    },
  );

  testWidgets('semantic RTL placement keeps pointer bubble inside margin', (
    tester,
  ) async {
    final EdgeInsets margin = const EdgeInsetsDirectional.only(
      start: 30,
      end: 18,
      top: 24,
      bottom: 24,
    ).resolve(TextDirection.rtl);
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        textDirection: TextDirection.rtl,
        child: singleTargetStack(
          id: 'a',
          left: 120,
          top: 20,
          width: 80,
          height: 60,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              placement: SpotlightGuidePlacement.start,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              margin: const EdgeInsetsDirectional.only(
                start: 30,
                end: 18,
                top: 24,
                bottom: 24,
              ),
              pointer: const SpotlightGuidePointer(
                size: Size(40, 40),
                child: SizedBox(
                  key: ValueKey<String>('rtl-safe-pointer'),
                  width: 40,
                  height: 40,
                  child: ColoredBox(color: Colors.yellow),
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['rtl-safe'] = guide;
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(width: 140, height: 220),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['rtl-safe']!;
    final Rect pointerRect = tester.getRect(
      find.byKey(const ValueKey<String>('rtl-safe-pointer')),
    );
    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));

    expect(guide.placement, SpotlightGuidePlacement.right);
    expect(guide.margin, margin);
    _expectBubbleInsideMargin(bubbleRect, guide, reason: 'rtl-safe');
    _expectPointerTouchesTarget(pointerRect, guide, reason: 'rtl-safe');
  });

  testWidgets(
    'targetAnchorPosition start bubble anchor stays safe without moving pointer',
    (tester) async {
      const EdgeInsets margin = EdgeInsets.all(24);
      final List<_PointerStartSafeCase> cases = <_PointerStartSafeCase>[
        const _PointerStartSafeCase(
          label: 'ltr-start-near-left',
          textDirection: TextDirection.ltr,
          targetLeft: 48,
        ),
        const _PointerStartSafeCase(
          label: 'rtl-start-near-right',
          textDirection: TextDirection.rtl,
          targetLeft: 632,
        ),
      ];

      for (final _PointerStartSafeCase testCase in cases) {
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
                  targetAnchorPosition:
                      const SpotlightGuideAnchorPosition.start(),
                  decoration: const SpotlightGuideBubbleDecoration(
                    borderRadius: 28,
                  ),
                  margin: margin,
                  pointer: SpotlightGuidePointer(
                    size: const Size(40, 24),
                    pointerAnchorPosition:
                        const SpotlightGuideAnchorPosition.start(),
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
                          child: const SizedBox(width: 20, height: 20),
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
        final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(
          tester,
        );
        final SpotlightGuideBubbleAnchorGeometry anchorGeometry =
            decoration.effectiveAnchorGeometry!;
        final double pointerTargetX =
            testCase.textDirection == TextDirection.rtl
            ? pointerRect.right
            : pointerRect.left;

        expect(
          pointerTargetX,
          moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
          reason: testCase.label,
        );
        _expectBubbleInsideMargin(bubbleRect, guide, reason: testCase.label);
        _expectAnchorInsideSafeInset(
          anchorGeometry,
          bubbleRect,
          decoration.anchorSafeInset,
          reason: testCase.label,
        );
        expect(
          bubbleRect.left + anchorGeometry.offset,
          moreOrLessEquals(pointerTargetX, epsilon: 0.5),
          reason: testCase.label,
        );
      }
    },
  );

  testWidgets(
    'cross-axis pointer bubble shifts anchor offset before overflowing margin',
    (tester) async {
      const EdgeInsets margin = EdgeInsets.all(18);
      const double gap = 18;
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 650,
            top: 120,
            width: 100,
            height: 80,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.left,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                decoration: const SpotlightGuideBubbleDecoration(
                  borderRadius: 18,
                ),
                margin: margin,
                gap: gap,
                pointer: const SpotlightGuidePointer(
                  size: Size(64, 104),
                  bubbleSide: SpotlightGuideBubbleSide.bottom,
                  child: SizedBox(
                    key: ValueKey<String>('cross-axis-pointer'),
                    width: 64,
                    height: 104,
                    child: ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['cross-axis'] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 300, height: 96),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['cross-axis']!;
      final Rect pointerRect = tester.getRect(
        find.byKey(const ValueKey<String>('cross-axis-pointer')),
      );
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(
        tester,
      );
      final SpotlightGuideBubbleAnchorGeometry anchorGeometry =
          decoration.effectiveAnchorGeometry!;

      _expectBubbleInsideMargin(bubbleRect, guide, reason: 'cross-axis');
      _expectPointerTouchesTarget(pointerRect, guide, reason: 'cross-axis');
      _expectBubbleAnchorAlignedToPointer(
        bubbleRect,
        pointerRect,
        anchorGeometry,
        reason: 'cross-axis',
      );
      expect(
        anchorGeometry.offset,
        greaterThan(32),
        reason: 'the bubble should use left-side space before overflowing',
      );
      expect(
        bubbleRect.top,
        moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
      );
    },
  );

  testWidgets(
    'along-placement pointer reserves pointer and target gap before right margin',
    (tester) async {
      const EdgeInsets margin = EdgeInsets.all(24);
      const double gap = 10;
      const double targetGap = 14;
      const Size pointerSize = Size(48, 48);
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 420,
            top: 220,
            width: 120,
            height: 64,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.right,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                decoration: const SpotlightGuideBubbleDecoration(
                  borderRadius: 18,
                ),
                margin: margin,
                gap: gap,
                maxWidth: 300,
                pointer: const SpotlightGuidePointer(
                  size: pointerSize,
                  targetGap: targetGap,
                  child: SizedBox(
                    key: ValueKey<String>('right-reserve-pointer'),
                    width: 48,
                    height: 48,
                    child: ColoredBox(color: Colors.yellow),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['right-reserve'] = guide;
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(width: 300, height: 84),
                      );
                    },
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      final SpotlightGuideStepContext guide = contexts['right-reserve']!;
      final Rect pointerRect = tester.getRect(
        find.byKey(const ValueKey<String>('right-reserve-pointer')),
      );
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(
        tester,
      );
      final SpotlightGuideBubbleAnchorGeometry anchorGeometry =
          decoration.effectiveAnchorGeometry!;

      _expectBubbleInsideMargin(bubbleRect, guide, reason: 'right-reserve');
      expect(
        pointerRect.left,
        moreOrLessEquals(guide.targetRect.right + targetGap, epsilon: 0.5),
        reason: 'right-reserve',
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
        reason: 'right-reserve',
      );
      _expectBubbleAnchorAlignedToPointer(
        bubbleRect,
        pointerRect,
        anchorGeometry,
        reason: 'right-reserve',
      );
      expect(
        bubbleRect.left,
        greaterThanOrEqualTo(pointerRect.right + gap - 0.5),
      );
    },
  );
}

class _SafePointerPlacementCase {
  const _SafePointerPlacementCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
    required this.targetTop,
    required this.targetWidth,
    required this.targetHeight,
    required this.bubbleSize,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
  final double targetTop;
  final double targetWidth;
  final double targetHeight;
  final Size bubbleSize;
}

class _PointerStartSafeCase {
  const _PointerStartSafeCase({
    required this.label,
    required this.textDirection,
    required this.targetLeft,
  });

  final String label;
  final TextDirection textDirection;
  final double targetLeft;
}

void _expectBubbleInsideMargin(
  Rect bubbleRect,
  SpotlightGuideStepContext guide, {
  required String reason,
}) {
  expect(
    bubbleRect.left,
    greaterThanOrEqualTo(guide.margin.left - 0.5),
    reason: reason,
  );
  expect(
    bubbleRect.top,
    greaterThanOrEqualTo(guide.margin.top - 0.5),
    reason: reason,
  );
  expect(
    bubbleRect.right,
    lessThanOrEqualTo(guide.overlaySize.width - guide.margin.right + 0.5),
    reason: reason,
  );
  expect(
    bubbleRect.bottom,
    lessThanOrEqualTo(guide.overlaySize.height - guide.margin.bottom + 0.5),
    reason: reason,
  );
}

void _expectAnchorInsideSafeInset(
  SpotlightGuideBubbleAnchorGeometry anchorGeometry,
  Rect bubbleRect,
  double safeInset, {
  required String reason,
}) {
  final double extent = switch (anchorGeometry.direction) {
    SpotlightGuideDirection.up ||
    SpotlightGuideDirection.down => bubbleRect.width,
    SpotlightGuideDirection.left ||
    SpotlightGuideDirection.right => bubbleRect.height,
  };
  expect(anchorGeometry.offset, greaterThanOrEqualTo(safeInset - 0.5));
  expect(
    anchorGeometry.offset,
    lessThanOrEqualTo(extent - safeInset + 0.5),
    reason: reason,
  );
}

void _expectPointerTouchesTarget(
  Rect pointerRect,
  SpotlightGuideStepContext guide, {
  required String reason,
}) {
  switch (guide.anchorDirection) {
    case SpotlightGuideDirection.up:
      expect(
        pointerRect.top,
        moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideDirection.down:
      expect(
        pointerRect.bottom,
        moreOrLessEquals(guide.targetRect.top, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideDirection.left:
      expect(
        pointerRect.left,
        moreOrLessEquals(guide.targetRect.right, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideDirection.right:
      expect(
        pointerRect.right,
        moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

void _expectBubbleAnchorAlignedToPointer(
  Rect bubbleRect,
  Rect pointerRect,
  SpotlightGuideBubbleAnchorGeometry anchorGeometry, {
  required String reason,
}) {
  switch (anchorGeometry.direction) {
    case SpotlightGuideDirection.up:
    case SpotlightGuideDirection.down:
      expect(
        bubbleRect.left + anchorGeometry.offset,
        moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideDirection.left:
    case SpotlightGuideDirection.right:
      expect(
        bubbleRect.top + anchorGeometry.offset,
        moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

SpotlightGuideBubbleDecoration _bubbleDecoration(WidgetTester tester) {
  final dynamic bubble = tester.renderObject(find.byType(SpotlightGuideBubble));
  return bubble.effectiveDecoration as SpotlightGuideBubbleDecoration;
}
