part of '../../spotlight_guide.dart';

/// Visual treatment for a spotlight target hole.
///
/// This decoration does not wrap or modify the real target widget. It controls
/// the overlay hole used by the dim barrier, plus optional paint layers such as
/// rings, glows, and shadows around that hole.
@immutable
class SpotlightGuideTargetDecoration {
  const SpotlightGuideTargetDecoration({
    this.padding = const EdgeInsets.all(6),
    this.shape = const SpotlightGuideRoundedRectShape(),
    this.layers = const <SpotlightGuideTargetLayer>[],
  });

  /// Space added around the resolved target before the spotlight hole is cut.
  ///
  /// Directional padding is resolved with the current [Directionality].
  final EdgeInsetsGeometry padding;

  /// Shape used to cut the dim barrier and draw target layers.
  final SpotlightGuideTargetShape shape;

  /// Extra visual layers painted around the spotlight hole.
  ///
  /// Layers are painted above the dim barrier and below hint bubbles. Custom
  /// layers are painted before the target hole is cleared, so the original
  /// target remains unobscured. Built-in ring layers are outside-only and are
  /// drawn after the hole is cleared to match Flutter's border-style stacking.
  final List<SpotlightGuideTargetLayer> layers;

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTargetDecoration &&
        other.padding == padding &&
        other.shape == shape &&
        listEquals(other.layers, layers);
  }

  @override
  int get hashCode => Object.hash(padding, shape, Object.hashAll(layers));
}

/// Shape used by [SpotlightGuideTargetDecoration] to cut a spotlight hole.
@immutable
abstract class SpotlightGuideTargetShape {
  const SpotlightGuideTargetShape();

  /// Builds this shape around [rect].
  ///
  /// [outset] expands the shape outward while preserving the shape's intent.
  /// Built-in target layers use it to draw rings, glows, and shadows.
  Path createPath({
    required Rect rect,
    required TextDirection textDirection,
    double outset = 0,
  });

  /// Paints an outside-only ring around this shape.
  ///
  /// The default implementation works for arbitrary paths. Built-in shapes
  /// override it to use the same double-rounded-rect primitive that Flutter's
  /// rounded [Border] painting uses.
  void paintRing({
    required Canvas canvas,
    required Rect rect,
    required TextDirection textDirection,
    required Paint paint,
    double outset = 0,
    required double width,
  }) {
    final double safeWidth = _nonNegativeFiniteOrZero(width);
    if (safeWidth <= 0) {
      return;
    }
    final double safeOutset = _nonNegativeFiniteOrZero(outset);
    final Path outerPath = createPath(
      rect: rect,
      textDirection: textDirection,
      outset: safeOutset + safeWidth,
    );
    final Path innerPath = createPath(
      rect: rect,
      textDirection: textDirection,
      outset: safeOutset,
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      paint,
    );
  }
}

/// Rounded rectangle spotlight target shape.
@immutable
class SpotlightGuideRoundedRectShape extends SpotlightGuideTargetShape {
  const SpotlightGuideRoundedRectShape({
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Corner radius of the spotlight hole.
  final BorderRadiusGeometry borderRadius;

  @override
  Path createPath({
    required Rect rect,
    required TextDirection textDirection,
    double outset = 0,
  }) {
    final BorderRadius radius = borderRadius.resolve(textDirection);
    return Path()..addRRect(
      _inflateRRect(radius.toRRect(rect), _nonNegativeFiniteOrZero(outset)),
    );
  }

  @override
  void paintRing({
    required Canvas canvas,
    required Rect rect,
    required TextDirection textDirection,
    required Paint paint,
    double outset = 0,
    required double width,
  }) {
    final double safeWidth = _nonNegativeFiniteOrZero(width);
    if (safeWidth <= 0) {
      return;
    }
    final double safeOutset = _nonNegativeFiniteOrZero(outset);
    final BorderRadius radius = borderRadius.resolve(textDirection);
    final RRect base = radius.toRRect(rect);
    canvas.drawDRRect(
      _inflateRRect(base, safeOutset + safeWidth),
      _inflateRRect(base, safeOutset),
      paint,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideRoundedRectShape &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => borderRadius.hashCode;
}

/// Oval spotlight target shape.
@immutable
class SpotlightGuideOvalShape extends SpotlightGuideTargetShape {
  const SpotlightGuideOvalShape();

  @override
  Path createPath({
    required Rect rect,
    required TextDirection textDirection,
    double outset = 0,
  }) {
    return Path()..addOval(rect.inflate(_nonNegativeFiniteOrZero(outset)));
  }

  @override
  void paintRing({
    required Canvas canvas,
    required Rect rect,
    required TextDirection textDirection,
    required Paint paint,
    double outset = 0,
    required double width,
  }) {
    final double safeWidth = _nonNegativeFiniteOrZero(width);
    if (safeWidth <= 0) {
      return;
    }
    RRect oval(double delta) {
      final Rect ovalRect = rect.inflate(_nonNegativeFiniteOrZero(delta));
      return RRect.fromRectXY(
        ovalRect,
        ovalRect.width / 2,
        ovalRect.height / 2,
      );
    }

    final double safeOutset = _nonNegativeFiniteOrZero(outset);
    canvas.drawDRRect(oval(safeOutset + safeWidth), oval(safeOutset), paint);
  }

  @override
  bool operator ==(Object other) => other is SpotlightGuideOvalShape;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Context passed to custom target decoration layers.
@immutable
class SpotlightGuideTargetLayerContext {
  const SpotlightGuideTargetLayerContext({
    required this.rect,
    required this.overlaySize,
    required this.textDirection,
    required this.shape,
    this.devicePixelRatio = 1,
  });

  /// Decorated target rect after [SpotlightGuideTargetDecoration.padding].
  final Rect rect;

  /// Full overlay size.
  final Size overlaySize;

  /// Text direction used to resolve directional shape and padding values.
  final TextDirection textDirection;

  /// Shape used by the target hole.
  final SpotlightGuideTargetShape shape;

  /// Device pixel ratio used to align built-in target paths to physical pixels.
  final double devicePixelRatio;

  /// Builds the target path, optionally expanded outward.
  Path path({double outset = 0}) {
    return shape.createPath(
      rect: _snapRectToPhysicalPixels(rect, devicePixelRatio),
      textDirection: textDirection,
      outset: _nonNegativeFiniteOrZero(outset),
    );
  }

  /// Paints an outside-only ring around the target shape.
  void paintRing(
    Canvas canvas,
    Paint paint, {
    double outset = 0,
    required double width,
  }) {
    shape.paintRing(
      canvas: canvas,
      rect: _snapRectToPhysicalPixels(rect, devicePixelRatio),
      textDirection: textDirection,
      paint: paint,
      outset: _nonNegativeFiniteOrZero(outset),
      width: _nonNegativeFiniteOrZero(width),
    );
  }
}

/// A custom visual layer painted around one spotlight target hole.
@immutable
abstract class SpotlightGuideTargetLayer {
  const SpotlightGuideTargetLayer();

  /// Paints this layer.
  ///
  /// Custom layers are painted before the overlay clears [context.path], so
  /// implementations can paint outward shapes without manually punching out the
  /// real target widget.
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context);
}

/// Draws an outside-only ring around the target hole.
@immutable
class SpotlightGuideTargetRingLayer extends SpotlightGuideTargetLayer {
  const SpotlightGuideTargetRingLayer({
    required this.color,
    this.width = 1,
    this.outset = 0,
  }) : assert(width >= 0, 'width must not be negative.'),
       assert(outset >= 0, 'outset must not be negative.');

  final Color color;
  final double width;

  /// Gap between the spotlight hole and the inner edge of this ring.
  final double outset;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context) {
    _paint(canvas, context, antiAlias: true);
  }

  void _paint(
    Canvas canvas,
    SpotlightGuideTargetLayerContext context, {
    required bool antiAlias,
  }) {
    final double safeWidth = _nonNegativeFiniteOrZero(width);
    if (safeWidth <= 0) {
      return;
    }
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = antiAlias;
    context.paintRing(
      canvas,
      paint,
      outset: _nonNegativeFiniteOrZero(outset),
      width: safeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTargetRingLayer &&
        other.color == color &&
        other.width == width &&
        other.outset == outset;
  }

  @override
  int get hashCode => Object.hash(color, width, outset);
}

/// Draws a dashed outline that follows the target shape.
@immutable
class SpotlightGuideTargetOutlineLayer extends SpotlightGuideTargetLayer {
  const SpotlightGuideTargetOutlineLayer({
    required this.color,
    this.width = 2,
    this.dashLength = 10,
    this.gapLength = 6,
    this.outset = 6,
    this.phase = 0,
    this.strokeCap = StrokeCap.round,
  }) : assert(width >= 0, 'width must not be negative.'),
       assert(dashLength > 0, 'dashLength must be greater than zero.'),
       assert(gapLength >= 0, 'gapLength must not be negative.'),
       assert(outset >= 0, 'outset must not be negative.');

  final Color color;
  final double width;
  final double dashLength;
  final double gapLength;

  /// Distance from the spotlight hole to the dashed outline path.
  final double outset;

  /// Shifts the start of the dash pattern along the path.
  final double phase;

  final StrokeCap strokeCap;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context) {
    final double safeWidth = _nonNegativeFiniteOrZero(width);
    if (safeWidth <= 0) {
      return;
    }
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = safeWidth
      ..strokeCap = strokeCap
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    _drawDashedPath(
      canvas,
      context.path(outset: _nonNegativeFiniteOrZero(outset)),
      paint,
      dashLength: _nonNegativeFiniteOrZero(dashLength),
      gapLength: _nonNegativeFiniteOrZero(gapLength),
      phase: _finiteOrZero(phase),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTargetOutlineLayer &&
        other.color == color &&
        other.width == width &&
        other.dashLength == dashLength &&
        other.gapLength == gapLength &&
        other.outset == outset &&
        other.phase == phase &&
        other.strokeCap == strokeCap;
  }

  @override
  int get hashCode => Object.hash(
    color,
    width,
    dashLength,
    gapLength,
    outset,
    phase,
    strokeCap,
  );
}

/// Draws a soft glow around the target hole.
///
/// The layer is painted on the overlay and the actual target hole is cleared
/// afterwards, so the glow can spread inward naturally without covering the
/// real target widget.
@immutable
class SpotlightGuideTargetGlowLayer extends SpotlightGuideTargetLayer {
  const SpotlightGuideTargetGlowLayer({
    required this.color,
    this.blurRadius = 18,
    this.spreadRadius = 0,
    this.blurStyle = ui.BlurStyle.normal,
  }) : assert(blurRadius >= 0, 'blurRadius must not be negative.'),
       assert(spreadRadius >= 0, 'spreadRadius must not be negative.');

  final Color color;
  final double blurRadius;
  final double spreadRadius;

  /// Blur style used for the glow.
  ///
  /// The default [ui.BlurStyle.normal] lets the blur feather naturally around
  /// the target. A positive [spreadRadius] expands the source shape before it
  /// is blurred; large spread values intentionally create a stronger
  /// border-like core.
  final ui.BlurStyle blurStyle;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context) {
    final Path path = context.path(
      outset: _nonNegativeFiniteOrZero(spreadRadius),
    );
    final Paint paint = BoxShadow(
      color: color,
      blurRadius: _nonNegativeFiniteOrZero(blurRadius),
      blurStyle: blurStyle,
    ).toPaint();
    canvas.drawPath(path, paint);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTargetGlowLayer &&
        other.color == color &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius &&
        other.blurStyle == blurStyle;
  }

  @override
  int get hashCode => Object.hash(color, blurRadius, spreadRadius, blurStyle);
}

/// Draws an offset shadow around the target hole.
@immutable
class SpotlightGuideTargetShadowLayer extends SpotlightGuideTargetLayer {
  const SpotlightGuideTargetShadowLayer({
    required this.color,
    this.blurRadius = 12,
    this.spreadRadius = 0,
    this.offset = Offset.zero,
    this.blurStyle = ui.BlurStyle.normal,
  }) : assert(blurRadius >= 0, 'blurRadius must not be negative.'),
       assert(spreadRadius >= 0, 'spreadRadius must not be negative.');

  final Color color;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;
  final ui.BlurStyle blurStyle;

  @override
  void paint(Canvas canvas, SpotlightGuideTargetLayerContext context) {
    final Path path = context
        .path(outset: _nonNegativeFiniteOrZero(spreadRadius))
        .shift(_finiteOffsetOrZero(offset));
    final Paint paint = BoxShadow(
      color: color,
      blurRadius: _nonNegativeFiniteOrZero(blurRadius),
      blurStyle: blurStyle,
    ).toPaint();
    canvas.drawPath(path, paint);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTargetShadowLayer &&
        other.color == color &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius &&
        other.offset == offset &&
        other.blurStyle == blurStyle;
  }

  @override
  int get hashCode =>
      Object.hash(color, blurRadius, spreadRadius, offset, blurStyle);
}

void _drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dashLength,
  required double gapLength,
  required double phase,
}) {
  if (dashLength <= 0) {
    canvas.drawPath(path, paint);
    return;
  }
  final double interval = dashLength + gapLength;
  if (!interval.isFinite || interval <= precisionErrorTolerance) {
    canvas.drawPath(path, paint);
    return;
  }
  if (gapLength <= precisionErrorTolerance) {
    canvas.drawPath(path, paint);
    return;
  }

  for (final ui.PathMetric metric in path.computeMetrics()) {
    if (!metric.length.isFinite || metric.length <= 0) {
      continue;
    }
    if (metric.length / interval > 10000) {
      canvas.drawPath(metric.extractPath(0, metric.length), paint);
      continue;
    }
    double distance = -_positiveModulo(phase, interval);
    while (distance < metric.length) {
      final double start = math.max(0, distance);
      final double end = math.min(metric.length, distance + dashLength);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
      distance += interval;
    }
  }
}

double _positiveModulo(double value, double modulus) {
  if (!value.isFinite || !modulus.isFinite || modulus <= 0) {
    return 0;
  }
  return ((value % modulus) + modulus) % modulus;
}

Rect _snapRectToPhysicalPixels(Rect rect, double devicePixelRatio) {
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
    return rect;
  }
  double snap(double value) {
    return (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
  }

  return Rect.fromLTRB(
    snap(rect.left),
    snap(rect.top),
    snap(rect.right),
    snap(rect.bottom),
  );
}

RRect _inflateRRect(RRect rrect, double delta) {
  if (delta == 0) {
    return rrect;
  }
  return RRect.fromRectAndCorners(
    rrect.outerRect.inflate(delta),
    topLeft: _inflateRadius(rrect.tlRadius, delta),
    topRight: _inflateRadius(rrect.trRadius, delta),
    bottomRight: _inflateRadius(rrect.brRadius, delta),
    bottomLeft: _inflateRadius(rrect.blRadius, delta),
  );
}

Radius _inflateRadius(Radius radius, double delta) {
  return Radius.elliptical(radius.x + delta, radius.y + delta);
}

double _finiteOrZero(double value) {
  return value.isFinite ? value : 0;
}

double _nonNegativeFiniteOrZero(double value) {
  return value.isFinite && value > 0 ? value : 0;
}

Offset _finiteOffsetOrZero(Offset value) {
  return Offset(_finiteOrZero(value.dx), _finiteOrZero(value.dy));
}

Size _finiteSizeOrZero(Size value) {
  return Size(
    _nonNegativeFiniteOrZero(value.width),
    _nonNegativeFiniteOrZero(value.height),
  );
}
