import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Target decoration tests.
///
/// Run this file when changing [SpotlightGuideTargetDecoration],
/// [SpotlightGuideTargetShape], or target decoration layers such as rings,
/// glows, dashed outlines and shadows.
void main() {
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
                shape: SpotlightGuideOvalShape(),
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
    final List<SpotlightGuideTargetLayerContext> layerContexts =
        <SpotlightGuideTargetLayerContext>[];

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
                shape: const SpotlightGuideRoundedRectShape(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                layers: <SpotlightGuideTargetLayer>[
                  _RecordingTargetLayer(layerContexts),
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
    expect(layerContexts, isNotEmpty);

    final SpotlightGuideTargetLayerContext layerContext = layerContexts.last;
    expect(layerContext.rect, guide.targetRect);
    expect(layerContext.path().contains(layerContext.rect.center), isTrue);
    expect(
      layerContext.path().contains(
        layerContext.rect.topLeft + const Offset(1, 1),
      ),
      isFalse,
      reason: 'Layer paths should follow the rounded target shape.',
    );
  });

  test('target glow layer is cleared away from the real target', () async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(100, 100);
    const SpotlightGuideTargetLayerContext context =
        SpotlightGuideTargetLayerContext(
          rect: Rect.fromLTWH(30, 30, 40, 40),
          overlaySize: size,
          textDirection: TextDirection.ltr,
          shape: SpotlightGuideRoundedRectShape(
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
    const SpotlightGuideTargetLayerContext context =
        SpotlightGuideTargetLayerContext(
          rect: Rect.fromLTWH(20.25, 20.25, 40, 40),
          overlaySize: size,
          textDirection: TextDirection.ltr,
          shape: SpotlightGuideRoundedRectShape(
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

  test('target decoration layers sanitize unstable numeric values', () {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(120, 120);
    const SpotlightGuideTargetLayerContext context =
        SpotlightGuideTargetLayerContext(
          rect: Rect.fromLTWH(36, 36, 48, 40),
          overlaySize: size,
          textDirection: TextDirection.ltr,
          shape: SpotlightGuideRoundedRectShape(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        );

    expect(() {
      const SpotlightGuideTargetOutlineLayer(
        color: Colors.white,
        width: 1,
        dashLength: double.minPositive,
        gapLength: double.minPositive,
        phase: double.nan,
      ).paint(canvas, context);
      const SpotlightGuideTargetOutlineLayer(
        color: Colors.white,
        width: double.infinity,
        dashLength: double.infinity,
        gapLength: double.infinity,
        outset: double.infinity,
        phase: double.nan,
      ).paint(canvas, context);
      const SpotlightGuideTargetRingLayer(
        color: Colors.white,
        width: double.infinity,
        outset: double.infinity,
      ).paint(canvas, context);
      const SpotlightGuideTargetGlowLayer(
        color: Colors.white,
        blurRadius: double.infinity,
        spreadRadius: double.infinity,
      ).paint(canvas, context);
      const SpotlightGuideTargetShadowLayer(
        color: Colors.white,
        blurRadius: double.infinity,
        spreadRadius: double.infinity,
        offset: Offset(double.nan, double.infinity),
      ).paint(canvas, context);
    }, returnsNormally);

    recorder.endRecording().dispose();
  });
}

class _RecordingTargetLayer extends SpotlightGuideTargetLayer {
  const _RecordingTargetLayer(this.layerContexts);

  final List<SpotlightGuideTargetLayerContext> layerContexts;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context) {
    layerContexts.add(context);
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
