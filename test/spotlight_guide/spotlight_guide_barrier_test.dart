import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Barrier and spotlight-hole tests.
///
/// Run this file when changing [SpotlightGuideBarrierStyle], spotlight-hole
/// clipping/deduplication, or target pass-through hit testing.
void main() {
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
                shape: SpotlightGuideRoundedRectShape(
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
                shape: SpotlightGuideRoundedRectShape(
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

      await tester.tapAt(const Offset(33, 64));
      await pumpGuide(tester);
      expect(targetTaps, 0);
      expect(barrierTaps, 1);

      await tester.tap(find.byKey(const ValueKey<String>('target-button')));
      await pumpGuide(tester);
      expect(targetTaps, 1);
      expect(barrierTaps, 1);
    },
  );
}
