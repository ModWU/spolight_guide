import 'dart:math' as math;

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Built-in hint UI tests.
///
/// Run this file when changing [SpotlightGuideBubble],
/// [SpotlightGuideBubbleDecoration], the connected bubble painter, or the way
/// [SpotlightGuideBubbleHint] resolves decoration data from
/// [SpotlightGuideStepContext]. It also covers spotlight-hole creation and
/// de-duplication in the barrier.
void main() {
  testWidgets('text hint renders progress and default navigation actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideTextHint(
                      guide: guide,
                      title: 'First title',
                      message: 'First message',
                    );
                  },
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'b',
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideTextHint(
                      guide: guide,
                      title: 'Second title',
                      message: 'Second message',
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.text('Step 1/2'), findsOneWidget);
    expect(find.text('First title'), findsOneWidget);
    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    await tester.tap(find.text('Next'));
    await pumpGuide(tester);

    expect(find.text('Step 2/2'), findsOneWidget);
    expect(find.text('Second title'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('bubble reserves anchor-side padding around its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SpotlightGuideBubble(
              decoration: const SpotlightGuideBubbleDecoration(
                anchor: SpotlightGuideTriangleAnchor(
                  size: Size(14, 8),
                  geometry: SpotlightGuideBubbleAnchorGeometry(
                    direction: SpotlightGuideDirection.up,
                    offset: 30,
                  ),
                ),
              ),
              child: const SizedBox(
                key: ValueKey<String>('bubble-child'),
                width: 100,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size bubbleSize = tester.getSize(find.byType(SpotlightGuideBubble));
    // The upward triangle adds its 8px height to the top. Content padding
    // defaults to zero so custom children control their own inset.
    expect(bubbleSize.width, moreOrLessEquals(100, epsilon: 0.5));
    expect(bubbleSize.height, moreOrLessEquals(40 + 8, epsilon: 0.5));
    expect(find.byKey(const ValueKey<String>('bubble-child')), findsOneWidget);
  });

  testWidgets('bubble applies explicit content padding around its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SpotlightGuideBubble(
              decoration: const SpotlightGuideBubbleDecoration(
                contentPadding: EdgeInsets.fromLTRB(24, 18, 24, 20),
                anchor: SpotlightGuideNoAnchor(),
              ),
              child: const SizedBox(
                key: ValueKey<String>('padded-bubble-child'),
                width: 100,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size bubbleSize = tester.getSize(find.byType(SpotlightGuideBubble));
    expect(bubbleSize.width, moreOrLessEquals(100 + 24 + 24, epsilon: 0.5));
    expect(bubbleSize.height, moreOrLessEquals(40 + 18 + 20, epsilon: 0.5));
  });

  testWidgets('bubble paints clipped content below an upward anchor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: const Align(
            alignment: Alignment.topLeft,
            child: SpotlightGuideBubble(
              decoration: SpotlightGuideBubbleDecoration(
                color: Color(0xFFFFFFFF),
                anchor: SpotlightGuideTriangleAnchor(
                  size: Size(20, 20),
                  geometry: SpotlightGuideBubbleAnchorGeometry(
                    direction: SpotlightGuideDirection.up,
                    offset: 20,
                  ),
                ),
              ),
              child: SizedBox(
                width: 40,
                height: 20,
                child: ColoredBox(color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(SpotlightGuideBubble),
      paints
        ..clipRRect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 20, 40, 20),
            const Radius.circular(6),
          ),
        )
        ..rect(
          rect: const Rect.fromLTWH(0, 20, 40, 20),
          color: const Color(0xFF000000),
        ),
    );
  });

  testWidgets('home intro text hint paints visible content', (tester) async {
    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 80,
          top: 80,
          width: 180,
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
              decoration: const SpotlightGuideBubbleDecoration(
                anchor: SpotlightGuideTriangleAnchor(size: Size(22, 14)),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideTextHint(
                      guide: guide,
                      title: 'Start simple',
                      message:
                          'Use the built-in text hint for the smallest path.',
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final Rect bubbleRect = tester.getRect(find.byType(SpotlightGuideBubble));
    for (final String text in <String>[
      'Start simple',
      'Use the built-in text hint for the smallest path.',
      'Done',
    ]) {
      final Finder finder = find.text(text);
      expect(finder, findsOneWidget);
      expect(
        tester.getRect(finder),
        isA<Rect>().having(
          (Rect rect) => bubbleRect.overlaps(rect),
          'overlaps bubble',
          isTrue,
        ),
      );
    }
  });

  testWidgets('bubble hint inherits decoration from guide context', (
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
                border: BorderSide(color: Color(0xFF112233), width: 2),
                anchor: SpotlightGuideTriangleAnchor(tipArcAngle: math.pi / 6),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(
                        key: ValueKey<String>('inherit-border'),
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

    expect(find.byKey(const ValueKey<String>('inherit-border')), findsWidgets);
    final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(tester);
    expect(
      decoration.border,
      const BorderSide(color: Color(0xFF112233), width: 2),
    );
    expect(decoration.anchor, isA<SpotlightGuideTriangleAnchor>());
    expect(
      (decoration.anchor as SpotlightGuideTriangleAnchor).tipArcAngle,
      moreOrLessEquals(math.pi / 6),
    );
  });

  testWidgets('rounded triangle anchor paints without flattening layout', (
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
                anchor: SpotlightGuideTriangleAnchor(
                  size: Size(24, 16),
                  tipArcAngle: math.pi / 6,
                ),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: const SizedBox(
                        key: ValueKey<String>('rounded-triangle-anchor'),
                        width: 120,
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

    final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(tester);
    final SpotlightGuideTriangleAnchor anchor =
        decoration.anchor as SpotlightGuideTriangleAnchor;

    expect(
      find.byKey(const ValueKey<String>('rounded-triangle-anchor')),
      findsWidgets,
    );
    expect(anchor.size, const Size(24, 16));
    expect(anchor.tipArcAngle, moreOrLessEquals(math.pi / 6));
  });

  testWidgets(
    'bubble hint visual stays inside horizontal margin near target edge anchors',
    (tester) async {
      const double margin = 40;
      const List<_EdgeAnchorCase> cases = <_EdgeAnchorCase>[
        _EdgeAnchorCase(
          label: 'ltr-start-left',
          direction: TextDirection.ltr,
          targetLeft: 20,
          anchor: SpotlightGuideAnchorPosition.start(),
        ),
        _EdgeAnchorCase(
          label: 'ltr-end-right',
          direction: TextDirection.ltr,
          targetLeft: 700,
          anchor: SpotlightGuideAnchorPosition.end(),
        ),
        _EdgeAnchorCase(
          label: 'rtl-start-right',
          direction: TextDirection.rtl,
          targetLeft: 700,
          anchor: SpotlightGuideAnchorPosition.start(),
        ),
        _EdgeAnchorCase(
          label: 'rtl-end-left',
          direction: TextDirection.rtl,
          targetLeft: 20,
          anchor: SpotlightGuideAnchorPosition.end(),
        ),
      ];

      for (final caseInfo in cases) {
        await tester.pumpWidget(
          guideApp(
            appKey: ValueKey<String>(caseInfo.label),
            textDirection: caseInfo.direction,
            child: singleTargetStack(
              id: 'a',
              left: caseInfo.targetLeft,
              top: 120,
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
                  margin: const EdgeInsets.symmetric(horizontal: margin),
                  targetAnchorPosition: caseInfo.anchor,
                  hintBuilder:
                      (BuildContext context, SpotlightGuideStepContext guide) {
                        return SpotlightGuideBubbleHint(
                          guide: guide,
                          child: const SizedBox(
                            width: 360,
                            height: 40,
                            child: Text('edge anchor'),
                          ),
                        );
                      },
                ),
              ),
            ],
          ),
        );
        await pumpGuide(tester);

        final Rect bubbleRect = tester.getRect(
          find.byType(SpotlightGuideBubble).last,
        );
        expect(
          bubbleRect.left,
          greaterThanOrEqualTo(margin - 0.5),
          reason: caseInfo.label,
        );
        expect(
          bubbleRect.right,
          lessThanOrEqualTo(800 - margin + 0.5),
          reason: caseInfo.label,
        );
      }
    },
  );

  testWidgets(
    'bubble hint keeps first visible frame aligned after measurement',
    (tester) async {
      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 280,
            top: 60,
            width: 40,
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
                  anchor: SpotlightGuideTriangleAnchor(size: Size(40, 24)),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuideBubbleHint(
                        guide: guide,
                        child: const SizedBox(
                          key: ValueKey<String>('stable-bubble-child'),
                          width: 120,
                          height: 40,
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      );

      final Finder child = find.byKey(
        const ValueKey<String>('stable-bubble-child'),
      );
      Offset? firstVisibleTopLeft;
      for (int i = 0; i < 8; i += 1) {
        await tester.pump();
        if (tester.any(child) && _hintOpacityFor(tester, child) == 1) {
          firstVisibleTopLeft = tester.getTopLeft(child);
          break;
        }
      }
      expect(firstVisibleTopLeft, isNotNull);

      await tester.pump();
      expect(tester.getTopLeft(child), firstVisibleTopLeft);

      await tester.pump();
      expect(tester.getTopLeft(child), firstVisibleTopLeft);
    },
  );

  testWidgets('bubble hint decoration override wins over guide context', (
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
                border: BorderSide(color: Color(0xFF112233), width: 2),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      decoration: const SpotlightGuideBubbleDecoration(
                        border: BorderSide(color: Color(0xFFAABBCC), width: 5),
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

    final SpotlightGuideBubbleDecoration decoration = _bubbleDecoration(tester);
    expect(
      decoration.border,
      const BorderSide(color: Color(0xFFAABBCC), width: 5),
    );
  });

  testWidgets('path anchor builder exposes resolved physical direction', (
    tester,
  ) async {
    final List<SpotlightGuideDirection> directions =
        <SpotlightGuideDirection>[];
    final Map<SpotlightGuidePlacement, SpotlightGuideDirection> cases =
        <SpotlightGuidePlacement, SpotlightGuideDirection>{
          SpotlightGuidePlacement.top: SpotlightGuideDirection.down,
          SpotlightGuidePlacement.bottom: SpotlightGuideDirection.up,
          SpotlightGuidePlacement.left: SpotlightGuideDirection.right,
          SpotlightGuidePlacement.right: SpotlightGuideDirection.left,
        };

    for (final MapEntry<SpotlightGuidePlacement, SpotlightGuideDirection> entry
        in cases.entries) {
      directions.clear();
      await tester.pumpWidget(
        guideApp(
          child: singleTargetStack(
            id: 'a',
            left: 300,
            top: 220,
            width: 80,
            height: 40,
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: entry.key,
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                decoration: SpotlightGuideBubbleDecoration(
                  anchor: SpotlightGuidePathAnchor(
                    shape: _RecordingPathAnchorShape(directions),
                  ),
                ),
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
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
      await tester.pump();

      expect(directions, contains(entry.value));
    }
  });

  testWidgets('bubble border does not block child taps', (tester) async {
    int taps = 0;

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
                border: BorderSide(color: Colors.red, width: 10),
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      child: TextButton(
                        key: const ValueKey<String>('border-button'),
                        onPressed: () => taps++,
                        child: const Text('OK'),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    await tester.tap(find.byKey(const ValueKey<String>('border-button')));
    await pumpGuide(tester);

    expect(taps, 1);
  });

  testWidgets('bubble can use a proxy decoration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SpotlightGuideBubble(
              decoration: const SpotlightGuideProxyDecoration(
                decoration: BoxDecoration(
                  color: Color(0xFFABCDEF),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                anchor: SpotlightGuideNoAnchor(),
                contentClipBorderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: SizedBox(
                key: const ValueKey<String>('proxy-child'),
                width: 80,
                height: 30,
                child: ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final SpotlightGuideAnchoredDecoration decoration =
        _effectiveBubbleDecoration(tester);
    expect(decoration, isA<SpotlightGuideProxyDecoration>());
    expect(find.byKey(const ValueKey<String>('proxy-child')), findsOneWidget);
  });

  test('path anchor separates body connection from visual width', () {
    const _WideVisualAnchorShape shape = _WideVisualAnchorShape();
    const SpotlightGuidePathAnchor anchor = SpotlightGuidePathAnchor(
      shape: shape,
      geometry: SpotlightGuideBubbleAnchorGeometry(
        direction: SpotlightGuideDirection.up,
        offset: 40,
      ),
    );
    final Rect body = Rect.fromLTWH(20, 40, 120, 80);
    final SpotlightGuideBubbleAnchorConnection connection = anchor
        .resolveConnection(
          body: body,
          paintOffset: const Offset(20, 0),
          paintSize: const Size(120, 120),
          geometry: null,
        )!;

    expect(connection.start, moreOrLessEquals(body.left + 40 - 5));
    expect(connection.end, moreOrLessEquals(body.left + 40 + 5));
    expect(anchor.safeInset(borderRadius: 6), moreOrLessEquals(30));

    final Path path = Path()..moveTo(connection.start, body.top);
    anchor.addToPath(
      path: path,
      body: body,
      paintOffset: const Offset(20, 0),
      paintSize: const Size(120, 120),
      geometry: null,
    );

    final Rect bounds = path.getBounds();
    expect(bounds.left, lessThan(connection.start - 4));
    expect(bounds.right, greaterThan(connection.end + 4));
    expect(bounds.top, moreOrLessEquals(0));
  });
}

SpotlightGuideAnchoredDecoration _effectiveBubbleDecoration(
  WidgetTester tester,
) {
  final dynamic bubble = tester.renderObject(find.byType(SpotlightGuideBubble));
  return bubble.effectiveDecoration as SpotlightGuideAnchoredDecoration;
}

SpotlightGuideBubbleDecoration _bubbleDecoration(WidgetTester tester) {
  return _effectiveBubbleDecoration(tester) as SpotlightGuideBubbleDecoration;
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

class _EdgeAnchorCase {
  const _EdgeAnchorCase({
    required this.label,
    required this.direction,
    required this.targetLeft,
    required this.anchor,
  });

  final String label;
  final TextDirection direction;
  final double targetLeft;
  final SpotlightGuideAnchorPosition anchor;
}

class _WideVisualAnchorShape extends SpotlightGuidePathAnchorShape {
  const _WideVisualAnchorShape();

  @override
  Size get preferredSize => const Size(48, 40);

  @override
  double get connectionHalfExtent => 5;

  @override
  double get visualHalfExtent => 24;

  @override
  void addToPath(Path path, SpotlightGuideBubbleAnchorPathBuilder builder) {
    builder.cubicTo(path, builder.startSide - 0.2, 0.1, -0.6, 0.4, -0.2, 0.7);
    builder.lineTo(path, 0, 1);
    builder.lineTo(path, 0.5, 0.6);
    builder.cubicTo(
      path,
      0.5,
      0.3,
      builder.endSide + 0.2,
      0.1,
      builder.endSide,
      0,
    );
  }
}

class _RecordingPathAnchorShape extends SpotlightGuidePathAnchorShape {
  const _RecordingPathAnchorShape(this.directions);

  final List<SpotlightGuideDirection> directions;

  @override
  Size get preferredSize => const Size(16, 10);

  @override
  double get connectionHalfExtent => 6;

  @override
  void addToPath(Path path, SpotlightGuideBubbleAnchorPathBuilder builder) {
    directions.add(builder.direction);
    builder.lineTo(path, 0, 1);
    builder.lineTo(path, builder.endSide, 0);
  }
}
