part of '../../spotlight_guide.dart';

/// Resolved geometry passed from guide layout to a visual anchor.
@immutable
class SpotlightGuideBubbleAnchorGeometry {
  const SpotlightGuideBubbleAnchorGeometry({
    required this.direction,
    required this.offset,
  });

  /// Direction in which the anchor points from the bubble toward the target.
  final SpotlightGuideDirection direction;

  /// Offset from the physical leading edge of the anchor side to the anchor tip
  /// center.
  final double offset;

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideBubbleAnchorGeometry &&
        other.direction == direction &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(direction, offset);
}

/// Base class for anchors attached to [SpotlightGuideBubbleDecoration].
///
/// Subclass this when the built-in triangle is not enough. The decoration
/// supplies [SpotlightGuideBubbleAnchorGeometry] after target layout resolves. Your
/// anchor can then contribute padding and append its outline to the bubble path.
@immutable
abstract class SpotlightGuideBubbleAnchor {
  const SpotlightGuideBubbleAnchor();

  /// Size used by layout and safe-area calculations before final offset exists.
  Size get preferredSize;

  /// Insets added to the child so content does not cover the anchor.
  EdgeInsetsGeometry padding(SpotlightGuideBubbleAnchorGeometry? geometry);

  /// Minimum side-axis inset needed before the body can safely contain this
  /// anchor near rounded corners.
  double safeInset({required double borderRadius}) {
    return math.max(
      0,
      _nonNegativeFiniteOrZero(borderRadius) +
          _nonNegativeFiniteOrZero(connectionHalfExtent),
    );
  }

  /// Half of the connection range touching the bubble side.
  ///
  /// This is deliberately separate from [preferredSize]. Irregular anchors can
  /// be visually wide while touching the bubble with a narrow base, or visually
  /// narrow while connecting with a broad curve.
  double get connectionHalfExtent => _finiteSizeOrZero(preferredSize).width / 2;

  /// Returns the side gap this anchor occupies on the bubble body.
  ///
  /// Returning null means no anchor is painted. When a gap is returned,
  /// [SpotlightGuideBubbleDecoration] skips that range on the body side before
  /// calling [addToPath], so the anchor and body share one continuous outline.
  SpotlightGuideBubbleAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  });

  /// Appends this anchor outline to [path].
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  });

  /// Creates a copy resolved with current guide geometry.
  SpotlightGuideBubbleAnchor resolve(
    SpotlightGuideBubbleAnchorGeometry geometry,
  );
}

/// Anchor that paints nothing.
@immutable
class SpotlightGuideNoAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuideNoAnchor();

  @override
  Size get preferredSize => Size.zero;

  @override
  EdgeInsetsGeometry padding(SpotlightGuideBubbleAnchorGeometry? geometry) {
    return EdgeInsets.zero;
  }

  @override
  SpotlightGuideBubbleAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {
    return null;
  }

  @override
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {}

  @override
  SpotlightGuideNoAnchor resolve(SpotlightGuideBubbleAnchorGeometry geometry) {
    return this;
  }

  @override
  bool operator ==(Object other) => other is SpotlightGuideNoAnchor;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Normalized coordinate helper for [SpotlightGuidePathAnchorShape].
///
/// The side axis is centered on the target connection. `outward == 0` is the
/// bubble body edge, while `outward == 1` is the outer tip edge. A shape may be
/// visually wider than the body connection; use [startSide] and [endSide] when
/// the outline must begin or end exactly at the body connection.
@immutable
class SpotlightGuideBubbleAnchorPathBuilder {
  const SpotlightGuideBubbleAnchorPathBuilder({
    required this.direction,
    required Offset Function(double side, double outward) pointBuilder,
    required this.startSide,
    required this.endSide,
  }) : _pointBuilder = pointBuilder;

  final Offset Function(double side, double outward) _pointBuilder;

  /// Physical side where the anchor is attached and points outward.
  ///
  /// Use this when a custom shape needs side-specific geometry beyond the
  /// normalized coordinate transform. For example, a custom arrow can switch
  /// control points when the bubble anchor is on the left or right side.
  final SpotlightGuideDirection direction;

  /// Normalized side value for the connection start on the bubble body edge.
  final double startSide;

  /// Normalized side value for the connection end on the bubble body edge.
  final double endSide;

  /// Resolves a normalized point into the current physical anchor direction.
  Offset point(double side, double outward) {
    return _pointBuilder(side, outward);
  }

  /// Adds a line to a normalized point.
  void lineTo(Path path, double side, double outward) {
    final Offset p = point(side, outward);
    path.lineTo(p.dx, p.dy);
  }

  /// Adds a cubic curve to normalized points.
  void cubicTo(
    Path path,
    double side1,
    double outward1,
    double side2,
    double outward2,
    double side3,
    double outward3,
  ) {
    final Offset p1 = point(side1, outward1);
    final Offset p2 = point(side2, outward2);
    final Offset p3 = point(side3, outward3);
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
  }
}

/// Shape specification for [SpotlightGuidePathAnchor].
///
/// This is useful when several custom arrows share the same anchor mechanics
/// but differ in path geometry. [connectionHalfExtent] controls how much of the
/// bubble edge is opened for the anchor, while [visualHalfExtent] controls the
/// side-axis range available to the drawn path. Keeping them separate lets a
/// shape have a narrow, pointed base with a wider visual arrow head.
@immutable
abstract class SpotlightGuidePathAnchorShape {
  const SpotlightGuidePathAnchorShape();

  /// Anchor footprint used by layout before the final offset is known.
  Size get preferredSize;

  /// Half of the range touching the bubble body.
  double get connectionHalfExtent;

  /// Half of the normalized visual side-axis range used by [addToPath].
  double get visualHalfExtent => connectionHalfExtent;

  /// Minimum side-axis inset needed to keep this shape clear of rounded corners.
  double safeInset({required double borderRadius}) {
    return math.max(0, borderRadius + visualHalfExtent);
  }

  /// Appends the normalized path outline.
  ///
  /// The current path position is already at the connection start. Implementers
  /// should finish at [SpotlightGuideBubbleAnchorPathBuilder.endSide] with
  /// `outward == 0`.
  void addToPath(Path path, SpotlightGuideBubbleAnchorPathBuilder builder);
}

/// Generic custom anchor driven by a reusable [SpotlightGuidePathAnchorShape].
@immutable
class SpotlightGuidePathAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuidePathAnchor({
    required this.shape,
    SpotlightGuideBubbleAnchorGeometry? geometry,
  }) : _geometry = geometry;

  /// Path, size and connection rules for this anchor.
  final SpotlightGuidePathAnchorShape shape;

  final SpotlightGuideBubbleAnchorGeometry? _geometry;

  /// Resolved geometry, when this anchor has already been laid out.
  SpotlightGuideBubbleAnchorGeometry? get geometry => _geometry;

  @override
  Size get preferredSize => _finiteSizeOrZero(shape.preferredSize);

  @override
  double get connectionHalfExtent {
    return _nonNegativeFiniteOrZero(shape.connectionHalfExtent);
  }

  @override
  double safeInset({required double borderRadius}) {
    return _nonNegativeFiniteOrZero(
      shape.safeInset(borderRadius: _nonNegativeFiniteOrZero(borderRadius)),
    );
  }

  @override
  EdgeInsetsGeometry padding(SpotlightGuideBubbleAnchorGeometry? geometry) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || preferredSize.isEmpty) {
      return EdgeInsets.zero;
    }
    final double inset = math.max(0, preferredSize.height);
    return switch (resolved.direction) {
      SpotlightGuideDirection.up => EdgeInsets.only(top: inset),
      SpotlightGuideDirection.down => EdgeInsets.only(bottom: inset),
      SpotlightGuideDirection.left => EdgeInsets.only(left: inset),
      SpotlightGuideDirection.right => EdgeInsets.only(right: inset),
    };
  }

  @override
  SpotlightGuideBubbleAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || preferredSize.isEmpty) {
      return null;
    }
    return switch (resolved.direction) {
      SpotlightGuideDirection.up || SpotlightGuideDirection.down =>
        SpotlightGuideBubbleAnchorConnection.horizontal(
          direction: resolved.direction,
          center: body.left + resolved.offset,
          halfWidth: connectionHalfExtent,
        ),
      SpotlightGuideDirection.left || SpotlightGuideDirection.right =>
        SpotlightGuideBubbleAnchorConnection.vertical(
          direction: resolved.direction,
          center: body.top + resolved.offset,
          halfWidth: connectionHalfExtent,
        ),
    };
  }

  @override
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    final SpotlightGuideBubbleAnchorConnection? connection = resolveConnection(
      body: body,
      paintOffset: paintOffset,
      paintSize: paintSize,
      geometry: geometry,
    );
    if (resolved == null || connection == null) {
      return;
    }

    final double visualHalfExtent = math.max(
      _nonNegativeFiniteOrZero(shape.visualHalfExtent),
      connectionHalfExtent,
    );
    final double startSide = -connectionHalfExtent / visualHalfExtent;
    final double endSide = connectionHalfExtent / visualHalfExtent;

    final SpotlightGuideBubbleAnchorPathBuilder builder = switch (resolved
        .direction) {
      SpotlightGuideDirection.up => SpotlightGuideBubbleAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          connection.center + visualHalfExtent * side,
          body.top - (body.top - paintOffset.dy) * outward,
        ),
      ),
      SpotlightGuideDirection.down => SpotlightGuideBubbleAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          connection.center - visualHalfExtent * side,
          body.bottom +
              (paintOffset.dy + paintSize.height - body.bottom) * outward,
        ),
      ),
      SpotlightGuideDirection.left => SpotlightGuideBubbleAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          body.left - (body.left - paintOffset.dx) * outward,
          connection.center - visualHalfExtent * side,
        ),
      ),
      SpotlightGuideDirection.right => SpotlightGuideBubbleAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          body.right +
              (paintOffset.dx + paintSize.width - body.right) * outward,
          connection.center + visualHalfExtent * side,
        ),
      ),
    };
    shape.addToPath(path, builder);
  }

  @override
  SpotlightGuidePathAnchor resolve(
    SpotlightGuideBubbleAnchorGeometry geometry,
  ) {
    return SpotlightGuidePathAnchor(shape: shape, geometry: geometry);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuidePathAnchor &&
        other.shape == shape &&
        other._geometry == _geometry;
  }

  @override
  int get hashCode => Object.hash(shape, _geometry);
}

/// Built-in triangular anchor.
@immutable
class SpotlightGuideTriangleAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuideTriangleAnchor({
    this.size = const Size(14, 8),
    this.tipArcAngle = 0,
    SpotlightGuideBubbleAnchorGeometry? geometry,
  }) : _geometry = geometry;

  /// Width is the triangle base width. Height is the distance from base to tip.
  final Size size;

  /// Radian angle used to round the triangle tip. Zero keeps a sharp point.
  ///
  /// The tip is rounded by cutting back along both triangle sides and connecting
  /// those tangent points with a conic arc. Values around `pi / 6` give a
  /// noticeable rounded tip without making the anchor look flat.
  final double tipArcAngle;

  final SpotlightGuideBubbleAnchorGeometry? _geometry;

  SpotlightGuideBubbleAnchorGeometry? get geometry => _geometry;

  @override
  Size get preferredSize => _finiteSizeOrZero(size);

  @override
  EdgeInsetsGeometry padding(SpotlightGuideBubbleAnchorGeometry? geometry) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    final Size safeSize = preferredSize;
    if (resolved == null || safeSize.isEmpty) {
      return EdgeInsets.zero;
    }
    final double inset = safeSize.height;
    return switch (resolved.direction) {
      SpotlightGuideDirection.up => EdgeInsets.only(top: inset),
      SpotlightGuideDirection.down => EdgeInsets.only(bottom: inset),
      SpotlightGuideDirection.left => EdgeInsets.only(left: inset),
      SpotlightGuideDirection.right => EdgeInsets.only(right: inset),
    };
  }

  @override
  double safeInset({required double borderRadius}) {
    return math.max(
      0,
      _nonNegativeFiniteOrZero(borderRadius) + connectionHalfExtent,
    );
  }

  @override
  double get connectionHalfExtent => preferredSize.width / 2;

  @override
  SpotlightGuideBubbleAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    final Size safeSize = preferredSize;
    if (resolved == null || safeSize.isEmpty) {
      return null;
    }
    final double halfWidth = safeSize.width / 2;
    switch (resolved.direction) {
      case SpotlightGuideDirection.up:
        final double center = body.left + resolved.offset;
        return SpotlightGuideBubbleAnchorConnection.horizontal(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideDirection.down:
        final double center = body.left + resolved.offset;
        return SpotlightGuideBubbleAnchorConnection.horizontal(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideDirection.left:
        final double center = body.top + resolved.offset;
        return SpotlightGuideBubbleAnchorConnection.vertical(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideDirection.right:
        final double center = body.top + resolved.offset;
        return SpotlightGuideBubbleAnchorConnection.vertical(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
    }
  }

  @override
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideBubbleAnchorGeometry? geometry,
  }) {
    final SpotlightGuideBubbleAnchorGeometry? resolved = geometry ?? _geometry;
    final SpotlightGuideBubbleAnchorConnection? gap = resolveConnection(
      body: body,
      paintOffset: paintOffset,
      paintSize: paintSize,
      geometry: geometry,
    );
    if (resolved == null || gap == null) {
      return;
    }
    final _SpotlightGuideAnchorTip tip;
    switch (resolved.direction) {
      case SpotlightGuideDirection.up:
        tip = _upDownTip(gap.center, paintOffset.dy, body.top);
        path
          ..lineTo(tip.left.dx, tip.left.dy)
          ..conicTo(
            tip.control.dx,
            tip.control.dy,
            tip.right.dx,
            tip.right.dy,
            tip.weight,
          )
          ..lineTo(gap.end, body.top);
      case SpotlightGuideDirection.down:
        tip = _upDownTip(
          gap.center,
          paintOffset.dy + paintSize.height,
          body.bottom,
        );
        path
          ..lineTo(tip.right.dx, tip.right.dy)
          ..conicTo(
            tip.control.dx,
            tip.control.dy,
            tip.left.dx,
            tip.left.dy,
            tip.weight,
          )
          ..lineTo(gap.start, body.bottom);
      case SpotlightGuideDirection.left:
        tip = _leftRightTip(paintOffset.dx, gap.center, body.left);
        path
          ..lineTo(tip.right.dx, tip.right.dy)
          ..conicTo(
            tip.control.dx,
            tip.control.dy,
            tip.left.dx,
            tip.left.dy,
            tip.weight,
          )
          ..lineTo(body.left, gap.start);
      case SpotlightGuideDirection.right:
        tip = _leftRightTip(
          paintOffset.dx + paintSize.width,
          gap.center,
          body.right,
        );
        path
          ..lineTo(tip.left.dx, tip.left.dy)
          ..conicTo(
            tip.control.dx,
            tip.control.dy,
            tip.right.dx,
            tip.right.dy,
            tip.weight,
          )
          ..lineTo(body.right, gap.end);
    }
  }

  @override
  SpotlightGuideTriangleAnchor resolve(
    SpotlightGuideBubbleAnchorGeometry geometry,
  ) {
    return SpotlightGuideTriangleAnchor(
      size: size,
      tipArcAngle: tipArcAngle,
      geometry: geometry,
    );
  }

  _SpotlightGuideAnchorTip _upDownTip(
    double centerX,
    double tipY,
    double baseY,
  ) {
    final double sign = tipY < baseY ? 1 : -1;
    final _SpotlightGuideRoundedTriangleTip roundedTip = _roundedTip;
    final double sideFraction = roundedTip.sideFraction;
    final Size safeSize = preferredSize;
    final double halfArc = (safeSize.width / 2) * sideFraction;
    final double inset = safeSize.height * sideFraction;
    return _SpotlightGuideAnchorTip(
      left: Offset(centerX - halfArc, tipY + inset * sign),
      control: Offset(centerX, tipY),
      right: Offset(centerX + halfArc, tipY + inset * sign),
      weight: roundedTip.conicWeight,
    );
  }

  _SpotlightGuideAnchorTip _leftRightTip(
    double tipX,
    double centerY,
    double baseX,
  ) {
    final double sign = tipX < baseX ? 1 : -1;
    final _SpotlightGuideRoundedTriangleTip roundedTip = _roundedTip;
    final double sideFraction = roundedTip.sideFraction;
    final Size safeSize = preferredSize;
    final double halfArc = (safeSize.width / 2) * sideFraction;
    final double inset = safeSize.height * sideFraction;
    return _SpotlightGuideAnchorTip(
      left: Offset(tipX + inset * sign, centerY - halfArc),
      control: Offset(tipX, centerY),
      right: Offset(tipX + inset * sign, centerY + halfArc),
      weight: roundedTip.conicWeight,
    );
  }

  _SpotlightGuideRoundedTriangleTip get _roundedTip {
    if (tipArcAngle <= 0) {
      return const _SpotlightGuideRoundedTriangleTip(
        sideFraction: 0,
        conicWeight: 1,
      );
    }
    final Size safeSize = preferredSize;
    final double halfWidth = safeSize.width / 2;
    final double height = safeSize.height;
    if (halfWidth <= 0 || height <= 0) {
      return const _SpotlightGuideRoundedTriangleTip(
        sideFraction: 0,
        conicWeight: 1,
      );
    }
    final double sideLength = math.sqrt(
      halfWidth * halfWidth + height * height,
    );
    final double maxCut = sideLength * 0.45;
    final double angle = _nonNegativeFiniteOrZero(
      tipArcAngle,
    ).clamp(0, math.pi / 2).toDouble();
    final double cut = math.min(maxCut, height * math.tan(angle / 2));
    final double apexAngle = 2 * math.atan2(halfWidth, height);
    final double conicWeight = math
        .sin(apexAngle / 2)
        .clamp(0.05, 1)
        .toDouble();
    return _SpotlightGuideRoundedTriangleTip(
      sideFraction: cut / sideLength,
      conicWeight: conicWeight,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideTriangleAnchor &&
        other.size == size &&
        other.tipArcAngle == tipArcAngle &&
        other._geometry == _geometry;
  }

  @override
  int get hashCode => Object.hash(size, tipArcAngle, _geometry);
}

/// Side segment opened on the bubble body for a visual anchor.
///
/// Custom anchors return this from
/// [SpotlightGuideBubbleAnchor.resolveConnection] so the bubble painter can
/// skip that side segment and let [SpotlightGuideBubbleAnchor.addToPath] draw a
/// continuous anchor outline in its place.
@immutable
class SpotlightGuideBubbleAnchorConnection {
  const SpotlightGuideBubbleAnchorConnection._({
    required this.direction,
    required this.center,
    required this.start,
    required this.end,
  });

  /// Creates a connection on a horizontal bubble side.
  factory SpotlightGuideBubbleAnchorConnection.horizontal({
    required SpotlightGuideDirection direction,
    required double center,
    required double halfWidth,
  }) {
    return SpotlightGuideBubbleAnchorConnection._(
      direction: direction,
      center: center,
      start: center - halfWidth,
      end: center + halfWidth,
    );
  }

  /// Creates a connection on a vertical bubble side.
  factory SpotlightGuideBubbleAnchorConnection.vertical({
    required SpotlightGuideDirection direction,
    required double center,
    required double halfWidth,
  }) {
    return SpotlightGuideBubbleAnchorConnection._(
      direction: direction,
      center: center,
      start: center - halfWidth,
      end: center + halfWidth,
    );
  }

  /// Physical side where the anchor is attached.
  final SpotlightGuideDirection direction;

  /// Center of the opened segment on the owning bubble side.
  final double center;

  /// Leading edge of the opened segment on the owning bubble side.
  final double start;

  /// Trailing edge of the opened segment on the owning bubble side.
  final double end;
}

class _SpotlightGuideAnchorTip {
  const _SpotlightGuideAnchorTip({
    required this.left,
    required this.control,
    required this.right,
    required this.weight,
  });

  final Offset left;
  final Offset control;
  final Offset right;
  final double weight;
}

class _SpotlightGuideRoundedTriangleTip {
  const _SpotlightGuideRoundedTriangleTip({
    required this.sideFraction,
    required this.conicWeight,
  });

  final double sideFraction;
  final double conicWeight;
}
