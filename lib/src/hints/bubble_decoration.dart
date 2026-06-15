part of '../../spotlight_guide.dart';

/// Resolved geometry passed from guide layout to a visual anchor.
class SpotlightGuideAnchorGeometry {
  const SpotlightGuideAnchorGeometry({
    required this.direction,
    required this.offset,
  });

  /// Direction in which the anchor points from the bubble toward the target.
  final SpotlightGuideIndicatorDirection direction;

  /// Offset from the physical leading edge of the anchor side to the anchor tip
  /// center.
  final double offset;

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideAnchorGeometry &&
        other.direction == direction &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(direction, offset);
}

/// Base class for anchors attached to [SpotlightGuideBubbleDecoration].
///
/// Subclass this when the built-in triangle is not enough. The decoration
/// supplies [SpotlightGuideAnchorGeometry] after target layout resolves. Your
/// anchor can then contribute padding and append its outline to the bubble path.
abstract class SpotlightGuideBubbleAnchor {
  const SpotlightGuideBubbleAnchor();

  /// Size used by layout and safe-area calculations before final offset exists.
  Size get preferredSize;

  /// Insets added to the child so content does not cover the anchor.
  EdgeInsetsGeometry padding(SpotlightGuideAnchorGeometry? geometry);

  /// Minimum side-axis inset needed before the body can safely contain this
  /// anchor near rounded corners.
  double safeInset({required double borderRadius}) {
    return math.max(0, borderRadius + connectionHalfExtent);
  }

  /// Half of the connection range touching the bubble side.
  ///
  /// This is deliberately separate from [preferredSize]. Irregular anchors can
  /// be visually wide while touching the bubble with a narrow base, or visually
  /// narrow while connecting with a broad curve.
  double get connectionHalfExtent => preferredSize.width / 2;

  /// Returns the side gap this anchor occupies on the bubble body.
  ///
  /// Returning null means no anchor is painted. When a gap is returned,
  /// [SpotlightGuideBubbleDecoration] skips that range on the body side before
  /// calling [addToPath], so the anchor and body share one continuous outline.
  SpotlightGuideAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  });

  /// Appends this anchor outline to [path].
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  });

  /// Creates a copy resolved with current guide geometry.
  SpotlightGuideBubbleAnchor resolve(SpotlightGuideAnchorGeometry geometry);
}

/// Anchor that paints nothing.
class SpotlightGuideNoAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuideNoAnchor();

  @override
  Size get preferredSize => Size.zero;

  @override
  EdgeInsetsGeometry padding(SpotlightGuideAnchorGeometry? geometry) {
    return EdgeInsets.zero;
  }

  @override
  SpotlightGuideAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    return null;
  }

  @override
  void addToPath({
    required Path path,
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {}

  @override
  SpotlightGuideNoAnchor resolve(SpotlightGuideAnchorGeometry geometry) {
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
class SpotlightGuideAnchorPathBuilder {
  SpotlightGuideAnchorPathBuilder({
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
  final SpotlightGuideIndicatorDirection direction;

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
  /// should finish at [SpotlightGuideAnchorPathBuilder.endSide] with
  /// `outward == 0`.
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder);
}

/// Generic custom anchor driven by a reusable [SpotlightGuidePathAnchorShape].
class SpotlightGuidePathAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuidePathAnchor({
    required this.shape,
    SpotlightGuideAnchorGeometry? geometry,
  }) : _geometry = geometry;

  /// Path, size and connection rules for this anchor.
  final SpotlightGuidePathAnchorShape shape;

  final SpotlightGuideAnchorGeometry? _geometry;

  /// Resolved geometry, when this anchor has already been laid out.
  SpotlightGuideAnchorGeometry? get geometry => _geometry;

  @override
  Size get preferredSize => shape.preferredSize;

  @override
  double get connectionHalfExtent => shape.connectionHalfExtent;

  @override
  double safeInset({required double borderRadius}) {
    return shape.safeInset(borderRadius: borderRadius);
  }

  @override
  EdgeInsetsGeometry padding(SpotlightGuideAnchorGeometry? geometry) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || preferredSize.isEmpty) {
      return EdgeInsets.zero;
    }
    final double inset = math.max(0, preferredSize.height);
    return switch (resolved.direction) {
      SpotlightGuideIndicatorDirection.up => EdgeInsets.only(top: inset),
      SpotlightGuideIndicatorDirection.down => EdgeInsets.only(bottom: inset),
      SpotlightGuideIndicatorDirection.left => EdgeInsets.only(left: inset),
      SpotlightGuideIndicatorDirection.right => EdgeInsets.only(right: inset),
    };
  }

  @override
  SpotlightGuideAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || preferredSize.isEmpty) {
      return null;
    }
    return switch (resolved.direction) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down =>
        SpotlightGuideAnchorConnection.horizontal(
          direction: resolved.direction,
          center: body.left + resolved.offset,
          halfWidth: connectionHalfExtent,
        ),
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right =>
        SpotlightGuideAnchorConnection.vertical(
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
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    final SpotlightGuideAnchorConnection? connection = resolveConnection(
      body: body,
      paintOffset: paintOffset,
      paintSize: paintSize,
      geometry: geometry,
    );
    if (resolved == null || connection == null) {
      return;
    }

    final double visualHalfExtent = math.max(
      shape.visualHalfExtent,
      connectionHalfExtent,
    );
    final double startSide = -connectionHalfExtent / visualHalfExtent;
    final double endSide = connectionHalfExtent / visualHalfExtent;

    final SpotlightGuideAnchorPathBuilder builder = switch (resolved
        .direction) {
      SpotlightGuideIndicatorDirection.up => SpotlightGuideAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          connection.center + visualHalfExtent * side,
          body.top - (body.top - paintOffset.dy) * outward,
        ),
      ),
      SpotlightGuideIndicatorDirection.down => SpotlightGuideAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          connection.center - visualHalfExtent * side,
          body.bottom +
              (paintOffset.dy + paintSize.height - body.bottom) * outward,
        ),
      ),
      SpotlightGuideIndicatorDirection.left => SpotlightGuideAnchorPathBuilder(
        direction: resolved.direction,
        startSide: startSide,
        endSide: endSide,
        pointBuilder: (double side, double outward) => Offset(
          body.left - (body.left - paintOffset.dx) * outward,
          connection.center - visualHalfExtent * side,
        ),
      ),
      SpotlightGuideIndicatorDirection.right => SpotlightGuideAnchorPathBuilder(
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
  SpotlightGuidePathAnchor resolve(SpotlightGuideAnchorGeometry geometry) {
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
class SpotlightGuideTriangleAnchor extends SpotlightGuideBubbleAnchor {
  const SpotlightGuideTriangleAnchor({
    this.size = const Size(14, 8),
    this.tipArcAngle = 0,
    SpotlightGuideAnchorGeometry? geometry,
  }) : _geometry = geometry;

  /// Width is the triangle base width. Height is the distance from base to tip.
  final Size size;

  /// Radian angle used to round the triangle tip. Zero keeps a sharp point.
  ///
  /// The tip is rounded by cutting back along both triangle sides and connecting
  /// those tangent points with a conic arc. Values around `pi / 6` give a
  /// noticeable rounded tip without making the anchor look flat.
  final double tipArcAngle;

  final SpotlightGuideAnchorGeometry? _geometry;

  SpotlightGuideAnchorGeometry? get geometry => _geometry;

  @override
  Size get preferredSize => size;

  @override
  EdgeInsetsGeometry padding(SpotlightGuideAnchorGeometry? geometry) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || size.isEmpty) {
      return EdgeInsets.zero;
    }
    final double inset = math.max(0, size.height);
    return switch (resolved.direction) {
      SpotlightGuideIndicatorDirection.up => EdgeInsets.only(top: inset),
      SpotlightGuideIndicatorDirection.down => EdgeInsets.only(bottom: inset),
      SpotlightGuideIndicatorDirection.left => EdgeInsets.only(left: inset),
      SpotlightGuideIndicatorDirection.right => EdgeInsets.only(right: inset),
    };
  }

  @override
  double safeInset({required double borderRadius}) {
    return math.max(0, borderRadius + connectionHalfExtent);
  }

  @override
  double get connectionHalfExtent => size.width / 2;

  @override
  SpotlightGuideAnchorConnection? resolveConnection({
    required Rect body,
    required Offset paintOffset,
    required Size paintSize,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    if (resolved == null || size.isEmpty) {
      return null;
    }
    final double halfWidth = size.width / 2;
    switch (resolved.direction) {
      case SpotlightGuideIndicatorDirection.up:
        final double center = body.left + resolved.offset;
        return SpotlightGuideAnchorConnection.horizontal(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideIndicatorDirection.down:
        final double center = body.left + resolved.offset;
        return SpotlightGuideAnchorConnection.horizontal(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideIndicatorDirection.left:
        final double center = body.top + resolved.offset;
        return SpotlightGuideAnchorConnection.vertical(
          direction: resolved.direction,
          center: center,
          halfWidth: halfWidth,
        );
      case SpotlightGuideIndicatorDirection.right:
        final double center = body.top + resolved.offset;
        return SpotlightGuideAnchorConnection.vertical(
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
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    final SpotlightGuideAnchorGeometry? resolved = geometry ?? _geometry;
    final SpotlightGuideAnchorConnection? gap = resolveConnection(
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
      case SpotlightGuideIndicatorDirection.up:
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
      case SpotlightGuideIndicatorDirection.down:
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
      case SpotlightGuideIndicatorDirection.left:
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
      case SpotlightGuideIndicatorDirection.right:
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
  SpotlightGuideTriangleAnchor resolve(SpotlightGuideAnchorGeometry geometry) {
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
    final double halfArc = (size.width / 2) * sideFraction;
    final double inset = size.height * sideFraction;
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
    final double halfArc = (size.width / 2) * sideFraction;
    final double inset = size.height * sideFraction;
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
    final double halfWidth = math.max(0, size.width / 2);
    final double height = math.max(0, size.height);
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
    final double angle = tipArcAngle.clamp(0, math.pi / 2).toDouble();
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

/// Base class for hint decorations that can consume guide-resolved geometry.
abstract class SpotlightGuideAnchoredDecoration extends Decoration {
  const SpotlightGuideAnchoredDecoration();

  SpotlightGuideBubbleAnchor get anchor;

  /// Anchor size used by layout before the final offset is known.
  Size get anchorSize => anchor.preferredSize;

  /// Half of the range where the anchor connects to the bubble side.
  double get anchorConnectionHalfExtent => anchor.connectionHalfExtent;

  /// Minimum side-axis inset needed to keep the visual anchor connected safely.
  double get anchorSafeInset => anchor.safeInset(borderRadius: 0);

  /// Returns a copy that uses current guide geometry.
  SpotlightGuideAnchoredDecoration resolveAnchor(
    SpotlightGuideAnchorGeometry geometry,
  );

  /// Border radius used to clip the content area, if the decoration needs it.
  BorderRadiusGeometry? get contentClipBorderRadius => null;
}

/// Decoration that paints a rounded bubble and anchor as one continuous shape.
///
/// When [anchor] is omitted, a [SpotlightGuideTriangleAnchor] is used. Pass
/// [SpotlightGuideNoAnchor] to hide the anchor while keeping the same bubble
/// container.
class SpotlightGuideBubbleDecoration extends SpotlightGuideAnchoredDecoration {
  const SpotlightGuideBubbleDecoration({
    this.color = Colors.white,
    this.borderRadius = 6,
    this.anchor = const SpotlightGuideTriangleAnchor(),
    this.contentPadding = const EdgeInsets.all(16),
    this.border = BorderSide.none,
    this.boxShadow,
    this.anchorGeometry,
  });

  /// Fill color for the bubble and anchor.
  final Color color;

  /// Corner radius of the bubble body.
  final double borderRadius;

  @override
  final SpotlightGuideBubbleAnchor anchor;

  /// Resolved target geometry for [anchor].
  final SpotlightGuideAnchorGeometry? anchorGeometry;

  SpotlightGuideAnchorGeometry? get effectiveAnchorGeometry {
    final SpotlightGuideBubbleAnchor current = anchor;
    if (anchorGeometry != null) {
      return anchorGeometry;
    }
    if (current is SpotlightGuideTriangleAnchor) {
      return current.geometry;
    }
    if (current is SpotlightGuidePathAnchor) {
      return current.geometry;
    }
    return null;
  }

  /// Padding around the content body before border and anchor insets are added.
  final EdgeInsetsGeometry contentPadding;

  /// Inward stroke painted around the whole bubble path.
  final BorderSide border;

  /// Optional shadows painted behind the bubble path.
  final List<BoxShadow>? boxShadow;

  double get _borderInset {
    if (border.style == BorderStyle.none || border.width <= 0) {
      return 0;
    }
    return border.width;
  }

  @override
  double get anchorSafeInset {
    return anchor.safeInset(borderRadius: math.max(0, borderRadius));
  }

  @override
  EdgeInsetsGeometry get padding {
    EdgeInsetsGeometry resolved = contentPadding;
    final double borderInset = _borderInset;
    if (borderInset > 0) {
      resolved = resolved.add(EdgeInsets.all(borderInset));
    }
    return resolved.add(anchor.padding(effectiveAnchorGeometry));
  }

  @override
  BorderRadiusGeometry get contentClipBorderRadius {
    return BorderRadius.circular(math.max(0, borderRadius - _borderInset));
  }

  @override
  SpotlightGuideBubbleDecoration resolveAnchor(
    SpotlightGuideAnchorGeometry geometry,
  ) {
    return SpotlightGuideBubbleDecoration(
      color: color,
      borderRadius: borderRadius,
      anchor: anchor.resolve(geometry),
      contentPadding: contentPadding,
      border: border,
      boxShadow: boxShadow,
      anchorGeometry: geometry,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _SpotlightGuideBubblePainter(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideBubbleDecoration &&
        other.color == color &&
        other.borderRadius == borderRadius &&
        other.anchor == anchor &&
        other.anchorGeometry == anchorGeometry &&
        other.contentPadding == contentPadding &&
        other.border == border &&
        other.boxShadow == boxShadow;
  }

  @override
  int get hashCode {
    return Object.hash(
      color,
      borderRadius,
      anchor,
      anchorGeometry,
      contentPadding,
      border,
      boxShadow,
    );
  }
}

/// Adapter that lets any Flutter [Decoration] participate in guide layout.
///
/// Use this when the hint body should be painted by a regular [BoxDecoration],
/// [ShapeDecoration], image decoration, or a project-specific decoration, while
/// still exposing guide anchor metadata. The delegated [decoration] paints the
/// background; [anchor] only contributes layout size, safe connection range and
/// padding. If the visual anchor must be connected to the background as one
/// outline, prefer [SpotlightGuideBubbleDecoration] or a custom
/// [SpotlightGuideAnchoredDecoration].
class SpotlightGuideProxyDecoration extends SpotlightGuideAnchoredDecoration {
  const SpotlightGuideProxyDecoration({
    required this.decoration,
    this.anchor = const SpotlightGuideNoAnchor(),
    this.anchorGeometry,
    this.contentClipBorderRadius,
  });

  /// Decoration delegated to Flutter's normal decoration painter.
  final Decoration decoration;

  @override
  final SpotlightGuideBubbleAnchor anchor;

  /// Resolved target geometry for [anchor].
  final SpotlightGuideAnchorGeometry? anchorGeometry;

  @override
  final BorderRadiusGeometry? contentClipBorderRadius;

  @override
  EdgeInsetsGeometry get padding {
    return decoration.padding.add(anchor.padding(anchorGeometry));
  }

  @override
  SpotlightGuideProxyDecoration resolveAnchor(
    SpotlightGuideAnchorGeometry geometry,
  ) {
    return SpotlightGuideProxyDecoration(
      decoration: decoration,
      anchor: anchor.resolve(geometry),
      anchorGeometry: geometry,
      contentClipBorderRadius: contentClipBorderRadius,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    if (onChanged == null) {
      return decoration.createBoxPainter();
    }
    return decoration.createBoxPainter(onChanged);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideProxyDecoration &&
        other.decoration == decoration &&
        other.anchor == anchor &&
        other.anchorGeometry == anchorGeometry &&
        other.contentClipBorderRadius == contentClipBorderRadius;
  }

  @override
  int get hashCode {
    return Object.hash(
      decoration,
      anchor,
      anchorGeometry,
      contentClipBorderRadius,
    );
  }
}

/// Side-axis range where a custom anchor touches the bubble body.
class SpotlightGuideAnchorConnection {
  const SpotlightGuideAnchorConnection._({
    required this.direction,
    required this.center,
    required this.start,
    required this.end,
  });

  factory SpotlightGuideAnchorConnection.horizontal({
    required SpotlightGuideIndicatorDirection direction,
    required double center,
    required double halfWidth,
  }) {
    return SpotlightGuideAnchorConnection._(
      direction: direction,
      center: center,
      start: center - halfWidth,
      end: center + halfWidth,
    );
  }

  factory SpotlightGuideAnchorConnection.vertical({
    required SpotlightGuideIndicatorDirection direction,
    required double center,
    required double halfWidth,
  }) {
    return SpotlightGuideAnchorConnection._(
      direction: direction,
      center: center,
      start: center - halfWidth,
      end: center + halfWidth,
    );
  }

  final SpotlightGuideIndicatorDirection direction;
  final double center;
  final double start;
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
