import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import 'spotlight_guide_test_helpers.dart';

/// Position axis semantics.
///
/// Run this file when changing [SpotlightGuideAxisPosition],
/// [SpotlightGuideAnchorPosition], [SpotlightGuidePointPosition],
/// [SpotlightGuidePlacement.start], [SpotlightGuidePlacement.end], or
/// direction-aware offset resolution.
void main() {
  testWidgets(
    'anchorTargetPosition mainAxisOffset follows the resolved connection side',
    (tester) async {
      const double offset = 14;

      for (final TextDirection textDirection in TextDirection.values) {
        for (final SpotlightGuidePlacement placement in _physicalPlacements) {
          final String label =
              'anchor-main-${textDirection.name}-${placement.name}';
          final SpotlightGuideStepContext guide = await _pumpAnchorPosition(
            tester,
            label: label,
            textDirection: textDirection,
            placement: placement,
            anchorPosition: const SpotlightGuideAnchorPosition.center(offset),
          );

          final Offset expected = _expectedAnchorPoint(
            guide.targetRect,
            placement: placement,
            textDirection: textDirection,
            alignment: SpotlightGuideAnchorAlignment.center,
            mainAxisOffset: offset,
          );
          expect(guide.anchorTargetPoint.dx, moreOrLessEquals(expected.dx));
          expect(guide.anchorTargetPoint.dy, moreOrLessEquals(expected.dy));
        }
      }
    },
  );

  testWidgets('anchorTargetPosition start and end use the correct edge', (
    tester,
  ) async {
    for (final TextDirection textDirection in TextDirection.values) {
      for (final SpotlightGuidePlacement placement in _physicalPlacements) {
        for (final _AlignmentCase testCase in _alignmentCases) {
          final String label =
              'anchor-edge-${textDirection.name}-${placement.name}'
              '-${testCase.alignment.name}';
          final SpotlightGuideStepContext guide = await _pumpAnchorPosition(
            tester,
            label: label,
            textDirection: textDirection,
            placement: placement,
            anchorPosition: testCase.position,
          );

          final Offset expected = _expectedAnchorPoint(
            guide.targetRect,
            placement: placement,
            textDirection: textDirection,
            alignment: testCase.alignment,
            mainAxisOffset: testCase.mainAxisOffset,
          );
          expect(guide.anchorTargetPoint.dx, moreOrLessEquals(expected.dx));
          expect(guide.anchorTargetPoint.dy, moreOrLessEquals(expected.dy));
        }
      }
    }
  });

  testWidgets(
    'pointerTargetPosition offsets resolve from the target on every side',
    (tester) async {
      const double distance = 10;

      for (final TextDirection textDirection in TextDirection.values) {
        for (final SpotlightGuidePlacement placement in _physicalPlacements) {
          final String label =
              'point-cross-${textDirection.name}-${placement.name}';
          final _PointerLayout layout = await _pumpPointerPosition(
            tester,
            label: label,
            textDirection: textDirection,
            placement: placement,
            pointerTargetPosition: const SpotlightGuidePointPosition.center(
              0,
              distance,
            ),
          );

          _expectPointerTargetContact(
            pointerRect: layout.pointerRect,
            guide: layout.guide,
            reason: label,
          );
        }
      }
    },
  );

  testWidgets(
    'semantic start and end placements resolve before position math',
    (tester) async {
      const double mainOffset = 6;
      const List<SpotlightGuidePlacement> placements =
          <SpotlightGuidePlacement>[
            SpotlightGuidePlacement.start,
            SpotlightGuidePlacement.end,
          ];

      for (final TextDirection textDirection in TextDirection.values) {
        for (final SpotlightGuidePlacement placement in placements) {
          final SpotlightGuidePlacement resolvedPlacement =
              _resolveSemanticPlacement(placement, textDirection);
          final String label =
              'semantic-${textDirection.name}-${placement.name}';
          final SpotlightGuideStepContext guide = await _pumpAnchorPosition(
            tester,
            label: label,
            textDirection: textDirection,
            placement: placement,
            anchorPosition: const SpotlightGuideAnchorPosition.center(
              mainOffset,
            ),
          );

          final Offset expected = _expectedAnchorPoint(
            guide.targetRect,
            placement: resolvedPlacement,
            textDirection: textDirection,
            alignment: SpotlightGuideAnchorAlignment.center,
            mainAxisOffset: mainOffset,
          );
          expect(guide.placement, resolvedPlacement);
          expect(guide.anchorTargetPoint.dx, moreOrLessEquals(expected.dx));
          expect(guide.anchorTargetPoint.dy, moreOrLessEquals(expected.dy));
        }
      }
    },
  );
}

const List<SpotlightGuidePlacement> _physicalPlacements =
    <SpotlightGuidePlacement>[
      SpotlightGuidePlacement.top,
      SpotlightGuidePlacement.bottom,
      SpotlightGuidePlacement.left,
      SpotlightGuidePlacement.right,
    ];

const List<_AlignmentCase> _alignmentCases = <_AlignmentCase>[
  _AlignmentCase(
    alignment: SpotlightGuideAnchorAlignment.start,
    mainAxisOffset: 11,
    position: SpotlightGuideAnchorPosition.start(11),
  ),
  _AlignmentCase(
    alignment: SpotlightGuideAnchorAlignment.end,
    mainAxisOffset: 13,
    position: SpotlightGuideAnchorPosition.end(13),
  ),
];

class _AlignmentCase {
  const _AlignmentCase({
    required this.alignment,
    required this.mainAxisOffset,
    required this.position,
  });

  final SpotlightGuideAnchorAlignment alignment;
  final double mainAxisOffset;
  final SpotlightGuideAnchorPosition position;
}

class _PointerLayout {
  const _PointerLayout({required this.guide, required this.pointerRect});

  final SpotlightGuideStepContext guide;
  final Rect pointerRect;
}

Future<SpotlightGuideStepContext> _pumpAnchorPosition(
  WidgetTester tester, {
  required String label,
  required TextDirection textDirection,
  required SpotlightGuidePlacement placement,
  required SpotlightGuideAnchorPosition anchorPosition,
}) async {
  final Map<String, SpotlightGuideStepContext> contexts =
      <String, SpotlightGuideStepContext>{};

  await tester.pumpWidget(
    guideApp(
      appKey: ValueKey<String>(label),
      textDirection: textDirection,
      child: singleTargetStack(
        id: 'a',
        left: 340,
        top: 250,
        width: 120,
        height: 80,
      ),
      steps: <SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'a',
            placement: placement,
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            anchorTargetPosition: anchorPosition,
            gap: 8,
            minWidth: 80,
            maxWidth: 120,
            hintBuilder: sizedHint(label, 80, 32, contexts),
          ),
        ),
      ],
    ),
  );
  await pumpGuide(tester);
  return contexts[label]!;
}

Future<_PointerLayout> _pumpPointerPosition(
  WidgetTester tester, {
  required String label,
  required TextDirection textDirection,
  required SpotlightGuidePlacement placement,
  required SpotlightGuidePointPosition pointerTargetPosition,
}) async {
  const Size pointerSize = Size(40, 30);
  final Map<String, SpotlightGuideStepContext> contexts =
      <String, SpotlightGuideStepContext>{};
  final ValueKey<String> pointerKey = ValueKey<String>('$label-pointer');

  await tester.pumpWidget(
    guideApp(
      appKey: ValueKey<String>(label),
      textDirection: textDirection,
      child: singleTargetStack(
        id: 'a',
        left: 340,
        top: 250,
        width: 120,
        height: 80,
      ),
      steps: <SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'a',
            placement: placement,
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            gap: 8,
            minWidth: 80,
            maxWidth: 120,
            pointer: SpotlightGuidePointer(
              size: pointerSize,
              pointerTargetPosition: pointerTargetPosition,
              child: SizedBox(
                key: pointerKey,
                width: pointerSize.width,
                height: pointerSize.height,
              ),
            ),
            hintBuilder:
                (BuildContext context, SpotlightGuideStepContext guide) {
                  contexts[label] = guide;
                  return SpotlightGuideBubbleHint(
                    guide: guide,
                    child: const SizedBox(width: 80, height: 32),
                  );
                },
          ),
        ),
      ],
    ),
  );
  await pumpGuide(tester);
  return _PointerLayout(
    guide: contexts[label]!,
    pointerRect: tester.getRect(find.byKey(pointerKey)),
  );
}

Offset _expectedAnchorPoint(
  Rect rect, {
  required SpotlightGuidePlacement placement,
  required TextDirection textDirection,
  required SpotlightGuideAnchorAlignment alignment,
  double mainAxisOffset = 0,
}) {
  final bool horizontalMainAxis =
      placement == SpotlightGuidePlacement.top ||
      placement == SpotlightGuidePlacement.bottom;
  if (horizontalMainAxis) {
    return Offset(
      _resolveHorizontalAxis(
        rect,
        textDirection: textDirection,
        alignment: alignment,
        offset: mainAxisOffset,
      ),
      rect.center.dy,
    );
  }
  return Offset(
    rect.center.dx,
    _resolveVerticalAxis(rect, alignment: alignment, offset: mainAxisOffset),
  );
}

double _resolveHorizontalAxis(
  Rect rect, {
  required TextDirection textDirection,
  required SpotlightGuideAnchorAlignment alignment,
  required double offset,
}) {
  final bool rtl = textDirection == TextDirection.rtl;
  return switch (alignment) {
    SpotlightGuideAnchorAlignment.center =>
      rect.center.dx + (rtl ? -offset : offset),
    SpotlightGuideAnchorAlignment.start =>
      rtl ? rect.right - offset : rect.left + offset,
    SpotlightGuideAnchorAlignment.end =>
      rtl ? rect.left + offset : rect.right - offset,
  };
}

double _resolveVerticalAxis(
  Rect rect, {
  required SpotlightGuideAnchorAlignment alignment,
  required double offset,
}) {
  return switch (alignment) {
    SpotlightGuideAnchorAlignment.center => rect.center.dy + offset,
    SpotlightGuideAnchorAlignment.start => rect.top + offset,
    SpotlightGuideAnchorAlignment.end => rect.bottom - offset,
  };
}

void _expectPointerTargetContact({
  required Rect pointerRect,
  required SpotlightGuideStepContext guide,
  required String reason,
}) {
  final String details =
      '$reason pointer=$pointerRect anchorTarget=${guide.anchorTargetPoint} '
      'pointerTarget=${guide.pointerTargetPoint} target=${guide.targetRect}';
  switch (guide.anchorDirection) {
    case SpotlightGuideDirection.up:
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.pointerTargetPoint.dx, epsilon: 0.5),
        reason: details,
      );
      expect(
        pointerRect.top,
        moreOrLessEquals(guide.pointerTargetPoint.dy, epsilon: 0.5),
        reason: details,
      );
    case SpotlightGuideDirection.down:
      expect(
        pointerRect.center.dx,
        moreOrLessEquals(guide.pointerTargetPoint.dx, epsilon: 0.5),
        reason: details,
      );
      expect(
        pointerRect.bottom,
        moreOrLessEquals(guide.pointerTargetPoint.dy, epsilon: 0.5),
        reason: details,
      );
    case SpotlightGuideDirection.left:
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.pointerTargetPoint.dy, epsilon: 0.5),
        reason: details,
      );
      expect(
        pointerRect.left,
        moreOrLessEquals(guide.pointerTargetPoint.dx, epsilon: 0.5),
        reason: details,
      );
    case SpotlightGuideDirection.right:
      expect(
        pointerRect.center.dy,
        moreOrLessEquals(guide.pointerTargetPoint.dy, epsilon: 0.5),
        reason: details,
      );
      expect(
        pointerRect.right,
        moreOrLessEquals(guide.pointerTargetPoint.dx, epsilon: 0.5),
        reason: details,
      );
  }
}

SpotlightGuidePlacement _resolveSemanticPlacement(
  SpotlightGuidePlacement placement,
  TextDirection textDirection,
) {
  return switch (placement) {
    SpotlightGuidePlacement.start =>
      textDirection == TextDirection.rtl
          ? SpotlightGuidePlacement.right
          : SpotlightGuidePlacement.left,
    SpotlightGuidePlacement.end =>
      textDirection == TextDirection.rtl
          ? SpotlightGuidePlacement.left
          : SpotlightGuidePlacement.right,
    _ => placement,
  };
}
