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
    // Default padding is 16 on each side. The upward triangle adds its 8px
    // height to the top only.
    expect(bubbleSize.width, moreOrLessEquals(100 + 16 + 16, epsilon: 0.5));
    expect(bubbleSize.height, moreOrLessEquals(40 + 16 + 16 + 8, epsilon: 0.5));
    expect(find.byKey(const ValueKey<String>('bubble-child')), findsOneWidget);
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
              targetPadding: EdgeInsets.zero,
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
                targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
                targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
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
                targetPadding: EdgeInsets.zero,
                hintBuilder: hint('dedup-a', contexts),
              ),
              SpotlightGuideStepItem(
                targetId: 'a',
                targetPadding: EdgeInsets.zero,
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
              targetPadding: EdgeInsets.zero,
              targetRadius: 0,
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
              targetPadding: const EdgeInsets.all(6),
              targetRadius: 16,
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
                targetPadding: const EdgeInsets.all(12),
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
