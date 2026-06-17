part of '../../spotlight_guide.dart';

/// Base class for hint decorations that can consume guide-resolved geometry.
@immutable
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
    SpotlightGuideBubbleAnchorGeometry geometry,
  );

  /// Border radius used to clip the content area, if the decoration needs it.
  BorderRadiusGeometry? get contentClipBorderRadius => null;
}

/// Decoration that paints a rounded bubble and anchor as one continuous shape.
///
/// When [anchor] is omitted, a [SpotlightGuideTriangleAnchor] is used. Pass
/// [SpotlightGuideNoAnchor] to hide the anchor while keeping the same bubble
/// container.
@immutable
class SpotlightGuideBubbleDecoration extends SpotlightGuideAnchoredDecoration {
  const SpotlightGuideBubbleDecoration({
    this.color = Colors.white,
    this.borderRadius = 6,
    this.anchor = const SpotlightGuideTriangleAnchor(),
    this.contentPadding = EdgeInsets.zero,
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
  final SpotlightGuideBubbleAnchorGeometry? anchorGeometry;

  SpotlightGuideBubbleAnchorGeometry? get effectiveAnchorGeometry {
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
  ///
  /// Defaults to zero so custom hint content can own its spacing explicitly.
  final EdgeInsetsGeometry contentPadding;

  /// Inward stroke painted around the whole bubble path.
  final BorderSide border;

  /// Optional shadows painted behind the bubble path.
  final List<BoxShadow>? boxShadow;

  double get _borderInset {
    final double borderWidth = _nonNegativeFiniteOrZero(border.width);
    if (border.style == BorderStyle.none || borderWidth <= 0) {
      return 0;
    }
    return borderWidth;
  }

  @override
  double get anchorSafeInset {
    return anchor.safeInset(
      borderRadius: _nonNegativeFiniteOrZero(borderRadius),
    );
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
    return BorderRadius.circular(
      math.max(0, _nonNegativeFiniteOrZero(borderRadius) - _borderInset),
    );
  }

  @override
  SpotlightGuideBubbleDecoration resolveAnchor(
    SpotlightGuideBubbleAnchorGeometry geometry,
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
@immutable
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
  final SpotlightGuideBubbleAnchorGeometry? anchorGeometry;

  @override
  final BorderRadiusGeometry? contentClipBorderRadius;

  @override
  EdgeInsetsGeometry get padding {
    return decoration.padding.add(anchor.padding(anchorGeometry));
  }

  @override
  SpotlightGuideProxyDecoration resolveAnchor(
    SpotlightGuideBubbleAnchorGeometry geometry,
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
