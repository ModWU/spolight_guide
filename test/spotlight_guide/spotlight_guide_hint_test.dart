import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  testWidgets('bubble reserves indicator-side padding around its child', (
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
                  geometry: SpotlightGuideAnchorGeometry(
                    direction: SpotlightGuideIndicatorDirection.up,
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
    final SpotlightGuideBubbleDecoration decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((DecoratedBox box) => box.decoration)
        .whereType<SpotlightGuideBubbleDecoration>()
        .first;
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

    final SpotlightGuideBubbleDecoration decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((DecoratedBox box) => box.decoration)
        .whereType<SpotlightGuideBubbleDecoration>()
        .first;
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
        if (tester.any(child)) {
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

    final SpotlightGuideBubbleDecoration decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((DecoratedBox box) => box.decoration)
        .whereType<SpotlightGuideBubbleDecoration>()
        .first;
    expect(
      decoration.border,
      const BorderSide(color: Color(0xFFAABBCC), width: 5),
    );
  });

  testWidgets('path anchor builder exposes resolved physical direction', (
    tester,
  ) async {
    final List<SpotlightGuideIndicatorDirection> directions =
        <SpotlightGuideIndicatorDirection>[];
    final Map<SpotlightGuidePlacement, SpotlightGuideIndicatorDirection> cases =
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
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      pointerSize: const Size(24, 24),
                      pointer: const SizedBox(
                        key: ValueKey<String>('pointer-on-border'),
                        width: 24,
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

    expect(
      find.byKey(const ValueKey<String>('pointer-on-border')),
      findsOneWidget,
    );

    final Stack outerStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(SpotlightGuideBubbleHint),
            matching: find.byType(Stack),
          )
          .last,
    );
    expect(outerStack.children.first, isA<Positioned>());
    expect(outerStack.children.last, isNot(isA<Positioned>()));
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
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return SpotlightGuideBubbleHint(
                      guide: guide,
                      pointerLayer: SpotlightGuidePointerLayer.aboveBubble,
                      pointerSize: const Size(24, 24),
                      pointer: const SizedBox(width: 24, height: 24),
                      child: const SizedBox(width: 100, height: 40),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final Stack outerStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(SpotlightGuideBubbleHint),
            matching: find.byType(Stack),
          )
          .last,
    );
    expect(outerStack.children.last, isA<Positioned>());
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

    final DecoratedBox decoratedBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SpotlightGuideBubble),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(decoratedBox.decoration, isA<SpotlightGuideProxyDecoration>());
    expect(find.byKey(const ValueKey<String>('proxy-child')), findsOneWidget);
  });

  test('path anchor separates body connection from visual width', () {
    const _WideVisualAnchorShape shape = _WideVisualAnchorShape();
    const SpotlightGuidePathAnchor anchor = SpotlightGuidePathAnchor(
      shape: shape,
      geometry: SpotlightGuideAnchorGeometry(
        direction: SpotlightGuideIndicatorDirection.up,
        offset: 40,
      ),
    );
    final Rect body = Rect.fromLTWH(20, 40, 120, 80);
    final SpotlightGuideAnchorConnection connection = anchor.resolveConnection(
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

  testWidgets('portal barrier style is inherited by steps', (tester) async {
    await tester.pumpWidget(
      guideApp(
        barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
        child: singleTargetStack(
          id: 'a',
          left: 200,
          top: 150,
          width: 60,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('blur-barrier'),
            ),
            barrier: const SpotlightGuideBarrierStyle(color: Color(0x66000000)),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('blur-barrier')), findsOneWidget);
  });

  testWidgets('step barrier style can override portal blur', (tester) async {
    await tester.pumpWidget(
      guideApp(
        barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
        child: singleTargetStack(
          id: 'a',
          left: 200,
          top: 150,
          width: 60,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('no-blur-barrier'),
            ),
            barrier: const SpotlightGuideBarrierStyle(blurSigma: 0),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('no-blur-barrier')),
      findsOneWidget,
    );
  });

  testWidgets('identical spotlight holes are de-duplicated', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        child: singleTargetStack(
          id: 'a',
          left: 200,
          top: 150,
          width: 60,
          height: 40,
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('dedup-a', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('dedup-b', contexts),
              ),
            ],
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    // Two items, but they highlight the same rect with the same radius, so the
    // barrier should only cut one hole.
    expect(contexts['dedup-a']?.itemTotal, 2);
    expect(contexts['dedup-a']?.stepTargetRects.length, 1);
    expect(contexts['dedup-b']?.stepTargetRects.length, 1);
  });

  testWidgets('overlapping spotlight holes stay transparent as one union', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        barrier: const SpotlightGuideBarrierStyle(
          color: Colors.black,
          blurSigma: 1,
        ),
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: ColoredBox(color: Colors.white)),
            Positioned(
              left: 100,
              top: 100,
              child: SpotlightGuideTarget(
                id: 'outer',
                child: SizedBox(
                  width: 200,
                  height: 90,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 160,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'inner',
                child: SizedBox(
                  width: 60,
                  height: 40,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetIds: const <Object>['outer', 'inner'],
              anchorTargetId: 'inner',
              placement: SpotlightGuidePlacement.bottom,
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
                shape: SpotlightGuideRoundedRectTargetShape(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              hintBuilder: sizedHint('nested-hole', 1, 1, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    // This mirrors a guide step that highlights a whole summary row while using
    // a nested card inside that row as the anchor. The inner card must remain a
    // real hole instead of being toggled back into the dim barrier.
    final ClipPath barrierClip = tester.widget<ClipPath>(
      find.byWidgetPredicate(
        (Widget widget) => widget is ClipPath && widget.child is BackdropFilter,
      ),
    );
    final CustomClipper<Path> barrierClipper = barrierClip.clipper!;
    final Path barrierPath = barrierClipper.getClip(
      tester.getSize(find.byType(SpotlightGuidePortal)),
    );
    final SpotlightGuideStepContext guide = contexts['nested-hole']!;

    expect(
      barrierPath.contains(guide.targetRect.center),
      isFalse,
      reason:
          'clipper=${barrierClipper.runtimeType}, '
          'target=${guide.targetRect}, stepTargets=${guide.stepTargetRects}',
    );
    expect(barrierPath.contains(const Offset(20, 20)), isTrue);
  });

  testWidgets('oversized spotlight holes are clipped to the overlay bounds', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        barrier: const SpotlightGuideBarrierStyle(
          color: Colors.black,
          blurSigma: 1,
        ),
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: ColoredBox(color: Colors.white)),
            Positioned(
              left: -40,
              top: 100,
              child: SpotlightGuideTarget(
                id: 'oversized',
                child: SizedBox(
                  width: 900,
                  height: 80,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'oversized',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.all(6),
                shape: SpotlightGuideRoundedRectTargetShape(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              hintBuilder: sizedHint('oversized-hole', 1, 1, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['oversized-hole']!;
    final Rect visualHole = guide.targetRects.single;
    expect(visualHole.left, 0);
    expect(visualHole.right, guide.overlaySize.width);
    expect(visualHole.top, moreOrLessEquals(94, epsilon: 0.5));
    expect(visualHole.bottom, moreOrLessEquals(186, epsilon: 0.5));
    expect(guide.targetRect.left, lessThan(0));
    expect(guide.targetRect.right, greaterThan(guide.overlaySize.width));

    final ClipPath barrierClip = tester.widget<ClipPath>(
      find.byWidgetPredicate(
        (Widget widget) => widget is ClipPath && widget.child is BackdropFilter,
      ),
    );
    final CustomClipper<Path> barrierClipper = barrierClip.clipper!;
    final Path barrierPath = barrierClipper.getClip(guide.overlaySize);

    expect(
      barrierPath.contains(Offset(2, visualHole.top + 2)),
      isTrue,
      reason: 'The clipped hole should keep a visible rounded left corner.',
    );
    expect(
      barrierPath.contains(
        Offset(guide.overlaySize.width - 2, visualHole.top + 2),
      ),
      isTrue,
      reason: 'The clipped hole should keep a visible rounded right corner.',
    );
    expect(barrierPath.contains(visualHole.center), isFalse);
  });

  testWidgets('target decoration shape cuts the barrier hole', (tester) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        barrier: const SpotlightGuideBarrierStyle(
          color: Colors.black,
          blurSigma: 1,
        ),
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: ColoredBox(color: Colors.white)),
            Positioned(
              left: 100,
              top: 100,
              child: SpotlightGuideTarget(
                id: 'oval',
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'oval',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
                shape: SpotlightGuideOvalTargetShape(),
              ),
              hintBuilder: sizedHint('oval-hole', 1, 1, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    final SpotlightGuideStepContext guide = contexts['oval-hole']!;
    final ClipPath barrierClip = tester.widget<ClipPath>(
      find.byWidgetPredicate(
        (Widget widget) => widget is ClipPath && widget.child is BackdropFilter,
      ),
    );
    final CustomClipper<Path> barrierClipper = barrierClip.clipper!;
    final Path barrierPath = barrierClipper.getClip(guide.overlaySize);

    expect(barrierPath.contains(guide.targetRect.center), isFalse);
    expect(
      barrierPath.contains(guide.targetRect.topLeft + const Offset(2, 2)),
      isTrue,
      reason: 'An oval hole should keep the bounding rect corners dimmed.',
    );
  });

  testWidgets('target decoration layers receive the resolved target shape', (
    tester,
  ) async {
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};
    final List<SpotlightGuideTargetPaintContext> paintContexts =
        <SpotlightGuideTargetPaintContext>[];

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: ColoredBox(color: Colors.white)),
            Positioned(
              left: 100,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'decorated',
                child: SizedBox(
                  width: 80,
                  height: 44,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'decorated',
              targetDecoration: SpotlightGuideTargetDecoration(
                padding: const EdgeInsets.fromLTRB(3, 5, 7, 11),
                shape: const SpotlightGuideRoundedRectTargetShape(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                layers: <SpotlightGuideTargetLayer>[
                  _RecordingTargetLayer(paintContexts),
                ],
              ),
              hintBuilder: sizedHint('decorated-hole', 1, 1, contexts),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    await tester.pump();

    final SpotlightGuideStepContext guide = contexts['decorated-hole']!;
    expect(paintContexts, isNotEmpty);

    final SpotlightGuideTargetPaintContext paintContext = paintContexts.last;
    expect(paintContext.rect, guide.targetRect);
    expect(paintContext.path().contains(paintContext.rect.center), isTrue);
    expect(
      paintContext.path().contains(
        paintContext.rect.topLeft + const Offset(1, 1),
      ),
      isFalse,
      reason: 'Layer paths should follow the rounded target shape.',
    );
  });

  test('target glow layer is cleared away from the real target', () async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(100, 100);
    const SpotlightGuideTargetPaintContext context =
        SpotlightGuideTargetPaintContext(
          rect: Rect.fromLTWH(30, 30, 40, 40),
          overlaySize: size,
          textDirection: TextDirection.ltr,
          shape: SpotlightGuideRoundedRectTargetShape(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        );

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    const SpotlightGuideTargetGlowLayer(
      color: Color(0xFFFFFFFF),
      blurRadius: 0,
      spreadRadius: 6,
    ).paint(canvas, context);
    canvas.drawPath(
      context.path(),
      Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.clear,
    );
    canvas.restore();

    final ui.Image image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final ByteData data = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;

    expect(
      _pixelColor(data, size, 50, 50),
      const Color(0xFFFFFFFF),
      reason: 'The glow should not cover the transparent target hole.',
    );
    expect(
      _colorBrightness(_pixelColor(data, size, 27, 50)),
      greaterThan(80),
      reason: 'The glow should remain visible just outside the target shape.',
    );
  });

  test('target ring layers use outside-only overlay painting', () async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(100, 100);
    const SpotlightGuideTargetPaintContext context =
        SpotlightGuideTargetPaintContext(
          rect: Rect.fromLTWH(20.25, 20.25, 40, 40),
          overlaySize: size,
          textDirection: TextDirection.ltr,
          shape: SpotlightGuideRoundedRectTargetShape(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        );

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    canvas.drawPath(
      context.path(),
      Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.clear,
    );
    const SpotlightGuideTargetRingLayer(
      color: Color(0xFFFF0000),
      width: 16,
    ).paint(canvas, context);
    const SpotlightGuideTargetRingLayer(
      color: Color(0xFF00FF00),
      width: 8,
    ).paint(canvas, context);
    canvas.restore();

    final ui.Image image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final ByteData data = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;

    expect(
      _pixelColor(data, size, 40, 40),
      const Color(0xFFFFFFFF),
      reason:
          'The transparent target hole should not be filled by ring layers.',
    );

    for (final Offset sample in <Offset>[
      const Offset(20, 40),
      const Offset(40, 20),
      const Offset(68, 40),
      const Offset(40, 12),
      const Offset(12, 40),
      const Offset(40, 68),
    ]) {
      final Color color = _pixelColor(
        data,
        size,
        sample.dx.toInt(),
        sample.dy.toInt(),
      );
      expect(
        _colorBrightness(color),
        greaterThan(80),
        reason:
            'Layered rings should cover the dim barrier instead of exposing a '
            'black gap at $sample. Actual color: $color',
      );
    }
  });

  testWidgets('barrier absorbs taps on the target hole by default', (
    tester,
  ) async {
    int targetTaps = 0;

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'btn',
                child: SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey<String>('target-button'),
                    onPressed: () => targetTaps++,
                    child: const Text('press'),
                  ),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'btn',
              placement: SpotlightGuidePlacement.bottom,
              hintBuilder: hint('absorb-hole'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('absorb-hole')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('target-button')),
      warnIfMissed: false,
    );
    await pumpGuide(tester);

    expect(targetTaps, 0);
  });

  testWidgets('allowTargetInteraction lets taps reach the highlighted target', (
    tester,
  ) async {
    int targetTaps = 0;

    await tester.pumpWidget(
      guideApp(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 40,
              top: 40,
              child: SpotlightGuideTarget(
                id: 'btn',
                child: SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey<String>('target-button'),
                    onPressed: () => targetTaps++,
                    child: const Text('press'),
                  ),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'btn',
              placement: SpotlightGuidePlacement.bottom,
              allowTargetInteraction: true,
              hintBuilder: hint('passthrough-hole'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('passthrough-hole')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('target-button')));
    await pumpGuide(tester);

    expect(targetTaps, 1);
  });

  testWidgets(
    'allowTargetInteraction pass-through covers the target rect, not its padding',
    (tester) async {
      int targetTaps = 0;
      int barrierTaps = 0;

      await tester.pumpWidget(
        guideApp(
          onBarrierTap: (SpotlightGuidePortalController c) => barrierTaps++,
          child: Stack(
            children: <Widget>[
              Positioned(
                // Target rect: (40,40) - (160,88).
                left: 40,
                top: 40,
                child: SpotlightGuideTarget(
                  id: 'btn',
                  child: SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      key: const ValueKey<String>('target-button'),
                      onPressed: () => targetTaps++,
                      child: const Text('press'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'btn',
                placement: SpotlightGuidePlacement.bottom,
                // The dim hole is inflated by 12 around the target rect.
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.all(12),
                ),
                allowTargetInteraction: true,
                hintBuilder: hint('raw-rect-hole'),
              ),
            ),
          ],
        ),
      );
      await pumpGuide(tester);

      // A tap inside the padding band (x=33 is left of the target rect at x=40
      // but inside the inflated hole at x=28) is still absorbed by the barrier.
      await tester.tapAt(const Offset(33, 64));
      await pumpGuide(tester);
      expect(targetTaps, 0);
      expect(barrierTaps, 1);

      // A tap on the real target passes through to the widget.
      await tester.tap(find.byKey(const ValueKey<String>('target-button')));
      await pumpGuide(tester);
      expect(targetTaps, 1);
      expect(barrierTaps, 1);
    },
  );
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
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {
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

  final List<SpotlightGuideIndicatorDirection> directions;

  @override
  Size get preferredSize => const Size(16, 10);

  @override
  double get connectionHalfExtent => 6;

  @override
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {
    directions.add(builder.direction);
    builder.lineTo(path, 0, 1);
    builder.lineTo(path, builder.endSide, 0);
  }
}

class _RecordingTargetLayer extends SpotlightGuideTargetLayer {
  const _RecordingTargetLayer(this.contexts);

  final List<SpotlightGuideTargetPaintContext> contexts;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetPaintContext context) {
    contexts.add(context);
  }
}

Color _pixelColor(ByteData data, Size imageSize, int x, int y) {
  final int offset = ((y * imageSize.width.toInt()) + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

int _colorBrightness(Color color) {
  return _colorChannel(color.r) +
      _colorChannel(color.g) +
      _colorChannel(color.b);
}

int _colorChannel(double value) {
  return (value * 255.0).round().clamp(0, 255).toInt();
}
