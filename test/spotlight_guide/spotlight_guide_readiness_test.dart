import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Paint-readiness tests for custom hints.
///
/// Run this file when changing overlay visibility, target-hole painting, or
/// custom hint support for async image/animation content.
void main() {
  testWidgets('paint gate keeps target pixels covered until ready', (
    tester,
  ) async {
    bool ready = false;
    final GlobalKey captureKey = GlobalKey();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    Widget buildApp() {
      return RepaintBoundary(
        key: captureKey,
        child: guideApp(
          barrier: const SpotlightGuideBarrierStyle(color: Color(0xFF000000)),
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
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['pixels'] = guide;
                      return SpotlightGuidePaintGate(
                        ready: ready,
                        child: const SizedBox(
                          key: ValueKey<String>('pixel-ready-hint'),
                          width: 180,
                          height: 72,
                          child: ColoredBox(color: Colors.white),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    final Offset targetCenter = contexts['pixels']!.targetRect.center;
    expect(
      _pixelAt(await _capturePixels(tester, captureKey), targetCenter),
      const Color(0xFF000000),
    );

    ready = true;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      _pixelAt(await _capturePixels(tester, captureKey), targetCenter),
      const Color(0xFFF44336),
    );
  });

  testWidgets('paint gate covers target again when readiness turns false', (
    tester,
  ) async {
    bool ready = true;
    final GlobalKey captureKey = GlobalKey();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    Widget buildApp() {
      return RepaintBoundary(
        key: captureKey,
        child: guideApp(
          barrier: const SpotlightGuideBarrierStyle(color: Color(0xFF000000)),
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
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['pixels'] = guide;
                      return SpotlightGuidePaintGate(
                        ready: ready,
                        child: const SizedBox(
                          key: ValueKey<String>('toggle-ready-hint'),
                          width: 180,
                          height: 72,
                          child: ColoredBox(color: Colors.white),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    final Offset targetCenter = contexts['pixels']!.targetRect.center;
    expect(
      _pixelAt(await _capturePixels(tester, captureKey), targetCenter),
      const Color(0xFFF44336),
    );

    ready = false;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      _pixelAt(await _capturePixels(tester, captureKey), targetCenter),
      const Color(0xFF000000),
    );
  });

  testWidgets('paint gate hides custom hint and target hole until ready', (
    tester,
  ) async {
    bool ready = false;
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
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['custom'] = guide;
                    return SpotlightGuidePaintGate(
                      ready: ready,
                      child: const SizedBox(
                        key: ValueKey<String>('custom-ready-hint'),
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
      find.byKey(const ValueKey<String>('custom-ready-hint')).hitTestable(),
      findsNothing,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['custom']!.overlaySize,
      ).contains(contexts['custom']!.targetRect.center),
      isTrue,
    );

    ready = true;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('custom-ready-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['custom']!.overlaySize,
      ).contains(contexts['custom']!.targetRect.center),
      isFalse,
    );
  });

  testWidgets(
    'target interaction waits until the ready target hole is visible',
    (tester) async {
      bool ready = false;
      int taps = 0;

      Widget buildApp() {
        return guideApp(
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 320,
                top: 120,
                child: SpotlightGuideTarget(
                  id: 'a',
                  child: GestureDetector(
                    onTap: () => taps += 1,
                    child: const SizedBox(
                      width: 100,
                      height: 60,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                allowTargetInteraction: true,
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      return SpotlightGuidePaintGate(
                        ready: ready,
                        child: const SizedBox(
                          key: ValueKey<String>('interactive-ready-hint'),
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
      await tester.tapAt(const Offset(370, 150));
      expect(taps, 0);

      ready = true;
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.tapAt(const Offset(370, 150));
      expect(taps, 1);
    },
  );

  testWidgets('paint gate can wait for a custom child natural size', (
    tester,
  ) async {
    bool loaded = false;
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
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['natural'] = guide;
                    return SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SpotlightGuidePaintGate(
                            requireNonEmptySize: true,
                            child: SizedBox(
                              key: const ValueKey<String>(
                                'custom-natural-child',
                              ),
                              width: 68,
                              height: loaded ? 102 : 0,
                              child: const ColoredBox(color: Colors.orange),
                            ),
                          ),
                          const SizedBox(
                            key: ValueKey<String>('custom-natural-hint'),
                            width: 220,
                            height: 64,
                            child: ColoredBox(color: Colors.white),
                          ),
                        ],
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
      find.byKey(const ValueKey<String>('custom-natural-hint')).hitTestable(),
      findsNothing,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['natural']!.overlaySize,
      ).contains(contexts['natural']!.targetRect.center),
      isTrue,
    );

    loaded = true;
    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('custom-natural-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('custom-natural-child')),
      ),
      const Size(68, 102),
    );
    expect(
      barrierClipPath(
        tester,
        contexts['natural']!.overlaySize,
      ).contains(contexts['natural']!.targetRect.center),
      isFalse,
    );
  });

  testWidgets('all same-step hints wait for every paint gate to be ready', (
    tester,
  ) async {
    bool firstReady = true;
    bool secondReady = false;
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    Widget buildApp() {
      return guideApp(
        barrier: const SpotlightGuideBarrierStyle(blurSigma: 1),
        child: Stack(
          children: const <Widget>[
            Positioned(
              left: 120,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'a',
                child: SizedBox(
                  width: 80,
                  height: 48,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
            Positioned(
              left: 520,
              top: 320,
              child: SpotlightGuideTarget(
                id: 'b',
                child: SizedBox(
                  width: 96,
                  height: 52,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                placement: SpotlightGuidePlacement.bottom,
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['first'] = guide;
                      return SpotlightGuidePaintGate(
                        ready: firstReady,
                        child: const SizedBox(
                          key: ValueKey<String>('first-ready-hint'),
                          width: 160,
                          height: 64,
                          child: ColoredBox(color: Colors.white),
                        ),
                      );
                    },
              ),
              SpotlightGuideStepItem(
                targetId: 'b',
                placement: SpotlightGuidePlacement.top,
                hintBuilder:
                    (BuildContext context, SpotlightGuideStepContext guide) {
                      contexts['second'] = guide;
                      return SpotlightGuidePaintGate(
                        ready: secondReady,
                        child: const SizedBox(
                          key: ValueKey<String>('second-ready-hint'),
                          width: 160,
                          height: 64,
                          child: ColoredBox(color: Colors.white),
                        ),
                      );
                    },
              ),
            ],
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp());
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('first-ready-hint')).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('second-ready-hint')).hitTestable(),
      findsNothing,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['first']!.overlaySize,
      ).contains(contexts['first']!.targetRect.center),
      isTrue,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['second']!.overlaySize,
      ).contains(contexts['second']!.targetRect.center),
      isTrue,
    );

    secondReady = true;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('first-ready-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('second-ready-hint')).hitTestable(),
      findsOneWidget,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['first']!.overlaySize,
      ).contains(contexts['first']!.targetRect.center),
      isFalse,
    );
    expect(
      barrierClipPath(
        tester,
        contexts['second']!.overlaySize,
      ).contains(contexts['second']!.targetRect.center),
      isFalse,
    );

    firstReady = false;
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('first-ready-hint')).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('second-ready-hint')).hitTestable(),
      findsNothing,
    );
  });
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

Color _pixelAt(_CapturedPixels pixels, Offset point) {
  return pixels.colorAt(
    point.dx.round().clamp(0, pixels.width - 1),
    point.dy.round().clamp(0, pixels.height - 1),
  );
}
