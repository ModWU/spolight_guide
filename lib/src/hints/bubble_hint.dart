part of '../../spotlight_guide.dart';

/// Paint order used for [SpotlightGuideBubbleHint.pointer].
enum SpotlightGuidePointerLayer {
  /// Paint the pointer below the bubble so pointer lines do not cover content.
  belowBubble,

  /// Paint the pointer above the bubble.
  aboveBubble,
}

/// Builds a pointer child with resolved placement information.
///
/// [child] is the original [SpotlightGuideHintPointer.child]. Return it
/// unchanged for the default appearance, or wrap it with transforms, animation,
/// direction-specific assets, or extra connector UI.
typedef SpotlightGuideHintPointerBuilder =
    Widget Function(
      BuildContext context,
      SpotlightGuidePointerContext pointer,
      Widget child,
    );

/// Natural direction of an unrotated pointer asset.
///
/// The default unrotated pose is up. The built-in values use the same
/// screen-space angle convention as [Transform.rotate]: positive radians rotate
/// clockwise. Each constructor accepts an extra clockwise offset so diagonal or
/// hand-drawn assets can describe their exact source pose, for example
/// `SpotlightGuidePointerDirection.upRight(math.pi / 8)`.
@immutable
class SpotlightGuidePointerDirection {
  /// A pointer direction from a clockwise angle in radians relative to up.
  const SpotlightGuidePointerDirection.radians(this.radians);

  /// A pointer direction from a clockwise angle in degrees relative to up.
  const SpotlightGuidePointerDirection.degrees(double degrees)
    : radians = degrees * math.pi / 180;

  /// Up, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.up([double clockwiseOffset = 0])
    : radians = clockwiseOffset;

  /// Up-right, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.upRight([double clockwiseOffset = 0])
    : radians = math.pi / 4 + clockwiseOffset;

  /// Right, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.right([double clockwiseOffset = 0])
    : radians = math.pi / 2 + clockwiseOffset;

  /// Down-right, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.downRight([double clockwiseOffset = 0])
    : radians = math.pi * 3 / 4 + clockwiseOffset;

  /// Down, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.down([double clockwiseOffset = 0])
    : radians = math.pi + clockwiseOffset;

  /// Down-left, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.downLeft([double clockwiseOffset = 0])
    : radians = -math.pi * 3 / 4 + clockwiseOffset;

  /// Left, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.left([double clockwiseOffset = 0])
    : radians = -math.pi / 2 + clockwiseOffset;

  /// Up-left, plus an optional clockwise offset.
  const SpotlightGuidePointerDirection.upLeft([double clockwiseOffset = 0])
    : radians = -math.pi / 4 + clockwiseOffset;

  /// Clockwise angle in radians, where `0` means up.
  final double radians;

  static SpotlightGuidePointerDirection _fromIndicator(
    SpotlightGuideIndicatorDirection direction,
  ) {
    return switch (direction) {
      SpotlightGuideIndicatorDirection.up =>
        const SpotlightGuidePointerDirection.up(),
      SpotlightGuideIndicatorDirection.right =>
        const SpotlightGuidePointerDirection.right(),
      SpotlightGuideIndicatorDirection.down =>
        const SpotlightGuidePointerDirection.down(),
      SpotlightGuideIndicatorDirection.left =>
        const SpotlightGuidePointerDirection.left(),
    };
  }
}

/// How a pointer participates in bubble-anchor layout.
enum SpotlightGuidePointerAnchorMode {
  /// The default target -> pointer -> bubble chain.
  ///
  /// The pointer sits between the target and the bubble. The pointer's target
  /// anchor aligns to the target, while the bubble anchor aligns to the
  /// pointer's center.
  pointer,

  /// Keep the bubble anchor directly connected to the target.
  ///
  /// The pointer is still painted and aligned on the anchor axis, but it does
  /// not move the bubble body away from the target. Use this for decorative
  /// pointers that should not become part of the visual anchor chain.
  target,
}

/// Where the bubble body sits relative to [SpotlightGuideBubbleHint.pointer].
///
/// This does not choose where the pointer sits around the target. That remains
/// the job of [SpotlightGuideStepItem.placement]. This enum only chooses the
/// second segment of the chain: pointer -> bubble.
enum SpotlightGuidePointerBubblePlacement {
  /// Keep the previous target -> pointer -> bubble line.
  ///
  /// The bubble is placed farther away from the target in the resolved
  /// [SpotlightGuideStepItem.placement] direction.
  alongPlacement,

  /// Place the bubble above the pointer.
  top,

  /// Place the bubble below the pointer.
  bottom,

  /// Place the bubble on the physical left side of the pointer.
  left,

  /// Place the bubble on the physical right side of the pointer.
  right,

  /// Place the bubble on the semantic start side of the pointer.
  start,

  /// Place the bubble on the semantic end side of the pointer.
  end,
}

/// Resolved information available while building a pointer widget.
///
/// Use [targetDirection] to orient arrows, hands, and other directional
/// artwork toward the highlighted target after auto placement, semantic
/// start/end placement, and RTL resolution have already run.
class SpotlightGuidePointerContext {
  const SpotlightGuidePointerContext({
    required this.guide,
    required this.textDirection,
    required this.targetDirection,
    required this.bubbleDirection,
    required this.bubbleAnchorDirection,
    required this.bubblePlacement,
    required this.anchorMode,
  });

  /// Resolved guide data for the active hint item.
  final SpotlightGuideStepContext guide;

  /// Ambient text direction used to resolve semantic pointer options.
  final TextDirection textDirection;

  /// Direction from the pointer toward the target.
  ///
  /// A pointer whose natural artwork points up can use [targetRotation] to
  /// point at the highlighted target.
  final SpotlightGuideIndicatorDirection targetDirection;

  /// Direction from the pointer toward the bubble body.
  final SpotlightGuideIndicatorDirection bubbleDirection;

  /// Direction used by the bubble anchor that connects back to the pointer.
  final SpotlightGuideIndicatorDirection bubbleAnchorDirection;

  /// Resolved physical bubble side relative to the pointer.
  final SpotlightGuidePointerBubblePlacement bubblePlacement;

  /// Effective anchor mode for this pointer.
  final SpotlightGuidePointerAnchorMode anchorMode;

  /// Resolved physical placement for the hint.
  SpotlightGuidePlacement get placement => guide.placement;

  /// Radians that rotate artwork whose natural direction points up so it
  /// points toward [targetDirection].
  ///
  /// This is a shorthand for `rotationToTarget()`. Use [rotationToTarget] when
  /// a pointer asset naturally points in another direction or at a custom
  /// angle.
  double get targetRotation => rotationToTarget();

  /// Radians that rotate artwork whose natural direction points up so it
  /// points toward [bubbleDirection].
  ///
  /// This is a shorthand for `rotationToBubble()`. Use [rotationToBubble] when
  /// a pointer asset naturally points in another direction or at a custom
  /// angle.
  double get bubbleRotation => rotationToBubble();

  /// Radians that rotate pointer artwork so its natural direction points toward
  /// [targetDirection].
  ///
  /// [from] describes the unrotated artwork's source pose. For example, use
  /// `SpotlightGuidePointerDirection.upRight()` for northeast-facing artwork,
  /// or `SpotlightGuidePointerDirection.left(math.pi / 4)` for a left-facing
  /// asset whose artwork is drawn 45 degrees clockwise from the left axis.
  double rotationToTarget({
    SpotlightGuidePointerDirection from =
        const SpotlightGuidePointerDirection.up(),
  }) {
    return rotationToward(
      SpotlightGuidePointerDirection._fromIndicator(targetDirection),
      from: from,
    );
  }

  /// Radians that rotate pointer artwork so its natural direction points toward
  /// [bubbleDirection].
  ///
  /// This is useful for connector art that should face the bubble body instead
  /// of the highlighted target.
  double rotationToBubble({
    SpotlightGuidePointerDirection from =
        const SpotlightGuidePointerDirection.up(),
  }) {
    return rotationToward(
      SpotlightGuidePointerDirection._fromIndicator(bubbleDirection),
      from: from,
    );
  }

  /// Radians that rotate pointer artwork from its natural direction to any
  /// pointer [direction].
  double rotationToward(
    SpotlightGuidePointerDirection direction, {
    SpotlightGuidePointerDirection from =
        const SpotlightGuidePointerDirection.up(),
  }) {
    return _normalizeRotation(direction.radians - from.radians);
  }

  static double _normalizeRotation(double radians) {
    if (!radians.isFinite) {
      return radians;
    }
    final double fullTurn = math.pi * 2;
    double normalized = radians % fullTurn;
    if (normalized > math.pi) {
      normalized -= fullTurn;
    } else if (normalized <= -math.pi) {
      normalized += fullTurn;
    }
    return normalized;
  }
}

/// Visual-only offset applied to [SpotlightGuideHintPointer.child].
///
/// This offset moves the pointer widget's painted content without changing the
/// target -> pointer -> bubble layout chain. Use it as a last-mile adjustment
/// when a custom pointer asset has a visual tip that does not sit exactly on
/// the widget bounds.
class SpotlightGuidePointerOffset {
  const SpotlightGuidePointerOffset._({
    required double physicalDx,
    required double directionalDx,
    required this.dy,
  }) : _physicalDx = physicalDx,
       _directionalDx = directionalDx;

  /// No visual offset.
  static const SpotlightGuidePointerOffset zero = SpotlightGuidePointerOffset._(
    physicalDx: 0,
    directionalDx: 0,
    dy: 0,
  );

  /// Physical screen offset.
  ///
  /// Positive [right] moves the visual pointer right, positive [left] moves it
  /// left, positive [down] moves it down, and positive [up] moves it up. This
  /// constructor is not mirrored in RTL.
  const SpotlightGuidePointerOffset.physical({
    double left = 0,
    double right = 0,
    double up = 0,
    double down = 0,
  }) : this._(physicalDx: right - left, directionalDx: 0, dy: down - up);

  /// Direction-aware horizontal offset.
  ///
  /// Positive [start] moves toward the semantic start side and positive [end]
  /// moves toward the semantic end side. In RTL, start is right and end is
  /// left. Vertical [up] and [down] are physical.
  const SpotlightGuidePointerOffset.directional({
    double start = 0,
    double end = 0,
    double up = 0,
    double down = 0,
  }) : this._(physicalDx: 0, directionalDx: end - start, dy: down - up);

  final double _physicalDx;
  final double _directionalDx;

  /// Physical vertical offset. Positive values move down.
  final double dy;

  Offset resolve(TextDirection textDirection) {
    final double resolvedDirectionalDx = switch (textDirection) {
      TextDirection.ltr => _directionalDx,
      TextDirection.rtl => -_directionalDx,
    };
    return Offset(_physicalDx + resolvedDirectionalDx, dy);
  }
}

/// Configuration for a visual pointer attached to a guide hint.
///
/// Pointer layout has three independent relationships:
///
/// - [SpotlightGuideStepItem.placement] chooses where the pointer/hint sits
///   relative to the target.
/// - [pointerAnchorPosition] chooses which point inside [child] aligns to the
///   target anchor.
/// - [SpotlightGuideStepItem.targetAnchorPosition] chooses which point inside
///   [child] the bubble anchor aligns to while the pointer participates in the
///   default anchor chain.
/// - [targetGap] controls the signed main-axis distance from the target edge to
///   the pointer.
/// - [bubblePlacement] chooses where the bubble sits relative to the pointer.
///
/// When [anchorMode] is [SpotlightGuidePointerAnchorMode.pointer], the pointer
/// touches the target side chosen by [SpotlightGuideStepItem.placement], and
/// [SpotlightGuideStepContext.gap] controls the distance from the pointer to
/// the bubble anchor tip. [targetGap] can move the pointer away from or toward
/// the target before that pointer-to-bubble segment is laid out. If the bubble
/// decoration uses an anchor that paints nothing, the bubble edge is treated as
/// that tip.
///
/// If a custom pointer image has transparent padding or a painted tip that is
/// not on the widget edge, wrap or size that pointer widget so its layout edge
/// represents the desired visual contact point.
class SpotlightGuideHintPointer {
  const SpotlightGuideHintPointer({
    required this.child,
    this.builder,
    this.size,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.targetGap = 0,
    this.layer = SpotlightGuidePointerLayer.belowBubble,
    this.anchorMode = SpotlightGuidePointerAnchorMode.pointer,
    this.bubblePlacement = SpotlightGuidePointerBubblePlacement.alongPlacement,
    this.bubbleOffset,
    this.visualOffset = SpotlightGuidePointerOffset.zero,
  });

  /// Convenience configuration using the built-in [SpotlightGuideTapPointer].
  const SpotlightGuideHintPointer.tap({
    this.builder,
    this.size = SpotlightGuideTapPointer.defaultSize,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.targetGap = 0,
    this.layer = SpotlightGuidePointerLayer.belowBubble,
    this.anchorMode = SpotlightGuidePointerAnchorMode.pointer,
    this.bubblePlacement = SpotlightGuidePointerBubblePlacement.alongPlacement,
    this.bubbleOffset,
    this.visualOffset = SpotlightGuidePointerOffset.zero,
  }) : child = const SpotlightGuideTapPointer();

  /// Pointer widget, such as [SpotlightGuideTapPointer], an image, or animation.
  final Widget child;

  /// Optional builder that can wrap [child] with resolved pointer information.
  ///
  /// This is useful for directional artwork. For example, a pointer asset whose
  /// default pose points up can be wrapped in `Transform.rotate` with
  /// [SpotlightGuidePointerContext.targetRotation], while other source poses
  /// can call `pointer.rotationToTarget(from: ...)`.
  final SpotlightGuideHintPointerBuilder? builder;

  /// Optional size reserved for [child] in the guide layout.
  ///
  /// When null, the pointer child is laid out with loose constraints and its
  /// own size is used. Provide a size when a pointer asset should reserve a
  /// stable visual slot regardless of the child's intrinsic dimensions.
  final Size? size;

  /// Anchor inside [child] that aligns with the resolved target anchor.
  ///
  /// For top/bottom placements this resolves on the pointer's horizontal axis.
  /// For left/right placements this resolves on the pointer's vertical axis.
  final SpotlightGuideAnchorPosition pointerAnchorPosition;

  /// Signed main-axis distance from the target edge to the pointer.
  ///
  /// Positive values move the pointer away from the target in the resolved
  /// placement direction: down for bottom hints, up for top hints, left for
  /// left hints, and right for right hints. Negative values move the pointer
  /// back toward or across the target. This only affects the target -> pointer
  /// segment; [SpotlightGuideStepItem.gap] still controls the pointer -> bubble
  /// anchor segment.
  final double targetGap;

  /// Whether [child] paints above or below the bubble.
  final SpotlightGuidePointerLayer layer;

  /// Whether [child] participates in the bubble-anchor chain.
  final SpotlightGuidePointerAnchorMode anchorMode;

  /// Side where the bubble is placed relative to [child].
  ///
  /// Defaults to [SpotlightGuidePointerBubblePlacement.alongPlacement], which
  /// keeps the target, pointer and bubble on the same main axis. Use
  /// [SpotlightGuidePointerBubblePlacement.bottom] for common "pointer points
  /// sideways, explanation appears below it" compositions.
  final SpotlightGuidePointerBubblePlacement bubblePlacement;

  /// Optional distance from the hint leading edge to the whole bubble edge.
  ///
  /// This is only used by [SpotlightGuidePointerBubblePlacement.alongPlacement].
  /// Leave null for the default pointer-between-target-and-bubble layout. Set
  /// a value only when a custom pointer asset needs manual composition.
  final double? bubbleOffset;

  /// Visual-only child offset that does not affect the anchor chain.
  final SpotlightGuidePointerOffset visualOffset;
}

/// A common hint container that combines [SpotlightGuideBubble] with an
/// optional visual pointer.
///
/// Without a pointer, the step item's target anchor resolves the indicator
/// position on the target. When [pointer] participates in the default pointer
/// chain, [SpotlightGuideHintPointer.pointerAnchorPosition] chooses which
/// point inside the pointer aligns to the target, and
/// [SpotlightGuideStepItem.targetAnchorPosition] chooses which point inside
/// the pointer the bubble anchor aligns to.
class SpotlightGuideBubbleHint extends StatelessWidget {
  const SpotlightGuideBubbleHint({
    super.key,
    required this.guide,
    required this.child,
    this.decoration,
    this.pointer,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Resolved layout data for the current step item.
  final SpotlightGuideStepContext guide;

  /// Content displayed inside the bubble body.
  final Widget child;

  /// Optional decoration override.
  ///
  /// When null, [SpotlightGuideStepContext.decoration] is used. Prefer setting
  /// decoration on [SpotlightGuideStepItem] so layout and painting share the
  /// same anchor size.
  final SpotlightGuideAnchoredDecoration? decoration;

  /// Optional visual pointer configuration.
  final SpotlightGuideHintPointer? pointer;

  /// Clip behavior applied to the bubble body content.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final SpotlightGuideHintPointer? pointer = this.pointer;
    final TextDirection textDirection = Directionality.of(context);
    final Widget? pointerChild = pointer?._buildChild(
      context,
      _pointerContextFor(
        guide: guide,
        pointer: pointer,
        textDirection: textDirection,
      ),
    );
    return _SpotlightGuideBubbleHintLayout(
      guide: guide,
      decoration: decoration ?? guide.decoration,
      pointer: pointer,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      children: <Widget>[
        SpotlightGuideBubble(
          decoration: decoration ?? guide.decoration,
          clipBehavior: clipBehavior,
          child: IntrinsicHeight(child: child),
        ),
        if (pointerChild != null) IgnorePointer(child: pointerChild),
      ],
    );
  }
}

extension on SpotlightGuideHintPointer {
  Widget _buildChild(
    BuildContext context,
    SpotlightGuidePointerContext pointerContext,
  ) {
    return builder?.call(context, pointerContext, child) ?? child;
  }
}

SpotlightGuidePointerContext _pointerContextFor({
  required SpotlightGuideStepContext guide,
  required SpotlightGuideHintPointer pointer,
  required TextDirection textDirection,
}) {
  final SpotlightGuidePointerBubblePlacement bubblePlacement =
      _resolvePointerBubblePlacement(pointer, textDirection);
  final SpotlightGuideIndicatorDirection bubbleAnchorDirection =
      _pointerBubbleAnchorDirection(guide.indicatorDirection, bubblePlacement);
  return SpotlightGuidePointerContext(
    guide: guide,
    textDirection: textDirection,
    targetDirection: guide.indicatorDirection,
    bubbleDirection: _oppositeDirection(bubbleAnchorDirection),
    bubbleAnchorDirection: bubbleAnchorDirection,
    bubblePlacement: bubblePlacement,
    anchorMode: pointer.anchorMode,
  );
}

SpotlightGuidePointerBubblePlacement _resolvePointerBubblePlacement(
  SpotlightGuideHintPointer pointer,
  TextDirection textDirection,
) {
  if (pointer.anchorMode != SpotlightGuidePointerAnchorMode.pointer) {
    return SpotlightGuidePointerBubblePlacement.alongPlacement;
  }
  final SpotlightGuidePointerBubblePlacement placement =
      pointer.bubblePlacement;
  return switch (placement) {
    SpotlightGuidePointerBubblePlacement.start => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePointerBubblePlacement.left,
      TextDirection.rtl => SpotlightGuidePointerBubblePlacement.right,
    },
    SpotlightGuidePointerBubblePlacement.end => switch (textDirection) {
      TextDirection.ltr => SpotlightGuidePointerBubblePlacement.right,
      TextDirection.rtl => SpotlightGuidePointerBubblePlacement.left,
    },
    SpotlightGuidePointerBubblePlacement.alongPlacement ||
    SpotlightGuidePointerBubblePlacement.top ||
    SpotlightGuidePointerBubblePlacement.bottom ||
    SpotlightGuidePointerBubblePlacement.left ||
    SpotlightGuidePointerBubblePlacement.right => placement,
  };
}

SpotlightGuideIndicatorDirection _pointerBubbleAnchorDirection(
  SpotlightGuideIndicatorDirection targetDirection,
  SpotlightGuidePointerBubblePlacement bubblePlacement,
) {
  return switch (bubblePlacement) {
    SpotlightGuidePointerBubblePlacement.alongPlacement => targetDirection,
    SpotlightGuidePointerBubblePlacement.top =>
      SpotlightGuideIndicatorDirection.down,
    SpotlightGuidePointerBubblePlacement.bottom =>
      SpotlightGuideIndicatorDirection.up,
    SpotlightGuidePointerBubblePlacement.left =>
      SpotlightGuideIndicatorDirection.right,
    SpotlightGuidePointerBubblePlacement.right =>
      SpotlightGuideIndicatorDirection.left,
    SpotlightGuidePointerBubblePlacement.start ||
    SpotlightGuidePointerBubblePlacement.end => throw StateError(
      'semantic placements must be resolved before pointer context',
    ),
  };
}

SpotlightGuideIndicatorDirection _oppositeDirection(
  SpotlightGuideIndicatorDirection direction,
) {
  return switch (direction) {
    SpotlightGuideIndicatorDirection.up =>
      SpotlightGuideIndicatorDirection.down,
    SpotlightGuideIndicatorDirection.down =>
      SpotlightGuideIndicatorDirection.up,
    SpotlightGuideIndicatorDirection.left =>
      SpotlightGuideIndicatorDirection.right,
    SpotlightGuideIndicatorDirection.right =>
      SpotlightGuideIndicatorDirection.left,
  };
}

class _SpotlightGuideBubbleHintLayout extends MultiChildRenderObjectWidget {
  const _SpotlightGuideBubbleHintLayout({
    required this.guide,
    required this.decoration,
    required this.pointer,
    required this.textDirection,
    required this.clipBehavior,
    required super.children,
  });

  final SpotlightGuideStepContext guide;
  final SpotlightGuideAnchoredDecoration decoration;
  final SpotlightGuideHintPointer? pointer;
  final TextDirection textDirection;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightGuideBubbleHint(
      guide: guide,
      decoration: decoration,
      pointer: pointer,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightGuideBubbleHint renderObject,
  ) {
    renderObject
      ..guide = guide
      ..decoration = decoration
      ..pointer = pointer
      ..textDirection = textDirection
      ..clipBehavior = clipBehavior;
  }
}

class _SpotlightGuideBubbleHintParentData
    extends ContainerBoxParentData<RenderBox> {}

class _RenderSpotlightGuideBubbleHint extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          _SpotlightGuideBubbleHintParentData
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _SpotlightGuideBubbleHintParentData
        > {
  _RenderSpotlightGuideBubbleHint({
    required SpotlightGuideStepContext guide,
    required SpotlightGuideAnchoredDecoration decoration,
    required SpotlightGuideHintPointer? pointer,
    required TextDirection textDirection,
    required Clip clipBehavior,
  }) : _guide = guide,
       _decoration = decoration,
       _pointer = pointer,
       _textDirection = textDirection,
       _clipBehavior = clipBehavior;

  SpotlightGuideStepContext _guide;

  set guide(SpotlightGuideStepContext value) {
    if (_guide == value) {
      return;
    }
    _guide = value;
    markNeedsLayout();
  }

  SpotlightGuideAnchoredDecoration _decoration;

  set decoration(SpotlightGuideAnchoredDecoration value) {
    if (_decoration == value) {
      return;
    }
    _decoration = value;
    markNeedsLayout();
  }

  SpotlightGuideHintPointer? _pointer;

  set pointer(SpotlightGuideHintPointer? value) {
    if (_pointer == value) {
      return;
    }
    _pointer = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  Clip _clipBehavior;

  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
  }

  Offset _bubblePaintOffset = Offset.zero;
  Offset _pointerPaintOffset = Offset.zero;
  Rect _paintBounds = Rect.zero;

  RenderBox? get _bubbleChild => firstChild;

  RenderBox? get _pointerChild {
    final RenderBox? bubble = _bubbleChild;
    if (bubble == null) {
      return null;
    }
    return childAfter(bubble);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SpotlightGuideBubbleHintParentData) {
      child.parentData = _SpotlightGuideBubbleHintParentData();
    }
  }

  @override
  void performLayout() {
    final RenderBox? bubble = _bubbleChild;
    if (bubble == null) {
      size = constraints.smallest;
      return;
    }

    final Size? pointerSize = _layoutPointer();
    _BubbleHintBubbleLayout bubbleLayout = _layoutBubble(
      _guide.indicatorOffset,
      pointerSize: pointerSize,
    );
    double indicatorOffset = _effectiveIndicatorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    bubbleLayout = _layoutBubble(indicatorOffset, pointerSize: pointerSize);
    final double resolvedIndicatorOffset = _effectiveIndicatorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    if ((resolvedIndicatorOffset - indicatorOffset).abs() > 0.01) {
      indicatorOffset = resolvedIndicatorOffset;
      bubbleLayout = _layoutBubble(indicatorOffset, pointerSize: pointerSize);
    }

    final Offset bubbleOffset = _bubbleOffset(
      pointerSize: pointerSize,
      indicatorOffset: indicatorOffset,
      bubbleSize: bubbleLayout.size,
    );
    final Offset translation = _translationOffset(
      pointerSize: pointerSize,
      indicatorOffset: indicatorOffset,
      bubbleOffset: bubbleOffset,
      bubbleSize: bubbleLayout.size,
    );

    _bubblePaintOffset = translation + bubbleOffset;
    final _SpotlightGuideBubbleHintParentData bubbleParentData =
        bubble.parentData! as _SpotlightGuideBubbleHintParentData;
    bubbleParentData.offset = _bubblePaintOffset;

    Rect bounds = _bubblePaintOffset & bubbleLayout.size;
    final RenderBox? pointer = _pointerChild;
    if (pointer != null && pointerSize != null) {
      _pointerPaintOffset =
          translation +
          Offset(
            _pointerLeft(
              pointerSize,
              indicatorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
            _pointerTop(
              pointerSize,
              indicatorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
          ) +
          (_pointer?.visualOffset.resolve(_textDirection) ?? Offset.zero);
      final _SpotlightGuideBubbleHintParentData pointerParentData =
          pointer.parentData! as _SpotlightGuideBubbleHintParentData;
      pointerParentData.offset = _pointerPaintOffset;
      bounds = bounds.expandToInclude(_pointerPaintOffset & pointerSize);
    } else {
      _pointerPaintOffset = Offset.zero;
    }

    _paintBounds = bounds;
    size = constraints.constrain(
      Size(
        math.max(
          math.max(0, bubbleOffset.dx + bubbleLayout.size.width),
          bounds.right,
        ),
        math.max(
          math.max(0, bubbleOffset.dy + bubbleLayout.size.height),
          bounds.bottom,
        ),
      ),
    );
  }

  Offset _bubbleOffset({
    required Size? pointerSize,
    required double indicatorOffset,
    required Size bubbleSize,
  }) {
    if (!_pointerAffectsBubble || pointerSize == null) {
      return Offset.zero;
    }
    final SpotlightGuideHintPointer pointer = _pointer!;
    final SpotlightGuidePointerBubblePlacement placement =
        _resolvedBubblePlacement;
    if (placement != SpotlightGuidePointerBubblePlacement.alongPlacement) {
      return switch (placement) {
        SpotlightGuidePointerBubblePlacement.bottom => Offset(
          0,
          math.max(
            pointerSize.height + _pointerAnchorGap,
            guide.targetRect.bottom -
                _targetContactAxis(isHorizontalAxis: false) +
                _pointerTargetOffset(
                  isHorizontalAxis: false,
                  extent: pointerSize.height,
                ) +
                _pointerAnchorGap,
          ),
        ),
        SpotlightGuidePointerBubblePlacement.right => Offset(
          math.max(
            pointerSize.width + _pointerAnchorGap,
            guide.targetRect.right -
                _targetContactAxis(isHorizontalAxis: true) +
                _pointerTargetOffset(
                  isHorizontalAxis: true,
                  extent: pointerSize.width,
                ) +
                _pointerAnchorGap,
          ),
          0,
        ),
        SpotlightGuidePointerBubblePlacement.top ||
        SpotlightGuidePointerBubblePlacement.left => Offset.zero,
        SpotlightGuidePointerBubblePlacement.start ||
        SpotlightGuidePointerBubblePlacement.end ||
        SpotlightGuidePointerBubblePlacement.alongPlacement => throw StateError(
          'semantic and along placements are resolved before bubble offset',
        ),
      };
    }
    final double leading = math.max(
      0,
      pointer.bubbleOffset ??
          switch (_guide.indicatorDirection) {
            SpotlightGuideIndicatorDirection.up =>
              pointerSize.height + _pointerAnchorGap,
            SpotlightGuideIndicatorDirection.left =>
              pointerSize.width + _pointerAnchorGap,
            SpotlightGuideIndicatorDirection.down ||
            SpotlightGuideIndicatorDirection.right => 0,
          },
    );
    return switch (_guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up => Offset(0, leading),
      SpotlightGuideIndicatorDirection.left => Offset(leading, 0),
      SpotlightGuideIndicatorDirection.down ||
      SpotlightGuideIndicatorDirection.right => Offset.zero,
    };
  }

  BoxConstraints _bubbleConstraints(Size? pointerSize) {
    final Size reserved = _reservedBubbleExtent(pointerSize);
    double minWidth = constraints.minWidth;
    double maxWidth = constraints.maxWidth;
    double minHeight = constraints.minHeight;
    double maxHeight = constraints.maxHeight;
    if (maxWidth.isFinite) {
      maxWidth = math.max(0, maxWidth - reserved.width);
      minWidth = math.min(minWidth, maxWidth);
    }
    if (maxHeight.isFinite) {
      maxHeight = math.max(0, maxHeight - reserved.height);
      minHeight = math.min(minHeight, maxHeight);
    }

    final double extent = _minimumBubbleIndicatorSideExtent();
    if (extent.isFinite && extent > 0) {
      switch (_anchorDirection) {
        case SpotlightGuideIndicatorDirection.up ||
            SpotlightGuideIndicatorDirection.down:
          minWidth = math.max(minWidth, extent);
          if (maxWidth.isFinite) {
            minWidth = math.min(minWidth, maxWidth);
          }
        case SpotlightGuideIndicatorDirection.left ||
            SpotlightGuideIndicatorDirection.right:
          minHeight = math.max(minHeight, extent);
          if (maxHeight.isFinite) {
            minHeight = math.min(minHeight, maxHeight);
          }
      }
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  Size _reservedBubbleExtent(Size? pointerSize) {
    if (!_pointerAffectsBubble || pointerSize == null) {
      return Size.zero;
    }
    final double horizontalAlongExtent = math.max(
      0,
      pointerSize.width + _pointerAnchorGap + _pointerTargetGap,
    );
    final double verticalAlongExtent = math.max(
      0,
      pointerSize.height + _pointerAnchorGap + _pointerTargetGap,
    );
    return switch (_resolvedBubblePlacement) {
      SpotlightGuidePointerBubblePlacement.alongPlacement =>
        switch (_guide.indicatorDirection) {
          SpotlightGuideIndicatorDirection.up ||
          SpotlightGuideIndicatorDirection.down => Size(0, verticalAlongExtent),
          SpotlightGuideIndicatorDirection.left ||
          SpotlightGuideIndicatorDirection.right => Size(
            horizontalAlongExtent,
            0,
          ),
        },
      SpotlightGuidePointerBubblePlacement.top ||
      SpotlightGuidePointerBubblePlacement.bottom => Size(
        0,
        math.max(0, pointerSize.height + _pointerAnchorGap),
      ),
      SpotlightGuidePointerBubblePlacement.left ||
      SpotlightGuidePointerBubblePlacement.right => Size(
        math.max(0, pointerSize.width + _pointerAnchorGap),
        0,
      ),
      SpotlightGuidePointerBubblePlacement.start ||
      SpotlightGuidePointerBubblePlacement.end => throw StateError(
        'semantic placements are resolved before bubble constraints',
      ),
    };
  }

  double _effectiveIndicatorOffset({
    required Size? pointerSize,
    required Size bubbleSize,
  }) {
    final SpotlightGuideIndicatorDirection anchorDirection = _anchorDirection;
    final bool isHorizontalSide =
        anchorDirection == SpotlightGuideIndicatorDirection.up ||
        anchorDirection == SpotlightGuideIndicatorDirection.down;
    final double measuredExtent = isHorizontalSide
        ? bubbleSize.width
        : bubbleSize.height;
    final double extent = math.max(
      measuredExtent,
      _minimumBubbleIndicatorSideExtent(),
    );
    if (!extent.isFinite || extent <= 0) {
      return _guide.indicatorOffset;
    }
    final double preferredOffset =
        _resolvedBubblePlacement ==
            SpotlightGuidePointerBubblePlacement.alongPlacement
        ? _guide.indicatorOffset
        : extent / 2;
    final double safeOffset = _HintLayout._resolveEffectiveIndicatorOffset(
      preferredOffset,
      extent: extent,
      connectionHalfExtent: _guide.anchorConnectionHalfExtent,
      safeInset: _guide.indicatorSafeInset,
    );
    return _resolveMarginSafeIndicatorOffset(
      safeOffset,
      pointerSize: pointerSize,
      isHorizontalSide: isHorizontalSide,
      extent: extent,
    );
  }

  Offset _translationOffset({
    required Size? pointerSize,
    required double indicatorOffset,
    required Offset bubbleOffset,
    required Size bubbleSize,
  }) {
    final Offset preferred = switch (guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down => Offset(
        _targetContactAxis(isHorizontalAxis: true) -
            guide.hintRect.left -
            _pointerAnchorX(
              pointerSize,
              indicatorOffset,
              bubbleOffset,
              bubbleSize,
            ),
        _pointer == null || pointerSize == null
            ? 0
            : _pointerAffectsBubble
            ? _pointerTargetTop(pointerSize) -
                  guide.hintRect.top -
                  _pointerTop(
                    pointerSize,
                    indicatorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
      ),
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right => Offset(
        _pointer == null || pointerSize == null
            ? 0
            : _pointerAffectsBubble
            ? _pointerTargetLeft(pointerSize) -
                  guide.hintRect.left -
                  _pointerLeft(
                    pointerSize,
                    indicatorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
        _targetContactAxis(isHorizontalAxis: false) -
            guide.hintRect.top -
            _pointerAnchorY(
              pointerSize,
              indicatorOffset,
              bubbleOffset,
              bubbleSize,
            ),
      ),
    };
    return _clampTranslationToHintRect(
      preferred,
      _contentBounds(pointerSize, indicatorOffset, bubbleOffset, bubbleSize),
    );
  }

  Rect _contentBounds(
    Size? pointerSize,
    double indicatorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    Rect bounds = Rect.fromLTWH(
      bubbleOffset.dx,
      bubbleOffset.dy,
      bubbleSize.width,
      bubbleSize.height,
    );
    if (_pointer == null || pointerSize == null) {
      return bounds;
    }
    final Rect pointerBounds = Rect.fromLTWH(
      _pointerLeft(pointerSize, indicatorOffset, bubbleOffset, bubbleSize),
      _pointerTop(pointerSize, indicatorOffset, bubbleOffset, bubbleSize),
      pointerSize.width,
      pointerSize.height,
    );
    bounds = bounds.expandToInclude(pointerBounds);
    return bounds;
  }

  Offset _clampTranslationToHintRect(Offset preferred, Rect contentBounds) {
    if (_pointerAffectsBubble) {
      // Pointer safety is handled by shifting the bubble anchor offset. Clamping
      // the whole stack here would move the pointer away from its target.
      return preferred;
    }

    double minDx = -contentBounds.left;
    double maxDx = guide.hintRect.width - contentBounds.right;
    double minDy = -contentBounds.top;
    double maxDy = guide.hintRect.height - contentBounds.bottom;
    final double dx = _HintLayout._clampDouble(preferred.dx, minDx, maxDx);
    final double dy = _HintLayout._clampDouble(preferred.dy, minDy, maxDy);
    return Offset(dx, dy);
  }

  double _pointerLeft(
    Size size,
    double indicatorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuidePointerBubblePlacement placement =
        _resolvedBubblePlacement;
    if (placement != SpotlightGuidePointerBubblePlacement.alongPlacement) {
      return switch (placement) {
        SpotlightGuidePointerBubblePlacement.top ||
        SpotlightGuidePointerBubblePlacement.bottom =>
          bubbleOffset.dx +
              indicatorOffset -
              _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
        SpotlightGuidePointerBubblePlacement.left => math.max(
          bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
          _targetContactAxis(isHorizontalAxis: true) -
              guide.targetRect.left +
              bubbleSize.width -
              _pointerTargetOffset(isHorizontalAxis: true, extent: size.width) +
              _pointerAnchorGap,
        ),
        SpotlightGuidePointerBubblePlacement.right => 0,
        SpotlightGuidePointerBubblePlacement.start ||
        SpotlightGuidePointerBubblePlacement.end ||
        SpotlightGuidePointerBubblePlacement.alongPlacement => throw StateError(
          'semantic and along placements are resolved before pointer left',
        ),
      };
    }
    return switch (_guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down =>
        indicatorOffset -
            _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
      SpotlightGuideIndicatorDirection.left => 0,
      SpotlightGuideIndicatorDirection.right =>
        bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
    };
  }

  double _pointerTop(
    Size size,
    double indicatorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuidePointerBubblePlacement placement =
        _resolvedBubblePlacement;
    if (placement != SpotlightGuidePointerBubblePlacement.alongPlacement) {
      return switch (placement) {
        SpotlightGuidePointerBubblePlacement.top => math.max(
          bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
          _targetContactAxis(isHorizontalAxis: false) -
              guide.targetRect.top +
              bubbleSize.height -
              _pointerTargetOffset(
                isHorizontalAxis: false,
                extent: size.height,
              ) +
              _pointerAnchorGap,
        ),
        SpotlightGuidePointerBubblePlacement.bottom => 0,
        SpotlightGuidePointerBubblePlacement.left ||
        SpotlightGuidePointerBubblePlacement.right =>
          bubbleOffset.dy +
              indicatorOffset -
              _pointerBubbleOffset(
                isHorizontalAxis: false,
                extent: size.height,
              ),
        SpotlightGuidePointerBubblePlacement.start ||
        SpotlightGuidePointerBubblePlacement.end ||
        SpotlightGuidePointerBubblePlacement.alongPlacement => throw StateError(
          'semantic and along placements are resolved before pointer top',
        ),
      };
    }
    return switch (_guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up => 0,
      SpotlightGuideIndicatorDirection.down =>
        bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right =>
        indicatorOffset -
            _pointerBubbleOffset(isHorizontalAxis: false, extent: size.height),
    };
  }

  SpotlightGuideStepContext get guide => _guide;

  bool get _pointerAffectsBubble {
    return _pointer?.anchorMode == SpotlightGuidePointerAnchorMode.pointer;
  }

  double get _pointerAnchorGap {
    return _guide.gap;
  }

  double _pointerTargetLeft(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.left =>
        guide.targetRect.right + targetGap,
      SpotlightGuideIndicatorDirection.right =>
        guide.targetRect.left - size.width - targetGap,
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down => guide.targetRect.left,
    };
  }

  double _pointerTargetTop(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up =>
        guide.targetRect.bottom + targetGap,
      SpotlightGuideIndicatorDirection.down =>
        guide.targetRect.top - size.height - targetGap,
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right => guide.targetRect.top,
    };
  }

  double get _pointerTargetGap {
    return _pointer?.targetGap ?? 0;
  }

  double _targetContactAxis({required bool isHorizontalAxis}) {
    if (!_pointerAffectsBubble) {
      return isHorizontalAxis
          ? guide.targetAnchorPoint.dx
          : guide.targetAnchorPoint.dy;
    }
    return isHorizontalAxis
        ? guide.targetRect.center.dx
        : guide.targetRect.center.dy;
  }

  double _resolveMarginSafeIndicatorOffset(
    double offset, {
    required Size? pointerSize,
    required bool isHorizontalSide,
    required double extent,
  }) {
    if (!_pointerAffectsBubble ||
        pointerSize == null ||
        !offset.isFinite ||
        !extent.isFinite ||
        extent <= 0) {
      return offset;
    }

    final Offset anchorPoint = _pointerTargetAnchorPoint(pointerSize);
    final double anchor = isHorizontalSide ? anchorPoint.dx : anchorPoint.dy;
    final EdgeInsets margin = guide.margin;
    final double minOrigin = isHorizontalSide ? margin.left : margin.top;
    final double maxEnd = isHorizontalSide
        ? guide.overlaySize.width - margin.right
        : guide.overlaySize.height - margin.bottom;
    if (!anchor.isFinite || maxEnd <= minOrigin) {
      return offset;
    }

    final double safeInset = math.min(
      math.max(guide.anchorConnectionHalfExtent, guide.indicatorSafeInset),
      extent / 2,
    );
    final double safeMin = safeInset;
    final double safeMax = math.max(safeMin, extent - safeInset);
    final double marginMin = anchor + extent - maxEnd;
    final double marginMax = anchor - minOrigin;
    final double minOffset = math.max(safeMin, marginMin);
    final double maxOffset = math.min(safeMax, marginMax);

    if (maxOffset >= minOffset) {
      return _HintLayout._clampDouble(offset, minOffset, maxOffset);
    }

    // If the requested content cannot satisfy both the screen margin and anchor
    // safety, keep the hint inside the margin first. The measured constraints
    // usually shrink the bubble on the next frame; this fallback avoids leaving
    // visible content outside the overlay edge while that happens.
    if (marginMax >= marginMin) {
      return _HintLayout._clampDouble(offset, marginMin, marginMax);
    }

    return _HintLayout._clampDouble(offset, safeMin, safeMax);
  }

  Offset _pointerTargetAnchorPoint(Size size) {
    final double pointerTargetX = _pointerTargetOffset(
      isHorizontalAxis: true,
      extent: size.width,
    );
    final double pointerTargetY = _pointerTargetOffset(
      isHorizontalAxis: false,
      extent: size.height,
    );
    final double pointerBubbleX = _pointerBubbleOffset(
      isHorizontalAxis: true,
      extent: size.width,
    );
    final double pointerBubbleY = _pointerBubbleOffset(
      isHorizontalAxis: false,
      extent: size.height,
    );
    final double targetGap = _pointerTargetGap;
    return Offset(
      switch (guide.indicatorDirection) {
        SpotlightGuideIndicatorDirection.up ||
        SpotlightGuideIndicatorDirection.down =>
          guide.targetRect.center.dx - pointerTargetX + pointerBubbleX,
        SpotlightGuideIndicatorDirection.left =>
          guide.targetRect.right + targetGap + pointerBubbleX,
        SpotlightGuideIndicatorDirection.right =>
          guide.targetRect.left - targetGap - size.width + pointerBubbleX,
      },
      switch (guide.indicatorDirection) {
        SpotlightGuideIndicatorDirection.up =>
          guide.targetRect.bottom + targetGap + pointerBubbleY,
        SpotlightGuideIndicatorDirection.down =>
          guide.targetRect.top - targetGap - size.height + pointerBubbleY,
        SpotlightGuideIndicatorDirection.left ||
        SpotlightGuideIndicatorDirection.right =>
          guide.targetRect.center.dy - pointerTargetY + pointerBubbleY,
      },
    );
  }

  SpotlightGuidePointerBubblePlacement get _resolvedBubblePlacement {
    final SpotlightGuideHintPointer? pointer = _pointer;
    if (pointer == null) {
      return SpotlightGuidePointerBubblePlacement.alongPlacement;
    }
    return _resolvePointerBubblePlacement(pointer, _textDirection);
  }

  SpotlightGuideIndicatorDirection get _anchorDirection {
    return switch (_resolvedBubblePlacement) {
      SpotlightGuidePointerBubblePlacement.alongPlacement =>
        _guide.indicatorDirection,
      SpotlightGuidePointerBubblePlacement.top =>
        SpotlightGuideIndicatorDirection.down,
      SpotlightGuidePointerBubblePlacement.bottom =>
        SpotlightGuideIndicatorDirection.up,
      SpotlightGuidePointerBubblePlacement.left =>
        SpotlightGuideIndicatorDirection.right,
      SpotlightGuidePointerBubblePlacement.right =>
        SpotlightGuideIndicatorDirection.left,
      SpotlightGuidePointerBubblePlacement.start ||
      SpotlightGuidePointerBubblePlacement.end => throw StateError(
        'semantic placements are resolved before anchor direction',
      ),
    };
  }

  double _pointerAnchorX(
    Size? size,
    double indicatorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return indicatorOffset;
    }
    return _pointerLeft(size, indicatorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: true, extent: size.width);
  }

  double _pointerAnchorY(
    Size? size,
    double indicatorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return indicatorOffset;
    }
    return _pointerTop(size, indicatorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: false, extent: size.height);
  }

  double _minimumBubbleIndicatorSideExtent() {
    final bool sameAxis = _anchorDirection == _guide.indicatorDirection;
    final double layoutExtent = sameAxis ? _guide.bubbleIndicatorSideExtent : 0;
    final double safeExtent =
        math.max(_guide.anchorConnectionHalfExtent, _guide.indicatorSafeInset) *
        2;
    return math.max(layoutExtent, safeExtent);
  }

  double _pointerTargetOffset({
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      _pointer!.pointerAnchorPosition,
      textDirection: _textDirection,
      isHorizontalAxis: isHorizontalAxis,
      extent: extent,
    );
  }

  double _pointerBubbleOffset({
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      _guide.targetAnchorPosition,
      textDirection: _textDirection,
      isHorizontalAxis: isHorizontalAxis,
      extent: extent,
    );
  }

  Size? _layoutPointer() {
    final RenderBox? pointer = _pointerChild;
    if (pointer == null || _pointer == null) {
      return null;
    }
    final Size? fixedSize = _pointer!.size;
    final BoxConstraints pointerConstraints = fixedSize == null
        ? BoxConstraints.loose(_finiteConstraintSize())
        : BoxConstraints.tight(fixedSize);
    pointer.layout(pointerConstraints, parentUsesSize: true);
    return pointer.size;
  }

  _BubbleHintBubbleLayout _layoutBubble(
    double indicatorOffset, {
    required Size? pointerSize,
  }) {
    final RenderBox bubble = _bubbleChild!;
    final SpotlightGuideAnchoredDecoration resolvedDecoration = _decoration
        .resolveAnchor(
          SpotlightGuideAnchorGeometry(
            direction: _anchorDirection,
            offset: indicatorOffset,
          ),
        );
    if (bubble is _RenderSpotlightGuideBubble) {
      bubble.useLayoutDecoration(resolvedDecoration);
    }
    bubble.layout(_bubbleConstraints(pointerSize), parentUsesSize: true);
    return _BubbleHintBubbleLayout(
      size: bubble.size,
      decoration: resolvedDecoration,
    );
  }

  Size _finiteConstraintSize() {
    double width = constraints.maxWidth;
    double height = constraints.maxHeight;
    if (!width.isFinite) {
      width = _guide.overlaySize.width;
    }
    if (!height.isFinite) {
      height = _guide.overlaySize.height;
    }
    return Size(math.max(0, width), math.max(0, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? bubble = _bubbleChild;
    final RenderBox? pointer = _pointerChild;
    if (bubble == null) {
      return;
    }
    final SpotlightGuidePointerLayer layer =
        _pointer?.layer ?? SpotlightGuidePointerLayer.belowBubble;
    if (pointer != null && layer == SpotlightGuidePointerLayer.belowBubble) {
      context.paintChild(pointer, offset + _pointerPaintOffset);
    }
    context.paintChild(bubble, offset + _bubblePaintOffset);
    if (pointer != null && layer == SpotlightGuidePointerLayer.aboveBubble) {
      context.paintChild(pointer, offset + _pointerPaintOffset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position) && !_paintBounds.contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? bubble = _bubbleChild;
    final RenderBox? pointer = _pointerChild;
    final SpotlightGuidePointerLayer layer =
        _pointer?.layer ?? SpotlightGuidePointerLayer.belowBubble;
    if (pointer != null && layer == SpotlightGuidePointerLayer.aboveBubble) {
      if (_hitTestChild(result, pointer, _pointerPaintOffset, position)) {
        return true;
      }
    }
    if (bubble != null &&
        _hitTestChild(result, bubble, _bubblePaintOffset, position)) {
      return true;
    }
    if (pointer != null && layer == SpotlightGuidePointerLayer.belowBubble) {
      return _hitTestChild(result, pointer, _pointerPaintOffset, position);
    }
    return false;
  }

  bool _hitTestChild(
    BoxHitTestResult result,
    RenderBox child,
    Offset childOffset,
    Offset position,
  ) {
    return result.addWithPaintOffset(
      offset: childOffset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final _SpotlightGuideBubbleHintParentData childParentData =
        child.parentData! as _SpotlightGuideBubbleHintParentData;
    transform.translateByDouble(
      childParentData.offset.dx,
      childParentData.offset.dy,
      0,
      1,
    );
  }
}

class _BubbleHintBubbleLayout {
  const _BubbleHintBubbleLayout({required this.size, required this.decoration});

  final Size size;
  final SpotlightGuideAnchoredDecoration decoration;
}
