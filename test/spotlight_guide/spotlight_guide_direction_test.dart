import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import 'spotlight_guide_test_helpers.dart';

/// Direction matrix tests.
///
/// Run this file when changing placement resolution, pointer bubble placement,
/// semantic start/end behavior, anchor positions, indicator directions, pointer
/// rotations, visual offsets, or signed gap semantics.
void main() {
  testWidgets('pointer bubble placement matrix resolves physical directions', (
    tester,
  ) async {
    const double gap = 10;
    const Size pointerSize = Size(32, 32);
    final List<SpotlightGuidePlacement> stepPlacements =
        <SpotlightGuidePlacement>[
          SpotlightGuidePlacement.top,
          SpotlightGuidePlacement.bottom,
          SpotlightGuidePlacement.left,
          SpotlightGuidePlacement.right,
          SpotlightGuidePlacement.start,
          SpotlightGuidePlacement.end,
        ];
    final List<SpotlightGuidePointerBubblePlacement> bubblePlacements =
        <SpotlightGuidePointerBubblePlacement>[
          SpotlightGuidePointerBubblePlacement.alongPlacement,
          SpotlightGuidePointerBubblePlacement.top,
          SpotlightGuidePointerBubblePlacement.bottom,
          SpotlightGuidePointerBubblePlacement.left,
          SpotlightGuidePointerBubblePlacement.right,
          SpotlightGuidePointerBubblePlacement.start,
          SpotlightGuidePointerBubblePlacement.end,
        ];

    for (final TextDirection textDirection in TextDirection.values) {
      for (final SpotlightGuidePlacement stepPlacement in stepPlacements) {
        final SpotlightGuidePlacement expectedPlacement = _resolveStepPlacement(
          stepPlacement,
          textDirection,
        );
        final _TargetGeometry target = _targetFor(expectedPlacement);
        for (final SpotlightGuidePointerBubblePlacement bubblePlacement
            in bubblePlacements) {
          final SpotlightGuidePointerBubblePlacement expectedBubblePlacement =
              _resolveBubblePlacement(bubblePlacement, textDirection);
          final SpotlightGuideIndicatorDirection expectedTargetDirection =
              _targetDirectionFor(expectedPlacement);
          final SpotlightGuideIndicatorDirection expectedAnchorDirection =
              _bubbleAnchorDirection(
                expectedTargetDirection,
                expectedBubblePlacement,
              );
          final SpotlightGuideIndicatorDirection expectedBubbleDirection =
              _oppositeDirection(expectedAnchorDirection);
          final String label =
              'matrix-${textDirection.name}-${stepPlacement.name}'
              '-${bubblePlacement.name}';
          final Map<String, SpotlightGuideStepContext> contexts =
              <String, SpotlightGuideStepContext>{};
          final List<SpotlightGuidePointerContext> pointerContexts =
              <SpotlightGuidePointerContext>[];
          final ValueKey<String> pointerKey = ValueKey<String>(
            '$label-pointer',
          );

          await tester.pumpWidget(
            guideApp(
              appKey: ValueKey<String>(label),
              textDirection: textDirection,
              child: singleTargetStack(
                id: 'a',
                left: target.left,
                top: target.top,
                width: target.width,
                height: target.height,
              ),
              steps: <SpotlightGuideStep>[
                SpotlightGuideStep.item(
                  SpotlightGuideStepItem(
                    targetId: 'a',
                    placement: stepPlacement,
                    targetDecoration: const SpotlightGuideTargetDecoration(
                      padding: EdgeInsets.zero,
                    ),
                    targetAnchorPosition:
                        const SpotlightGuideAnchorPosition.center(),
                    gap: gap,
                    minWidth: 96,
                    maxWidth: 140,
                    hintBuilder:
                        (
                          BuildContext context,
                          SpotlightGuideStepContext guide,
                        ) {
                          contexts[label] = guide;
                          return SpotlightGuideBubbleHint(
                            guide: guide,
                            pointer: SpotlightGuideHintPointer(
                              size: pointerSize,
                              bubblePlacement: bubblePlacement,
                              child: SizedBox(
                                key: pointerKey,
                                width: pointerSize.width,
                                height: pointerSize.height,
                                child: const ColoredBox(color: Colors.yellow),
                              ),
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
                            child: const SizedBox(width: 96, height: 42),
                          );
                        },
                  ),
                ),
              ],
            ),
          );
          await _pumpDirectionGuide(tester);

          final SpotlightGuideStepContext guide = contexts[label]!;
          final SpotlightGuidePointerContext pointerContext =
              pointerContexts.last;
          final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
          final Rect bubbleRect = tester.getRect(
            find.byType(SpotlightGuideBubble),
          );
          final SpotlightGuideAnchorGeometry anchorGeometry =
              _bubbleAnchorGeometry(tester);

          expect(guide.placement, expectedPlacement, reason: label);
          expect(
            guide.indicatorDirection,
            expectedTargetDirection,
            reason: label,
          );
          expect(
            pointerContext.targetDirection,
            expectedTargetDirection,
            reason: label,
          );
          expect(
            pointerContext.bubblePlacement,
            expectedBubblePlacement,
            reason: label,
          );
          expect(
            pointerContext.bubbleAnchorDirection,
            expectedAnchorDirection,
            reason: label,
          );
          expect(
            pointerContext.bubbleDirection,
            expectedBubbleDirection,
            reason: label,
          );
          expect(
            anchorGeometry.direction,
            expectedAnchorDirection,
            reason: label,
          );
          _expectPointerTouchesTargetSideOrPerpendicularOverhang(
            pointerRect: pointerRect,
            bubbleRect: bubbleRect,
            guide: guide,
            bubbleDirection: expectedBubbleDirection,
            reason: label,
          );
          _expectBubbleOnPointerSide(
            bubbleRect: bubbleRect,
            pointerRect: pointerRect,
            direction: expectedBubbleDirection,
            gap: gap,
            reason: label,
          );
          _expectBubbleAnchorAimsAtPointerCenter(
            bubbleRect: bubbleRect,
            pointerRect: pointerRect,
            anchorGeometry: anchorGeometry,
            reason: label,
          );
        }
      }
    }
  });

  testWidgets('auto placements resolve before pointer bubble matrix', (
    tester,
  ) async {
    const double gap = 10;
    final List<_AutoPlacementCase> cases = <_AutoPlacementCase>[
      const _AutoPlacementCase(
        label: 'auto-bottom',
        placement: SpotlightGuidePlacement.auto,
        target: _TargetGeometry(left: 340, top: 48, width: 80, height: 56),
      ),
      const _AutoPlacementCase(
        label: 'auto-top',
        placement: SpotlightGuidePlacement.auto,
        target: _TargetGeometry(left: 340, top: 500, width: 80, height: 56),
      ),
      const _AutoPlacementCase(
        label: 'vertical-auto-bottom',
        placement: SpotlightGuidePlacement.verticalAuto,
        target: _TargetGeometry(left: 340, top: 48, width: 80, height: 56),
        expectedPlacement: SpotlightGuidePlacement.bottom,
      ),
      const _AutoPlacementCase(
        label: 'vertical-auto-top',
        placement: SpotlightGuidePlacement.verticalAuto,
        target: _TargetGeometry(left: 340, top: 500, width: 80, height: 56),
        expectedPlacement: SpotlightGuidePlacement.top,
      ),
      const _AutoPlacementCase(
        label: 'horizontal-auto-right',
        placement: SpotlightGuidePlacement.horizontalAuto,
        target: _TargetGeometry(left: 48, top: 260, width: 80, height: 56),
        expectedPlacement: SpotlightGuidePlacement.right,
      ),
      const _AutoPlacementCase(
        label: 'horizontal-auto-left',
        placement: SpotlightGuidePlacement.horizontalAuto,
        target: _TargetGeometry(left: 620, top: 260, width: 80, height: 56),
        expectedPlacement: SpotlightGuidePlacement.left,
      ),
    ];
    final List<SpotlightGuidePointerBubblePlacement> bubblePlacements =
        <SpotlightGuidePointerBubblePlacement>[
          SpotlightGuidePointerBubblePlacement.alongPlacement,
          SpotlightGuidePointerBubblePlacement.top,
          SpotlightGuidePointerBubblePlacement.bottom,
          SpotlightGuidePointerBubblePlacement.left,
          SpotlightGuidePointerBubblePlacement.right,
          SpotlightGuidePointerBubblePlacement.start,
          SpotlightGuidePointerBubblePlacement.end,
        ];

    for (final TextDirection textDirection in TextDirection.values) {
      for (final _AutoPlacementCase testCase in cases) {
        for (final SpotlightGuidePointerBubblePlacement bubblePlacement
            in bubblePlacements) {
          final String label =
              '${testCase.label}-${textDirection.name}'
              '-${bubblePlacement.name}';
          final Map<String, SpotlightGuideStepContext> contexts =
              <String, SpotlightGuideStepContext>{};
          final List<SpotlightGuidePointerContext> pointerContexts =
              <SpotlightGuidePointerContext>[];
          final ValueKey<String> pointerKey = ValueKey<String>(
            '$label-pointer',
          );
          final SpotlightGuidePointerBubblePlacement expectedBubblePlacement =
              _resolveBubblePlacement(bubblePlacement, textDirection);

          await tester.pumpWidget(
            guideApp(
              appKey: ValueKey<String>(label),
              textDirection: textDirection,
              child: singleTargetStack(
                id: 'a',
                left: testCase.target.left,
                top: testCase.target.top,
                width: testCase.target.width,
                height: testCase.target.height,
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
                    minWidth: 96,
                    maxWidth: 140,
                    hintBuilder:
                        (
                          BuildContext context,
                          SpotlightGuideStepContext guide,
                        ) {
                          contexts[label] = guide;
                          return SpotlightGuideBubbleHint(
                            guide: guide,
                            pointer: SpotlightGuideHintPointer(
                              size: const Size(32, 32),
                              bubblePlacement: bubblePlacement,
                              child: SizedBox(
                                key: pointerKey,
                                width: 32,
                                height: 32,
                              ),
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
                            child: const SizedBox(width: 96, height: 42),
                          );
                        },
                  ),
                ),
              ],
            ),
          );
          await _pumpDirectionGuide(tester);

          final SpotlightGuideStepContext guide = contexts[label]!;
          final SpotlightGuidePointerContext pointerContext =
              pointerContexts.last;
          final SpotlightGuideIndicatorDirection expectedTargetDirection =
              _targetDirectionFor(guide.placement);
          final SpotlightGuideIndicatorDirection expectedAnchorDirection =
              _bubbleAnchorDirection(
                expectedTargetDirection,
                expectedBubblePlacement,
              );
          final SpotlightGuideIndicatorDirection expectedBubbleDirection =
              _oppositeDirection(expectedAnchorDirection);
          final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
          final Rect bubbleRect = tester.getRect(
            find.byType(SpotlightGuideBubble),
          );
          final SpotlightGuideAnchorGeometry anchorGeometry =
              _bubbleAnchorGeometry(tester);

          if (testCase.expectedPlacement != null) {
            expect(guide.placement, testCase.expectedPlacement, reason: label);
          } else {
            expect(
              _isPhysicalPlacement(guide.placement),
              isTrue,
              reason: label,
            );
          }
          expect(
            guide.indicatorDirection,
            expectedTargetDirection,
            reason: label,
          );
          expect(
            pointerContext.bubblePlacement,
            expectedBubblePlacement,
            reason: label,
          );
          expect(
            pointerContext.bubbleAnchorDirection,
            expectedAnchorDirection,
            reason: label,
          );
          expect(
            anchorGeometry.direction,
            expectedAnchorDirection,
            reason: label,
          );
          _expectPointerTouchesTargetSideOrPerpendicularOverhang(
            pointerRect: pointerRect,
            bubbleRect: bubbleRect,
            guide: guide,
            bubbleDirection: expectedBubbleDirection,
            reason: label,
          );
          _expectBubbleOnPointerSide(
            bubbleRect: bubbleRect,
            pointerRect: pointerRect,
            direction: expectedBubbleDirection,
            gap: gap,
            reason: label,
          );
          _expectBubbleAnchorAimsAtPointerCenter(
            bubbleRect: bubbleRect,
            pointerRect: pointerRect,
            anchorGeometry: anchorGeometry,
            reason: label,
          );
        }
      }
    }
  });

  testWidgets('anchorMode target keeps bubble direction tied to target', (
    tester,
  ) async {
    const double gap = 12;
    const Size pointerSize = Size(34, 30);
    const List<SpotlightGuidePlacement> stepPlacements =
        <SpotlightGuidePlacement>[
          SpotlightGuidePlacement.top,
          SpotlightGuidePlacement.bottom,
          SpotlightGuidePlacement.left,
          SpotlightGuidePlacement.right,
          SpotlightGuidePlacement.start,
          SpotlightGuidePlacement.end,
        ];
    const List<SpotlightGuidePointerBubblePlacement> bubblePlacements =
        <SpotlightGuidePointerBubblePlacement>[
          SpotlightGuidePointerBubblePlacement.alongPlacement,
          SpotlightGuidePointerBubblePlacement.top,
          SpotlightGuidePointerBubblePlacement.bottom,
          SpotlightGuidePointerBubblePlacement.left,
          SpotlightGuidePointerBubblePlacement.right,
          SpotlightGuidePointerBubblePlacement.start,
          SpotlightGuidePointerBubblePlacement.end,
        ];

    for (final TextDirection textDirection in TextDirection.values) {
      for (final SpotlightGuidePlacement stepPlacement in stepPlacements) {
        final SpotlightGuidePlacement expectedPlacement = _resolveStepPlacement(
          stepPlacement,
          textDirection,
        );
        final _TargetGeometry target = _targetFor(expectedPlacement);
        final SpotlightGuideIndicatorDirection expectedDirection =
            _targetDirectionFor(expectedPlacement);
        for (final SpotlightGuidePointerBubblePlacement bubblePlacement
            in bubblePlacements) {
          final String label =
              'target-mode-${textDirection.name}-${stepPlacement.name}'
              '-${bubblePlacement.name}';
          final Map<String, SpotlightGuideStepContext> contexts =
              <String, SpotlightGuideStepContext>{};
          final List<SpotlightGuidePointerContext> pointerContexts =
              <SpotlightGuidePointerContext>[];
          final ValueKey<String> pointerKey = ValueKey<String>(
            '$label-pointer',
          );

          await tester.pumpWidget(
            guideApp(
              appKey: ValueKey<String>(label),
              textDirection: textDirection,
              child: singleTargetStack(
                id: 'a',
                left: target.left,
                top: target.top,
                width: target.width,
                height: target.height,
              ),
              steps: <SpotlightGuideStep>[
                SpotlightGuideStep.item(
                  SpotlightGuideStepItem(
                    targetId: 'a',
                    placement: stepPlacement,
                    targetDecoration: const SpotlightGuideTargetDecoration(
                      padding: EdgeInsets.zero,
                    ),
                    targetAnchorPosition:
                        const SpotlightGuideAnchorPosition.center(),
                    gap: gap,
                    minWidth: 96,
                    maxWidth: 140,
                    hintBuilder:
                        (
                          BuildContext context,
                          SpotlightGuideStepContext guide,
                        ) {
                          contexts[label] = guide;
                          return SpotlightGuideBubbleHint(
                            guide: guide,
                            pointer: SpotlightGuideHintPointer(
                              size: pointerSize,
                              anchorMode:
                                  SpotlightGuidePointerAnchorMode.target,
                              bubblePlacement: bubblePlacement,
                              child: SizedBox(
                                key: pointerKey,
                                width: pointerSize.width,
                                height: pointerSize.height,
                              ),
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
                            child: const SizedBox(width: 96, height: 42),
                          );
                        },
                  ),
                ),
              ],
            ),
          );
          await _pumpDirectionGuide(tester);

          final SpotlightGuideStepContext guide = contexts[label]!;
          final SpotlightGuidePointerContext pointerContext =
              pointerContexts.last;
          final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
          final Rect bubbleRect = tester.getRect(
            find.byType(SpotlightGuideBubble),
          );
          final SpotlightGuideAnchorGeometry anchorGeometry =
              _bubbleAnchorGeometry(tester);

          expect(guide.placement, expectedPlacement, reason: label);
          expect(guide.indicatorDirection, expectedDirection, reason: label);
          expect(
            pointerContext.anchorMode,
            SpotlightGuidePointerAnchorMode.target,
            reason: label,
          );
          expect(
            pointerContext.bubblePlacement,
            SpotlightGuidePointerBubblePlacement.alongPlacement,
            reason: label,
          );
          expect(anchorGeometry.direction, expectedDirection, reason: label);
          expect(
            _signedTargetHintGap(guide),
            moreOrLessEquals(gap, epsilon: 0.5),
            reason: label,
          );
          _expectBubbleAnchorAimsAtTargetAnchor(
            bubbleRect: bubbleRect,
            guide: guide,
            anchorGeometry: anchorGeometry,
            reason: label,
          );
          _expectPointerCrossAxisAlignedWithTargetAnchor(
            pointerRect,
            guide,
            label,
          );
        }
      }
    }
  });

  testWidgets(
    'targetAnchorPosition controls no-pointer anchors in LTR and RTL',
    (tester) async {
      const List<SpotlightGuidePlacement> stepPlacements =
          <SpotlightGuidePlacement>[
            SpotlightGuidePlacement.top,
            SpotlightGuidePlacement.bottom,
            SpotlightGuidePlacement.left,
            SpotlightGuidePlacement.right,
            SpotlightGuidePlacement.start,
            SpotlightGuidePlacement.end,
          ];
      const List<SpotlightGuideAnchorPosition> anchors =
          <SpotlightGuideAnchorPosition>[
            SpotlightGuideAnchorPosition.start(8),
            SpotlightGuideAnchorPosition.center(5),
            SpotlightGuideAnchorPosition.end(8),
          ];

      for (final TextDirection textDirection in TextDirection.values) {
        for (final SpotlightGuidePlacement stepPlacement in stepPlacements) {
          final SpotlightGuidePlacement expectedPlacement =
              _resolveStepPlacement(stepPlacement, textDirection);
          final _TargetGeometry target = _targetFor(expectedPlacement);
          for (final SpotlightGuideAnchorPosition anchor in anchors) {
            final String label =
                'no-pointer-${textDirection.name}-${stepPlacement.name}'
                '-${anchor.anchor.name}';
            final Map<String, SpotlightGuideStepContext> contexts =
                <String, SpotlightGuideStepContext>{};

            await tester.pumpWidget(
              guideApp(
                appKey: ValueKey<String>(label),
                textDirection: textDirection,
                child: singleTargetStack(
                  id: 'a',
                  left: target.left,
                  top: target.top,
                  width: target.width,
                  height: target.height,
                ),
                steps: <SpotlightGuideStep>[
                  SpotlightGuideStep.item(
                    SpotlightGuideStepItem(
                      targetId: 'a',
                      placement: stepPlacement,
                      targetDecoration: const SpotlightGuideTargetDecoration(
                        padding: EdgeInsets.zero,
                      ),
                      targetAnchorPosition: anchor,
                      gap: 10,
                      minWidth: 96,
                      maxWidth: 140,
                      hintBuilder: sizedHint(label, 96, 42, contexts),
                    ),
                  ),
                ],
              ),
            );
            await _pumpDirectionGuide(tester);

            final SpotlightGuideStepContext guide = contexts[label]!;
            expect(guide.placement, expectedPlacement, reason: label);
            expect(
              _hintAnchorGlobalAxis(guide),
              moreOrLessEquals(_targetAnchorAxis(guide), epsilon: 0.5),
              reason: label,
            );
          }
        }
      }
    },
  );

  testWidgets('directional margins resolve before placement math', (
    tester,
  ) async {
    const EdgeInsetsDirectional margin = EdgeInsetsDirectional.only(
      start: 28,
      end: 12,
      top: 7,
      bottom: 11,
    );

    for (final TextDirection textDirection in TextDirection.values) {
      final String label = 'directional-margin-${textDirection.name}';
      final Map<String, SpotlightGuideStepContext> contexts =
          <String, SpotlightGuideStepContext>{};

      await tester.pumpWidget(
        guideApp(
          appKey: ValueKey<String>(label),
          textDirection: textDirection,
          child: singleTargetStack(
            id: 'a',
            left: 340,
            top: 88,
            width: 84,
            height: 58,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                margin: margin,
                hintBuilder: sizedHint(label, 96, 42, contexts),
              ),
            ),
          ],
        ),
      );
      await _pumpDirectionGuide(tester);

      final SpotlightGuideStepContext guide = contexts[label]!;
      final EdgeInsets resolved = margin.resolve(textDirection);
      expect(guide.margin, resolved, reason: label);
      expect(guide.hintRect.left, greaterThanOrEqualTo(resolved.left - 0.5));
      expect(
        guide.hintRect.right,
        lessThanOrEqualTo(guide.overlaySize.width - resolved.right + 0.5),
      );
    }
  });

  testWidgets('visual smoke renders pointer and bubble across directions', (
    tester,
  ) async {
    const Color pointerColor = Color(0xFFFF00FF);
    const Color bubbleColor = Color(0xFF00E5FF);
    const double gap = 10;
    const _TargetGeometry target = _TargetGeometry(
      left: 340,
      top: 260,
      width: 84,
      height: 58,
    );
    const List<_VisualDirectionCase> cases = <_VisualDirectionCase>[
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.top,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.alongPlacement,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.bottom,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.top,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.left,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.right,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.right,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.left,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.start,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.end,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.rtl,
        placement: SpotlightGuidePlacement.start,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.end,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.ltr,
        placement: SpotlightGuidePlacement.end,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.start,
      ),
      _VisualDirectionCase(
        textDirection: TextDirection.rtl,
        placement: SpotlightGuidePlacement.end,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.start,
      ),
    ];

    for (final _VisualDirectionCase testCase in cases) {
      final String label =
          'visual-${testCase.textDirection.name}-${testCase.placement.name}'
          '-${testCase.bubblePlacement.name}';
      final GlobalKey captureKey = GlobalKey();
      final ValueKey<String> pointerKey = ValueKey<String>('$label-pointer');

      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: guideApp(
            appKey: ValueKey<String>(label),
            textDirection: testCase.textDirection,
            child: singleTargetStack(
              id: 'a',
              left: target.left,
              top: target.top,
              width: target.width,
              height: target.height,
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
                  minWidth: 96,
                  maxWidth: 140,
                  decoration: const SpotlightGuideBubbleDecoration(
                    color: bubbleColor,
                    borderRadius: 4,
                  ),
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          pointer: SpotlightGuideHintPointer(
                            size: const Size(32, 32),
                            bubblePlacement: testCase.bubblePlacement,
                            child: SizedBox(
                              key: pointerKey,
                              width: 32,
                              height: 32,
                              child: const ColoredBox(color: pointerColor),
                            ),
                          ),
                          child: const SizedBox(width: 96, height: 42),
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      );
      await _pumpDirectionGuide(tester);

      final _CapturedPixels pixels = await _capturePixels(tester, captureKey);
      final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
      final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
      _expectColorVisibleInRect(
        pixels,
        pointerRect.deflate(3),
        pointerColor,
        reason: label,
      );
      _expectColorVisibleInRect(
        pixels,
        bubbleRect.deflate(6),
        bubbleColor,
        reason: label,
      );
    }
  });

  testWidgets('anchor positions resolve consistently in LTR and RTL', (
    tester,
  ) async {
    const List<SpotlightGuideAnchorPosition> anchors =
        <SpotlightGuideAnchorPosition>[
          SpotlightGuideAnchorPosition.start(8),
          SpotlightGuideAnchorPosition.center(6),
          SpotlightGuideAnchorPosition.end(8),
        ];
    const List<SpotlightGuidePlacement> placements = <SpotlightGuidePlacement>[
      SpotlightGuidePlacement.bottom,
      SpotlightGuidePlacement.top,
      SpotlightGuidePlacement.left,
      SpotlightGuidePlacement.right,
    ];

    for (final TextDirection textDirection in TextDirection.values) {
      for (final SpotlightGuidePlacement placement in placements) {
        final _TargetGeometry target = _targetFor(placement);
        for (final SpotlightGuideAnchorPosition targetAnchor in anchors) {
          for (final SpotlightGuideAnchorPosition pointerAnchor in anchors) {
            final String label =
                'anchor-${textDirection.name}-${placement.name}'
                '-target-${targetAnchor.anchor.name}'
                '-pointer-${pointerAnchor.anchor.name}';
            final Map<String, SpotlightGuideStepContext> contexts =
                <String, SpotlightGuideStepContext>{};
            final ValueKey<String> pointerKey = ValueKey<String>(
              '$label-pointer',
            );

            await tester.pumpWidget(
              guideApp(
                appKey: ValueKey<String>(label),
                textDirection: textDirection,
                child: singleTargetStack(
                  id: 'a',
                  left: target.left,
                  top: target.top,
                  width: target.width,
                  height: target.height,
                ),
                steps: <SpotlightGuideStep>[
                  SpotlightGuideStep.item(
                    SpotlightGuideStepItem(
                      targetId: 'a',
                      placement: placement,
                      targetDecoration: const SpotlightGuideTargetDecoration(
                        padding: EdgeInsets.zero,
                      ),
                      targetAnchorPosition: targetAnchor,
                      gap: 10,
                      minWidth: 96,
                      maxWidth: 140,
                      hintBuilder:
                          (
                            BuildContext context,
                            SpotlightGuideStepContext guide,
                          ) {
                            contexts[label] = guide;
                            return SpotlightGuideBubbleHint(
                              guide: guide,
                              pointer: SpotlightGuideHintPointer(
                                size: const Size(40, 28),
                                pointerAnchorPosition: pointerAnchor,
                                child: SizedBox(
                                  key: pointerKey,
                                  width: 40,
                                  height: 28,
                                ),
                              ),
                              child: const SizedBox(width: 96, height: 42),
                            );
                          },
                    ),
                  ),
                ],
              ),
            );
            await _pumpDirectionGuide(tester);

            final SpotlightGuideStepContext guide = contexts[label]!;
            final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
            final Rect bubbleRect = tester.getRect(
              find.byType(SpotlightGuideBubble),
            );
            final SpotlightGuideAnchorGeometry anchorGeometry =
                _bubbleAnchorGeometry(tester);
            final bool horizontalAxis =
                guide.indicatorDirection ==
                    SpotlightGuideIndicatorDirection.up ||
                guide.indicatorDirection ==
                    SpotlightGuideIndicatorDirection.down;
            final double pointerTargetAxis = _anchorAxisPosition(
              pointerRect,
              pointerAnchor,
              isHorizontalAxis: horizontalAxis,
              textDirection: textDirection,
            );
            final double bubbleAnchorAxis = _anchorAxisPosition(
              pointerRect,
              targetAnchor,
              isHorizontalAxis: horizontalAxis,
              textDirection: textDirection,
            );
            final double targetAxis = horizontalAxis
                ? guide.targetRect.center.dx
                : guide.targetRect.center.dy;

            expect(
              pointerTargetAxis,
              moreOrLessEquals(targetAxis, epsilon: 0.5),
              reason: label,
            );
            expect(
              _bubbleAnchorGlobalAxis(bubbleRect, anchorGeometry),
              moreOrLessEquals(bubbleAnchorAxis, epsilon: 0.5),
              reason: label,
            );
          }
        }
      }
    }
  });

  testWidgets('signed gap and targetGap follow resolved directions', (
    tester,
  ) async {
    const List<SpotlightGuidePlacement> placements = <SpotlightGuidePlacement>[
      SpotlightGuidePlacement.bottom,
      SpotlightGuidePlacement.top,
      SpotlightGuidePlacement.left,
      SpotlightGuidePlacement.right,
      SpotlightGuidePlacement.start,
      SpotlightGuidePlacement.end,
    ];
    const List<double> gaps = <double>[12, -5];
    const List<double> targetGaps = <double>[9, -4];

    for (final TextDirection textDirection in TextDirection.values) {
      for (final SpotlightGuidePlacement placement in placements) {
        final SpotlightGuidePlacement resolvedPlacement = _resolveStepPlacement(
          placement,
          textDirection,
        );
        final _TargetGeometry target = _targetFor(resolvedPlacement);
        for (final double gap in gaps) {
          for (final double targetGap in targetGaps) {
            final String label =
                'signed-${textDirection.name}-${placement.name}'
                '-gap-$gap-targetGap-$targetGap';
            final Map<String, SpotlightGuideStepContext> contexts =
                <String, SpotlightGuideStepContext>{};
            final ValueKey<String> pointerKey = ValueKey<String>(
              '$label-pointer',
            );

            await tester.pumpWidget(
              guideApp(
                appKey: ValueKey<String>(label),
                textDirection: textDirection,
                child: singleTargetStack(
                  id: 'a',
                  left: target.left,
                  top: target.top,
                  width: target.width,
                  height: target.height,
                ),
                steps: <SpotlightGuideStep>[
                  SpotlightGuideStep.item(
                    SpotlightGuideStepItem(
                      targetId: 'a',
                      placement: placement,
                      targetDecoration: const SpotlightGuideTargetDecoration(
                        padding: EdgeInsets.zero,
                      ),
                      gap: gap,
                      minWidth: 96,
                      maxWidth: 140,
                      hintBuilder:
                          (
                            BuildContext context,
                            SpotlightGuideStepContext guide,
                          ) {
                            contexts[label] = guide;
                            return SpotlightGuideBubbleHint(
                              guide: guide,
                              pointer: SpotlightGuideHintPointer(
                                size: const Size(32, 32),
                                targetGap: targetGap,
                                child: SizedBox(
                                  key: pointerKey,
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                              child: const SizedBox(width: 96, height: 42),
                            );
                          },
                    ),
                  ),
                ],
              ),
            );
            await _pumpDirectionGuide(tester);

            final SpotlightGuideStepContext guide = contexts[label]!;
            final Rect pointerRect = tester.getRect(find.byKey(pointerKey));
            final Rect bubbleRect = tester.getRect(
              find.byType(SpotlightGuideBubble),
            );

            expect(guide.placement, resolvedPlacement, reason: label);
            expect(
              _signedTargetGap(pointerRect, guide),
              moreOrLessEquals(targetGap, epsilon: 0.5),
              reason: label,
            );
            expect(
              _signedPointerBubbleGap(pointerRect, bubbleRect, guide),
              moreOrLessEquals(gap, epsilon: 0.5),
              reason: label,
            );
          }
        }
      }
    }
  });

  test('pointer direction rotations cover every indicator direction', () {
    final Map<SpotlightGuideIndicatorDirection, double> expectedRadians =
        <SpotlightGuideIndicatorDirection, double>{
          SpotlightGuideIndicatorDirection.up: 0,
          SpotlightGuideIndicatorDirection.right: math.pi / 2,
          SpotlightGuideIndicatorDirection.down: math.pi,
          SpotlightGuideIndicatorDirection.left: -math.pi / 2,
        };

    for (final MapEntry<SpotlightGuideIndicatorDirection, double> entry
        in expectedRadians.entries) {
      final SpotlightGuidePointerContext pointer = _syntheticPointerContext(
        entry.key,
      );
      expect(
        pointer.targetRotation,
        moreOrLessEquals(entry.value, epsilon: 0.001),
        reason: entry.key.name,
      );
      expect(
        pointer.rotationToTarget(
          from: const SpotlightGuidePointerDirection.upRight(),
        ),
        moreOrLessEquals(
          _normalizeRotation(entry.value - math.pi / 4),
          epsilon: 0.001,
        ),
        reason: entry.key.name,
      );
      expect(
        pointer.rotationToward(
          const SpotlightGuidePointerDirection.left(math.pi / 2),
          from: const SpotlightGuidePointerDirection.right(math.pi / 2),
        ),
        moreOrLessEquals(math.pi, epsilon: 0.001),
      );
    }
  });

  test('pointer offsets resolve physical and semantic directions', () {
    const SpotlightGuidePointerOffset physical =
        SpotlightGuidePointerOffset.physical(
          left: 3,
          right: 11,
          up: 5,
          down: 17,
        );
    expect(physical.resolve(TextDirection.ltr), const Offset(8, 12));
    expect(physical.resolve(TextDirection.rtl), const Offset(8, 12));

    const SpotlightGuidePointerOffset semantic =
        SpotlightGuidePointerOffset.directional(
          start: 3,
          end: 11,
          up: 5,
          down: 17,
        );
    expect(semantic.resolve(TextDirection.ltr), const Offset(8, 12));
    expect(semantic.resolve(TextDirection.rtl), const Offset(-8, 12));
  });
}

Future<void> _pumpDirectionGuide(WidgetTester tester) async {
  await pumpGuideFrames(tester, count: 18);
}

class _TargetGeometry {
  const _TargetGeometry({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class _AutoPlacementCase {
  const _AutoPlacementCase({
    required this.label,
    required this.placement,
    required this.target,
    this.expectedPlacement,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final _TargetGeometry target;
  final SpotlightGuidePlacement? expectedPlacement;
}

class _VisualDirectionCase {
  const _VisualDirectionCase({
    required this.textDirection,
    required this.placement,
    required this.bubblePlacement,
  });

  final TextDirection textDirection;
  final SpotlightGuidePlacement placement;
  final SpotlightGuidePointerBubblePlacement bubblePlacement;
}

_TargetGeometry _targetFor(SpotlightGuidePlacement placement) {
  return switch (placement) {
    SpotlightGuidePlacement.bottom => const _TargetGeometry(
      left: 340,
      top: 88,
      width: 84,
      height: 58,
    ),
    SpotlightGuidePlacement.top => const _TargetGeometry(
      left: 340,
      top: 450,
      width: 84,
      height: 58,
    ),
    SpotlightGuidePlacement.left => const _TargetGeometry(
      left: 590,
      top: 260,
      width: 84,
      height: 58,
    ),
    SpotlightGuidePlacement.right => const _TargetGeometry(
      left: 86,
      top: 260,
      width: 84,
      height: 58,
    ),
    SpotlightGuidePlacement.auto ||
    SpotlightGuidePlacement.verticalAuto ||
    SpotlightGuidePlacement.horizontalAuto ||
    SpotlightGuidePlacement.start ||
    SpotlightGuidePlacement.end => throw StateError(
      'Expected a resolved physical placement.',
    ),
  };
}

SpotlightGuidePlacement _resolveStepPlacement(
  SpotlightGuidePlacement placement,
  TextDirection textDirection,
) {
  return switch (placement) {
    SpotlightGuidePlacement.start => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePlacement.left,
      TextDirection.rtl => SpotlightGuidePlacement.right,
    },
    SpotlightGuidePlacement.end => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePlacement.right,
      TextDirection.rtl => SpotlightGuidePlacement.left,
    },
    SpotlightGuidePlacement.top ||
    SpotlightGuidePlacement.bottom ||
    SpotlightGuidePlacement.left ||
    SpotlightGuidePlacement.right => placement,
    SpotlightGuidePlacement.auto ||
    SpotlightGuidePlacement.verticalAuto ||
    SpotlightGuidePlacement.horizontalAuto => throw StateError(
      'Auto placements are covered by a separate test.',
    ),
  };
}

SpotlightGuidePointerBubblePlacement _resolveBubblePlacement(
  SpotlightGuidePointerBubblePlacement placement,
  TextDirection textDirection,
) {
  return switch (placement) {
    SpotlightGuidePointerBubblePlacement.start => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePointerBubblePlacement.left,
      TextDirection.rtl => SpotlightGuidePointerBubblePlacement.right,
    },
    SpotlightGuidePointerBubblePlacement.end => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePointerBubblePlacement.right,
      TextDirection.rtl => SpotlightGuidePointerBubblePlacement.left,
    },
    SpotlightGuidePointerBubblePlacement.alongPlacement ||
    SpotlightGuidePointerBubblePlacement.top ||
    SpotlightGuidePointerBubblePlacement.bottom ||
    SpotlightGuidePointerBubblePlacement.left ||
    SpotlightGuidePointerBubblePlacement.right => placement,
  };
}

SpotlightGuideIndicatorDirection _targetDirectionFor(
  SpotlightGuidePlacement placement,
) {
  return switch (placement) {
    SpotlightGuidePlacement.top => SpotlightGuideIndicatorDirection.down,
    SpotlightGuidePlacement.bottom => SpotlightGuideIndicatorDirection.up,
    SpotlightGuidePlacement.left => SpotlightGuideIndicatorDirection.right,
    SpotlightGuidePlacement.right => SpotlightGuideIndicatorDirection.left,
    SpotlightGuidePlacement.auto ||
    SpotlightGuidePlacement.verticalAuto ||
    SpotlightGuidePlacement.horizontalAuto ||
    SpotlightGuidePlacement.start ||
    SpotlightGuidePlacement.end => throw StateError(
      'Expected a resolved physical placement.',
    ),
  };
}

bool _isPhysicalPlacement(SpotlightGuidePlacement placement) {
  return switch (placement) {
    SpotlightGuidePlacement.top ||
    SpotlightGuidePlacement.bottom ||
    SpotlightGuidePlacement.left ||
    SpotlightGuidePlacement.right => true,
    SpotlightGuidePlacement.auto ||
    SpotlightGuidePlacement.verticalAuto ||
    SpotlightGuidePlacement.horizontalAuto ||
    SpotlightGuidePlacement.start ||
    SpotlightGuidePlacement.end => false,
  };
}

SpotlightGuideIndicatorDirection _bubbleAnchorDirection(
  SpotlightGuideIndicatorDirection targetDirection,
  SpotlightGuidePointerBubblePlacement bubblePlacement,
) {
  return switch (bubblePlacement) {
    SpotlightGuidePointerBubblePlacement.alongPlacement => targetDirection,
    SpotlightGuidePointerBubblePlacement.top =>
      SpotlightGuideIndicatorDirection.down,
    SpotlightGuidePointerBubblePlacement.bottom =>
      SpotlightGuideIndicatorDirection.up,
    SpotlightGuidePointerBubblePlacement.left =>
      SpotlightGuideIndicatorDirection.right,
    SpotlightGuidePointerBubblePlacement.right =>
      SpotlightGuideIndicatorDirection.left,
    SpotlightGuidePointerBubblePlacement.start ||
    SpotlightGuidePointerBubblePlacement.end => throw StateError(
      'Semantic bubble placements must be resolved first.',
    ),
  };
}

SpotlightGuideIndicatorDirection _oppositeDirection(
  SpotlightGuideIndicatorDirection direction,
) {
  return switch (direction) {
    SpotlightGuideIndicatorDirection.up =>
      SpotlightGuideIndicatorDirection.down,
    SpotlightGuideIndicatorDirection.down =>
      SpotlightGuideIndicatorDirection.up,
    SpotlightGuideIndicatorDirection.left =>
      SpotlightGuideIndicatorDirection.right,
    SpotlightGuideIndicatorDirection.right =>
      SpotlightGuideIndicatorDirection.left,
  };
}

void _expectPointerTouchesTargetSide(
  Rect pointerRect,
  SpotlightGuideStepContext guide,
  String reason,
) {
  switch (guide.indicatorDirection) {
    case SpotlightGuideIndicatorDirection.up:
      expect(
        pointerRect.top,
        moreOrLessEquals(guide.targetRect.bottom, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.down:
      expect(
        pointerRect.bottom,
        moreOrLessEquals(guide.targetRect.top, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.left:
      expect(
        pointerRect.left,
        moreOrLessEquals(guide.targetRect.right, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.right:
      expect(
        pointerRect.right,
        moreOrLessEquals(guide.targetRect.left, epsilon: 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

void _expectPointerTouchesTargetSideOrPerpendicularOverhang({
  required Rect pointerRect,
  required Rect bubbleRect,
  required SpotlightGuideStepContext guide,
  required SpotlightGuideIndicatorDirection bubbleDirection,
  required String reason,
}) {
  final bool targetIsVertical =
      guide.indicatorDirection == SpotlightGuideIndicatorDirection.up ||
      guide.indicatorDirection == SpotlightGuideIndicatorDirection.down;
  final bool bubbleIsVertical =
      bubbleDirection == SpotlightGuideIndicatorDirection.up ||
      bubbleDirection == SpotlightGuideIndicatorDirection.down;
  if (targetIsVertical == bubbleIsVertical) {
    _expectPointerTouchesTargetSide(pointerRect, guide, reason);
    return;
  }

  final double overhang = targetIsVertical
      ? math.max(0, (bubbleRect.height - pointerRect.height) / 2)
      : math.max(0, (bubbleRect.width - pointerRect.width) / 2);
  switch (guide.indicatorDirection) {
    case SpotlightGuideIndicatorDirection.up:
      expect(
        pointerRect.top,
        greaterThanOrEqualTo(guide.targetRect.bottom - 0.5),
        reason: reason,
      );
      expect(
        pointerRect.top - guide.targetRect.bottom,
        lessThanOrEqualTo(overhang + 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.down:
      expect(
        pointerRect.bottom,
        lessThanOrEqualTo(guide.targetRect.top + 0.5),
        reason: reason,
      );
      expect(
        guide.targetRect.top - pointerRect.bottom,
        lessThanOrEqualTo(overhang + 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.left:
      expect(
        pointerRect.left,
        greaterThanOrEqualTo(guide.targetRect.right - 0.5),
        reason: reason,
      );
      expect(
        pointerRect.left - guide.targetRect.right,
        lessThanOrEqualTo(overhang + 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.right:
      expect(
        pointerRect.right,
        lessThanOrEqualTo(guide.targetRect.left + 0.5),
        reason: reason,
      );
      expect(
        guide.targetRect.left - pointerRect.right,
        lessThanOrEqualTo(overhang + 0.5),
        reason: reason,
      );
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

void _expectBubbleOnPointerSide({
  required Rect bubbleRect,
  required Rect pointerRect,
  required SpotlightGuideIndicatorDirection direction,
  required double gap,
  required String reason,
}) {
  switch (direction) {
    case SpotlightGuideIndicatorDirection.up:
      expect(
        bubbleRect.bottom,
        moreOrLessEquals(pointerRect.top - gap, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.down:
      expect(
        bubbleRect.top,
        moreOrLessEquals(pointerRect.bottom + gap, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.left:
      expect(
        bubbleRect.right,
        moreOrLessEquals(pointerRect.left - gap, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.right:
      expect(
        bubbleRect.left,
        moreOrLessEquals(pointerRect.right + gap, epsilon: 0.5),
        reason: reason,
      );
  }
}

void _expectBubbleAnchorAimsAtPointerCenter({
  required Rect bubbleRect,
  required Rect pointerRect,
  required SpotlightGuideAnchorGeometry anchorGeometry,
  required String reason,
}) {
  final double anchorAxis = _bubbleAnchorGlobalAxis(bubbleRect, anchorGeometry);
  switch (anchorGeometry.direction) {
    case SpotlightGuideIndicatorDirection.up ||
        SpotlightGuideIndicatorDirection.down:
      expect(
        anchorAxis,
        moreOrLessEquals(pointerRect.center.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.left ||
        SpotlightGuideIndicatorDirection.right:
      expect(
        anchorAxis,
        moreOrLessEquals(pointerRect.center.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

void _expectBubbleAnchorAimsAtTargetAnchor({
  required Rect bubbleRect,
  required SpotlightGuideStepContext guide,
  required SpotlightGuideAnchorGeometry anchorGeometry,
  required String reason,
}) {
  expect(
    _bubbleAnchorGlobalAxis(bubbleRect, anchorGeometry),
    moreOrLessEquals(_targetAnchorAxis(guide), epsilon: 0.5),
    reason: reason,
  );
}

void _expectPointerCrossAxisAlignedWithTargetAnchor(
  Rect pointerRect,
  SpotlightGuideStepContext guide,
  String reason,
) {
  switch (guide.indicatorDirection) {
    case SpotlightGuideIndicatorDirection.up ||
        SpotlightGuideIndicatorDirection.down:
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.targetAnchorPoint.dx, epsilon: 0.5),
        reason: reason,
      );
    case SpotlightGuideIndicatorDirection.left ||
        SpotlightGuideIndicatorDirection.right:
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.targetAnchorPoint.dy, epsilon: 0.5),
        reason: reason,
      );
  }
}

double _signedTargetGap(Rect pointerRect, SpotlightGuideStepContext guide) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up =>
      pointerRect.top - guide.targetRect.bottom,
    SpotlightGuideIndicatorDirection.down =>
      guide.targetRect.top - pointerRect.bottom,
    SpotlightGuideIndicatorDirection.left =>
      pointerRect.left - guide.targetRect.right,
    SpotlightGuideIndicatorDirection.right =>
      guide.targetRect.left - pointerRect.right,
  };
}

double _signedTargetHintGap(SpotlightGuideStepContext guide) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up =>
      guide.hintRect.top - guide.targetRect.bottom,
    SpotlightGuideIndicatorDirection.down =>
      guide.targetRect.top - guide.hintRect.bottom,
    SpotlightGuideIndicatorDirection.left =>
      guide.hintRect.left - guide.targetRect.right,
    SpotlightGuideIndicatorDirection.right =>
      guide.targetRect.left - guide.hintRect.right,
  };
}

double _signedPointerBubbleGap(
  Rect pointerRect,
  Rect bubbleRect,
  SpotlightGuideStepContext guide,
) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up => bubbleRect.top - pointerRect.bottom,
    SpotlightGuideIndicatorDirection.down =>
      pointerRect.top - bubbleRect.bottom,
    SpotlightGuideIndicatorDirection.left =>
      bubbleRect.left - pointerRect.right,
    SpotlightGuideIndicatorDirection.right =>
      pointerRect.left - bubbleRect.right,
  };
}

double _hintAnchorGlobalAxis(SpotlightGuideStepContext guide) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up ||
    SpotlightGuideIndicatorDirection.down =>
      guide.hintRect.left + guide.indicatorOffset,
    SpotlightGuideIndicatorDirection.left ||
    SpotlightGuideIndicatorDirection.right =>
      guide.hintRect.top + guide.indicatorOffset,
  };
}

double _targetAnchorAxis(SpotlightGuideStepContext guide) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up ||
    SpotlightGuideIndicatorDirection.down => guide.targetAnchorPoint.dx,
    SpotlightGuideIndicatorDirection.left ||
    SpotlightGuideIndicatorDirection.right => guide.targetAnchorPoint.dy,
  };
}

SpotlightGuideBubbleDecoration _bubbleDecoration(WidgetTester tester) {
  final dynamic bubble = tester.renderObject(find.byType(SpotlightGuideBubble));
  return bubble.effectiveDecoration as SpotlightGuideBubbleDecoration;
}

SpotlightGuideAnchorGeometry _bubbleAnchorGeometry(WidgetTester tester) {
  return _bubbleDecoration(tester).effectiveAnchorGeometry!;
}

double _bubbleAnchorGlobalAxis(
  Rect bubbleRect,
  SpotlightGuideAnchorGeometry anchorGeometry,
) {
  return switch (anchorGeometry.direction) {
    SpotlightGuideIndicatorDirection.up ||
    SpotlightGuideIndicatorDirection.down =>
      bubbleRect.left + anchorGeometry.offset,
    SpotlightGuideIndicatorDirection.left ||
    SpotlightGuideIndicatorDirection.right =>
      bubbleRect.top + anchorGeometry.offset,
  };
}

double _anchorAxisPosition(
  Rect rect,
  SpotlightGuideAnchorPosition position, {
  required bool isHorizontalAxis,
  required TextDirection textDirection,
}) {
  final bool reverse = isHorizontalAxis && textDirection == TextDirection.rtl;
  return switch (position.anchor) {
    SpotlightGuideAnchor.center =>
      (isHorizontalAxis ? rect.center.dx : rect.center.dy) +
          (reverse ? -position.offset : position.offset),
    SpotlightGuideAnchor.start =>
      isHorizontalAxis
          ? reverse
                ? rect.right - position.offset
                : rect.left + position.offset
          : rect.top + position.offset,
    SpotlightGuideAnchor.end =>
      isHorizontalAxis
          ? reverse
                ? rect.left + position.offset
                : rect.right - position.offset
          : rect.bottom - position.offset,
  };
}

SpotlightGuidePointerContext _syntheticPointerContext(
  SpotlightGuideIndicatorDirection targetDirection,
) {
  return SpotlightGuidePointerContext(
    guide: SpotlightGuideStepContext(
      index: 0,
      total: 1,
      itemIndex: 0,
      itemTotal: 1,
      targetRect: Rect.zero,
      targetRects: const <Rect>[Rect.zero],
      stepTargetRects: const <Rect>[Rect.zero],
      hintRect: Rect.zero,
      hintConstraints: const BoxConstraints(),
      targetAnchorPoint: Offset.zero,
      targetAnchorPosition: const SpotlightGuideAnchorPosition.center(),
      placement: SpotlightGuidePlacement.bottom,
      indicatorDirection: targetDirection,
      indicatorOffset: 0,
      indicatorSafeInset: 0,
      anchorConnectionHalfExtent: 0,
      bubbleIndicatorSideExtent: 0,
      contentSize: Size.zero,
      margin: EdgeInsets.zero,
      overlaySize: Size.zero,
      gap: 0,
      decoration: const SpotlightGuideBubbleDecoration(),
      indicatorSize: Size.zero,
      controller: SpotlightGuidePortalController(),
    ),
    textDirection: TextDirection.ltr,
    targetDirection: targetDirection,
    bubbleDirection: _oppositeDirection(targetDirection),
    bubbleAnchorDirection: targetDirection,
    bubblePlacement: SpotlightGuidePointerBubblePlacement.alongPlacement,
    anchorMode: SpotlightGuidePointerAnchorMode.pointer,
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

class _CapturedPixels {
  const _CapturedPixels({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;

  Color colorAt(int x, int y) {
    final int index = (y * width + x) * 4;
    return Color.fromARGB(
      bytes[index + 3],
      bytes[index],
      bytes[index + 1],
      bytes[index + 2],
    );
  }
}

Future<_CapturedPixels> _capturePixels(
  WidgetTester tester,
  GlobalKey key,
) async {
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final _CapturedPixels? pixels = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final ByteData byteData = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final Uint8List bytes = Uint8List.fromList(byteData.buffer.asUint8List());
    final int width = image.width;
    final int height = image.height;
    image.dispose();
    return _CapturedPixels(width: width, height: height, bytes: bytes);
  });
  return pixels!;
}

void _expectColorVisibleInRect(
  _CapturedPixels pixels,
  Rect rect,
  Color expected, {
  required String reason,
}) {
  final int left = rect.left.floor().clamp(0, pixels.width - 1);
  final int top = rect.top.floor().clamp(0, pixels.height - 1);
  final int right = rect.right.ceil().clamp(0, pixels.width);
  final int bottom = rect.bottom.ceil().clamp(0, pixels.height);
  int matches = 0;

  for (int y = top; y < bottom; y += 2) {
    for (int x = left; x < right; x += 2) {
      final Color actual = pixels.colorAt(x, y);
      if (_isCloseColor(actual, expected)) {
        matches++;
      }
    }
  }

  expect(
    matches,
    greaterThan(8),
    reason:
        '$reason expected ${expected.toARGB32().toRadixString(16)} in $rect',
  );
}

bool _isCloseColor(Color actual, Color expected) {
  final int actualArgb = actual.toARGB32();
  final int expectedArgb = expected.toARGB32();
  return (_colorChannel(actualArgb, 24) - _colorChannel(expectedArgb, 24))
              .abs() <=
          8 &&
      (_colorChannel(actualArgb, 16) - _colorChannel(expectedArgb, 16)).abs() <=
          8 &&
      (_colorChannel(actualArgb, 8) - _colorChannel(expectedArgb, 8)).abs() <=
          8 &&
      (_colorChannel(actualArgb, 0) - _colorChannel(expectedArgb, 0)).abs() <=
          8;
}

int _colorChannel(int argb, int shift) {
  return (argb >> shift) & 0xFF;
}
