part of '../../spotlight_guide.dart';

/// Paint order used for [SpotlightGuideStepItem.pointer].
enum SpotlightGuidePointerLayer {
  /// Paint the pointer below the bubble so pointer lines do not cover content.
  belowBubble,

  /// Paint the pointer above the bubble.
  aboveBubble,
}

/// Builds a pointer child with resolved placement information.
///
/// [child] is the original [SpotlightGuidePointer.child]. Return it
/// unchanged for the default appearance, or wrap it with transforms, animation,
/// direction-specific assets, or extra connector UI.
typedef SpotlightGuidePointerBuilder =
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

  static SpotlightGuidePointerDirection _fromDirection(
    SpotlightGuideDirection direction,
  ) {
    return switch (direction) {
      SpotlightGuideDirection.up =>
        const SpotlightGuidePointerDirection.up(),
      SpotlightGuideDirection.right =>
        const SpotlightGuidePointerDirection.right(),
      SpotlightGuideDirection.down =>
        const SpotlightGuidePointerDirection.down(),
      SpotlightGuideDirection.left =>
        const SpotlightGuidePointerDirection.left(),
    };
  }
}

double? _pointerTargetLayoutGap(SpotlightGuidePointer? pointer) {
  if (pointer == null ||
      pointer.anchorMode != SpotlightGuidePointerAnchorMode.pointer) {
    return null;
  }
  return _finiteOrZero(pointer.targetGap);
}

double _stepTargetLayoutGap(SpotlightGuideStepItem item) {
  return _pointerTargetLayoutGap(item.pointer) ?? _finiteOrZero(item.gap);
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

/// Where the bubble body sits relative to [SpotlightGuideStepItem.pointer].
///
/// This does not choose where the pointer sits around the target. That remains
/// the job of [SpotlightGuideStepItem.placement]. This enum only chooses the
/// second segment of the chain: pointer -> bubble. The distance on that segment
/// is controlled by [SpotlightGuideStepItem.gap], not by the target size.
enum SpotlightGuideBubbleSide {
  /// Keep the target -> pointer -> bubble line on the same axis.
  ///
  /// The bubble is placed farther away from the target in the resolved
  /// [SpotlightGuideStepItem.placement] direction.
  along,

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
    required this.bubbleSide,
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
  final SpotlightGuideDirection targetDirection;

  /// Direction from the pointer toward the bubble body.
  final SpotlightGuideDirection bubbleDirection;

  /// Direction used by the bubble anchor that connects back to the pointer.
  final SpotlightGuideDirection bubbleAnchorDirection;

  /// Resolved physical bubble side relative to the pointer.
  final SpotlightGuideBubbleSide bubbleSide;

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
      SpotlightGuidePointerDirection._fromDirection(targetDirection),
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
      SpotlightGuidePointerDirection._fromDirection(bubbleDirection),
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
      return 0;
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

/// Visual-only offset applied to [SpotlightGuidePointer.child].
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
    return Offset(
      _finiteOrZero(_physicalDx + resolvedDirectionalDx),
      _finiteOrZero(dy),
    );
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
/// - [bubbleSide] chooses where the bubble sits relative to the pointer.
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
///
/// For image or animation pointers, prefer [size] or an otherwise tight child
/// layout so the pointer reserves a stable slot before the asset decodes. If
/// [size] is omitted, [SpotlightGuideBubbleHint] uses the child's laid-out size
/// and reports transient zero-size pointer frames as not paint-ready, so the
/// overlay can reveal target holes and hints together from a stable layout.
class SpotlightGuidePointer {
  const SpotlightGuidePointer({
    required this.child,
    this.builder,
    this.size,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.targetGap = 0,
    this.layer = SpotlightGuidePointerLayer.belowBubble,
    this.anchorMode = SpotlightGuidePointerAnchorMode.pointer,
    this.bubbleSide = SpotlightGuideBubbleSide.along,
    this.bubbleOffset,
    this.visualOffset = SpotlightGuidePointerOffset.zero,
  });

  /// Convenience configuration using the built-in [SpotlightGuideTapPointer].
  const SpotlightGuidePointer.tap({
    this.builder,
    this.size = SpotlightGuideTapPointer.defaultSize,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.targetGap = 0,
    this.layer = SpotlightGuidePointerLayer.belowBubble,
    this.anchorMode = SpotlightGuidePointerAnchorMode.pointer,
    this.bubbleSide = SpotlightGuideBubbleSide.along,
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
  final SpotlightGuidePointerBuilder? builder;

  /// Optional size reserved for [child] in the guide layout.
  ///
  /// When null, the pointer child is laid out with loose constraints and its
  /// own size is used. Provide a size when a pointer asset should reserve a
  /// stable visual slot regardless of the child's intrinsic dimensions or image
  /// decode timing.
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
  /// Defaults to [SpotlightGuideBubbleSide.along], which
  /// keeps the target, pointer and bubble on the same main axis. Use
  /// [SpotlightGuideBubbleSide.bottom] for common "pointer points
  /// sideways, explanation appears below it" compositions.
  final SpotlightGuideBubbleSide bubbleSide;

  /// Optional distance from the hint leading edge to the whole bubble edge.
  ///
  /// This is only used by [SpotlightGuideBubbleSide.along].
  /// Leave null for the default pointer-between-target-and-bubble layout. Set
  /// a value only when a custom pointer asset needs manual composition.
  final double? bubbleOffset;

  /// Visual-only child offset that does not affect the anchor chain.
  final SpotlightGuidePointerOffset visualOffset;
}

/// A common hint container that combines [SpotlightGuideBubble] with an
/// optional visual pointer.
///
/// Without a pointer, the step item's target anchor resolves the anchor
/// position on the target. When [SpotlightGuideStepItem.pointer] participates
/// in the default pointer chain,
/// [SpotlightGuidePointer.pointerAnchorPosition] chooses which point inside
/// the pointer aligns to the target, and
/// [SpotlightGuideStepItem.targetAnchorPosition] chooses which point inside the
/// pointer the bubble anchor aligns to.
class SpotlightGuideBubbleHint extends StatelessWidget {
  const SpotlightGuideBubbleHint({
    super.key,
    required this.guide,
    required this.child,
    this.decoration,
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

  /// Clip behavior applied to the bubble body content.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final SpotlightGuidePointer? pointer = guide.pointer;
    final TextDirection textDirection = Directionality.of(context);
    final Widget? pointerChild = pointer?._buildChild(
      context,
      _pointerContextFor(
        guide: guide,
        pointer: pointer,
        textDirection: textDirection,
      ),
    );
    return _BubbleHintLayout(
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

extension on SpotlightGuidePointer {
  Widget _buildChild(
    BuildContext context,
    SpotlightGuidePointerContext pointerContext,
  ) {
    return builder?.call(context, pointerContext, child) ?? child;
  }
}

SpotlightGuidePointerContext _pointerContextFor({
  required SpotlightGuideStepContext guide,
  required SpotlightGuidePointer pointer,
  required TextDirection textDirection,
}) {
  final SpotlightGuideBubbleSide bubbleSide =
      _resolvePointerBubbleSide(pointer, textDirection);
  final SpotlightGuideDirection bubbleAnchorDirection =
      _pointerBubbleAnchorDirection(guide.anchorDirection, bubbleSide);
  return SpotlightGuidePointerContext(
    guide: guide,
    textDirection: textDirection,
    targetDirection: guide.anchorDirection,
    bubbleDirection: _oppositeDirection(bubbleAnchorDirection),
    bubbleAnchorDirection: bubbleAnchorDirection,
    bubbleSide: bubbleSide,
    anchorMode: pointer.anchorMode,
  );
}

SpotlightGuideBubbleSide _resolvePointerBubbleSide(
  SpotlightGuidePointer pointer,
  TextDirection textDirection,
) {
  if (pointer.anchorMode != SpotlightGuidePointerAnchorMode.pointer) {
    return SpotlightGuideBubbleSide.along;
  }
  final SpotlightGuideBubbleSide placement =
      pointer.bubbleSide;
  return switch (placement) {
    SpotlightGuideBubbleSide.start => switch (textDirection) {
      TextDirection.ltr => SpotlightGuideBubbleSide.left,
      TextDirection.rtl => SpotlightGuideBubbleSide.right,
    },
    SpotlightGuideBubbleSide.end => switch (textDirection) {
      TextDirection.ltr => SpotlightGuideBubbleSide.right,
      TextDirection.rtl => SpotlightGuideBubbleSide.left,
    },
    SpotlightGuideBubbleSide.along ||
    SpotlightGuideBubbleSide.top ||
    SpotlightGuideBubbleSide.bottom ||
    SpotlightGuideBubbleSide.left ||
    SpotlightGuideBubbleSide.right => placement,
  };
}

SpotlightGuideDirection _pointerBubbleAnchorDirection(
  SpotlightGuideDirection targetDirection,
  SpotlightGuideBubbleSide bubbleSide,
) {
  return switch (bubbleSide) {
    SpotlightGuideBubbleSide.along => targetDirection,
    SpotlightGuideBubbleSide.top =>
      SpotlightGuideDirection.down,
    SpotlightGuideBubbleSide.bottom =>
      SpotlightGuideDirection.up,
    SpotlightGuideBubbleSide.left =>
      SpotlightGuideDirection.right,
    SpotlightGuideBubbleSide.right =>
      SpotlightGuideDirection.left,
    SpotlightGuideBubbleSide.start ||
    SpotlightGuideBubbleSide.end => throw StateError(
      'semantic placements must be resolved before pointer context',
    ),
  };
}

SpotlightGuideBubbleSide _resolvePointerLayoutBubbleSide({
  required SpotlightGuidePointer pointer,
  required TextDirection textDirection,
  required SpotlightGuideDirection targetDirection,
}) {
  final SpotlightGuideBubbleSide placement =
      _resolvePointerBubbleSide(pointer, textDirection);
  if (placement == SpotlightGuideBubbleSide.along) {
    return placement;
  }
  final SpotlightGuideDirection anchorDirection =
      _pointerBubbleAnchorDirection(targetDirection, placement);
  if (anchorDirection == targetDirection) {
    return SpotlightGuideBubbleSide.along;
  }
  return placement;
}

SpotlightGuideDirection _oppositeDirection(
  SpotlightGuideDirection direction,
) {
  return switch (direction) {
    SpotlightGuideDirection.up =>
      SpotlightGuideDirection.down,
    SpotlightGuideDirection.down =>
      SpotlightGuideDirection.up,
    SpotlightGuideDirection.left =>
      SpotlightGuideDirection.right,
    SpotlightGuideDirection.right =>
      SpotlightGuideDirection.left,
  };
}

class _BubbleHintLayout extends MultiChildRenderObjectWidget {
  const _BubbleHintLayout({
    required this.guide,
    required this.decoration,
    required this.pointer,
    required this.textDirection,
    required this.clipBehavior,
    required super.children,
  });

  final SpotlightGuideStepContext guide;
  final SpotlightGuideAnchoredDecoration decoration;
  final SpotlightGuidePointer? pointer;
  final TextDirection textDirection;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBubbleHint(
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
    covariant _RenderBubbleHint renderObject,
  ) {
    renderObject
      ..guide = guide
      ..decoration = decoration
      ..pointer = pointer
      ..textDirection = textDirection
      ..clipBehavior = clipBehavior;
  }
}

class _BubbleHintParentData
    extends ContainerBoxParentData<RenderBox> {}

class _RenderBubbleHint extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          _BubbleHintParentData
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _BubbleHintParentData
        >
    implements _HintLayoutParticipant {
  _RenderBubbleHint({
    required SpotlightGuideStepContext guide,
    required SpotlightGuideAnchoredDecoration decoration,
    required SpotlightGuidePointer? pointer,
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

  /// Applies geometry resolved by the overlay slot during the current layout.
  ///
  /// This keeps the built-in bubble renderer on the same final geometry as the
  /// public guide object without waiting for a post-frame rebuild.
  @override
  void useLayoutGuide(SpotlightGuideStepContext value) {
    _guide._absorbLayout(value);
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

  SpotlightGuidePointer? _pointer;

  set pointer(SpotlightGuidePointer? value) {
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
  Offset _layoutOffsetCorrection = Offset.zero;
  Rect _paintBounds = Rect.zero;
  bool _paintReady = true;

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
    if (child.parentData is! _BubbleHintParentData) {
      child.parentData = _BubbleHintParentData();
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
    _paintReady = _resolvePaintReadiness(pointerSize);
    _BubbleHintBubbleLayout bubbleLayout = _layoutBubble(
      _guide.anchorOffset,
      pointerSize: pointerSize,
    );
    double anchorOffset = _effectiveAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    bubbleLayout = _layoutBubble(anchorOffset, pointerSize: pointerSize);
    final double resolvedAnchorOffset = _effectiveAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    if ((resolvedAnchorOffset - anchorOffset).abs() > 0.01) {
      anchorOffset = resolvedAnchorOffset;
      bubbleLayout = _layoutBubble(anchorOffset, pointerSize: pointerSize);
    }

    final Offset bubbleOffset = _bubbleOffset(
      pointerSize: pointerSize,
      anchorOffset: anchorOffset,
      bubbleSize: bubbleLayout.size,
    );
    final Offset translation = _translationOffset(
      pointerSize: pointerSize,
      anchorOffset: anchorOffset,
      bubbleOffset: bubbleOffset,
      bubbleSize: bubbleLayout.size,
    );

    Offset bubblePaintOffset = translation + bubbleOffset;
    Rect layoutBounds = bubblePaintOffset & bubbleLayout.size;
    Rect paintBounds = layoutBounds;
    final RenderBox? pointer = _pointerChild;
    Offset pointerPaintOffset = Offset.zero;
    if (pointer != null && pointerSize != null) {
      final Offset pointerLayoutOffset =
          translation +
          Offset(
            _pointerLeft(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
            _pointerTop(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
          );
      pointerPaintOffset =
          pointerLayoutOffset +
          (_pointer?.visualOffset.resolve(_textDirection) ?? Offset.zero);
      layoutBounds = layoutBounds.expandToInclude(
        pointerLayoutOffset & pointerSize,
      );
      paintBounds = paintBounds.expandToInclude(
        pointerPaintOffset & pointerSize,
      );
    }

    final Offset contentShift = Offset(
      layoutBounds.left < 0 ? -layoutBounds.left : 0,
      layoutBounds.top < 0 ? -layoutBounds.top : 0,
    );
    _layoutOffsetCorrection = -contentShift;
    bubblePaintOffset += contentShift;
    if (pointer != null && pointerSize != null) {
      pointerPaintOffset += contentShift;
    }
    layoutBounds = layoutBounds.shift(contentShift);
    paintBounds = paintBounds.shift(contentShift);

    _bubblePaintOffset = bubblePaintOffset;
    final _BubbleHintParentData bubbleParentData =
        bubble.parentData! as _BubbleHintParentData;
    bubbleParentData.offset = _bubblePaintOffset;

    _pointerPaintOffset = pointerPaintOffset;
    if (pointer != null && pointerSize != null) {
      final _BubbleHintParentData pointerParentData =
          pointer.parentData! as _BubbleHintParentData;
      pointerParentData.offset = _pointerPaintOffset;
    }

    final Size requiredSize = Size(
      math.max(0, layoutBounds.right),
      math.max(0, layoutBounds.bottom),
    );
    size = constraints.constrain(requiredSize);
    _paintBounds = Rect.fromLTWH(
      math.min(0, paintBounds.left),
      math.min(0, paintBounds.top),
      math.max(size.width, paintBounds.right) - math.min(0, paintBounds.left),
      math.max(size.height, paintBounds.bottom) - math.min(0, paintBounds.top),
    );
  }

  Offset _bubbleOffset({
    required Size? pointerSize,
    required double anchorOffset,
    required Size bubbleSize,
  }) {
    if (!_pointerAffectsBubble || pointerSize == null) {
      return Offset.zero;
    }
    final SpotlightGuidePointer pointer = _pointer!;
    final SpotlightGuideBubbleSide placement =
        _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.bottom => Offset(
          0,
          pointerSize.height + _pointerAnchorGap,
        ),
        SpotlightGuideBubbleSide.right => Offset(
          pointerSize.width + _pointerAnchorGap,
          0,
        ),
        SpotlightGuideBubbleSide.top ||
        SpotlightGuideBubbleSide.left => Offset.zero,
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before bubble offset',
        ),
      };
    }
    final double leading = math.max(
      0,
      pointer.bubbleOffset ??
          switch (_guide.anchorDirection) {
            SpotlightGuideDirection.up =>
              pointerSize.height + _pointerAnchorGap,
            SpotlightGuideDirection.left =>
              pointerSize.width + _pointerAnchorGap,
            SpotlightGuideDirection.down ||
            SpotlightGuideDirection.right => 0,
          },
    );
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => Offset(0, leading),
      SpotlightGuideDirection.left => Offset(leading, 0),
      SpotlightGuideDirection.down ||
      SpotlightGuideDirection.right => Offset.zero,
    };
  }

  BoxConstraints _bubbleConstraints(Size? pointerSize) {
    final Size reserved = _reservedBubbleExtent(pointerSize);
    final BoxConstraints hintConstraints = _guide.hintConstraints;
    double minWidth = math.max(constraints.minWidth, hintConstraints.minWidth);
    double maxWidth = math.min(constraints.maxWidth, hintConstraints.maxWidth);
    double minHeight = math.max(
      constraints.minHeight,
      hintConstraints.minHeight,
    );
    double maxHeight = math.min(
      constraints.maxHeight,
      hintConstraints.maxHeight,
    );
    if (maxWidth.isFinite) {
      maxWidth = math.max(0, maxWidth - reserved.width);
      minWidth = math.min(minWidth, maxWidth);
    }
    if (maxHeight.isFinite) {
      maxHeight = math.max(0, maxHeight - reserved.height);
      minHeight = math.min(minHeight, maxHeight);
    }

    final double extent = _minimumBubbleAnchorSideExtent();
    if (extent.isFinite && extent > 0) {
      switch (_anchorDirection) {
        case SpotlightGuideDirection.up ||
            SpotlightGuideDirection.down:
          minWidth = math.max(minWidth, extent);
          if (maxWidth.isFinite) {
            minWidth = math.min(minWidth, maxWidth);
          }
        case SpotlightGuideDirection.left ||
            SpotlightGuideDirection.right:
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
      pointerSize.width + _pointerAnchorGap,
    );
    final double verticalAlongExtent = math.max(
      0,
      pointerSize.height + _pointerAnchorGap,
    );
    return switch (_layoutBubbleSide) {
      SpotlightGuideBubbleSide.along =>
        switch (_guide.anchorDirection) {
          SpotlightGuideDirection.up ||
          SpotlightGuideDirection.down => Size(0, verticalAlongExtent),
          SpotlightGuideDirection.left ||
          SpotlightGuideDirection.right => Size(
            horizontalAlongExtent,
            0,
          ),
        },
      SpotlightGuideBubbleSide.top ||
      SpotlightGuideBubbleSide.bottom => Size(
        0,
        math.max(0, pointerSize.height + _pointerAnchorGap),
      ),
      SpotlightGuideBubbleSide.left ||
      SpotlightGuideBubbleSide.right => Size(
        math.max(0, pointerSize.width + _pointerAnchorGap),
        0,
      ),
      SpotlightGuideBubbleSide.start ||
      SpotlightGuideBubbleSide.end => throw StateError(
        'semantic placements are resolved before bubble constraints',
      ),
    };
  }

  double _effectiveAnchorOffset({
    required Size? pointerSize,
    required Size bubbleSize,
  }) {
    final SpotlightGuideDirection anchorDirection = _anchorDirection;
    final bool isHorizontalSide =
        anchorDirection == SpotlightGuideDirection.up ||
        anchorDirection == SpotlightGuideDirection.down;
    final double measuredExtent = isHorizontalSide
        ? bubbleSize.width
        : bubbleSize.height;
    final double extent = math.max(
      measuredExtent,
      _minimumBubbleAnchorSideExtent(),
    );
    if (!extent.isFinite || extent <= 0) {
      return _guide.anchorOffset;
    }
    final double preferredOffset =
        _layoutBubbleSide ==
            SpotlightGuideBubbleSide.along
        ? _guide.anchorOffset
        : extent / 2;
    final double safeOffset = _HintLayout._resolveEffectiveAnchorOffset(
      preferredOffset,
      extent: extent,
      connectionHalfExtent: _guide.anchorConnectionHalfExtent,
      safeInset: _guide.anchorSafeInset,
    );
    return _resolveMarginSafeAnchorOffset(
      safeOffset,
      pointerSize: pointerSize,
      isHorizontalSide: isHorizontalSide,
      extent: extent,
    );
  }

  Offset _translationOffset({
    required Size? pointerSize,
    required double anchorOffset,
    required Offset bubbleOffset,
    required Size bubbleSize,
  }) {
    final Offset preferred = switch (guide.anchorDirection) {
      SpotlightGuideDirection.up ||
      SpotlightGuideDirection.down => Offset(
        _targetContactAxis(isHorizontalAxis: true) -
            guide.hintRect.left -
            _pointerAnchorX(
              pointerSize,
              anchorOffset,
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
                    anchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
      ),
      SpotlightGuideDirection.left ||
      SpotlightGuideDirection.right => Offset(
        _pointer == null || pointerSize == null
            ? 0
            : _pointerAffectsBubble
            ? _pointerTargetLeft(pointerSize) -
                  guide.hintRect.left -
                  _pointerLeft(
                    pointerSize,
                    anchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
        _targetContactAxis(isHorizontalAxis: false) -
            guide.hintRect.top -
            _pointerAnchorY(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleSize,
            ),
      ),
    };
    return _clampTranslationToHintRect(
      preferred,
      _contentBounds(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
    );
  }

  Rect _contentBounds(
    Size? pointerSize,
    double anchorOffset,
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
      _pointerLeft(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
      _pointerTop(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
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
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement =
        _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top ||
        SpotlightGuideBubbleSide.bottom =>
          bubbleOffset.dx +
              anchorOffset -
              _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
        SpotlightGuideBubbleSide.left =>
          bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
        SpotlightGuideBubbleSide.right => 0,
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before pointer left',
        ),
      };
    }
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up ||
      SpotlightGuideDirection.down =>
        anchorOffset -
            _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
      SpotlightGuideDirection.left => 0,
      SpotlightGuideDirection.right =>
        bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
    };
  }

  double _pointerTop(
    Size size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement =
        _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top =>
          bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
        SpotlightGuideBubbleSide.bottom => 0,
        SpotlightGuideBubbleSide.left ||
        SpotlightGuideBubbleSide.right =>
          bubbleOffset.dy +
              anchorOffset -
              _pointerBubbleOffset(
                isHorizontalAxis: false,
                extent: size.height,
              ),
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before pointer top',
        ),
      };
    }
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => 0,
      SpotlightGuideDirection.down =>
        bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
      SpotlightGuideDirection.left ||
      SpotlightGuideDirection.right =>
        anchorOffset -
            _pointerBubbleOffset(isHorizontalAxis: false, extent: size.height),
    };
  }

  SpotlightGuideStepContext get guide => _guide;

  bool get _pointerAffectsBubble {
    return _pointer?.anchorMode == SpotlightGuidePointerAnchorMode.pointer;
  }

  @override
  double? get targetLayoutGap {
    return _pointerAffectsBubble ? _pointerTargetGap : null;
  }

  @override
  Offset get layoutOffsetCorrection => _layoutOffsetCorrection;

  @override
  bool get isPaintReady => _paintReady;

  double get _pointerAnchorGap {
    return _finiteOrZero(_guide.gap);
  }

  double _pointerTargetLeft(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.left =>
        guide.targetRect.right + targetGap,
      SpotlightGuideDirection.right =>
        guide.targetRect.left - size.width - targetGap,
      SpotlightGuideDirection.up ||
      SpotlightGuideDirection.down => guide.targetRect.left,
    };
  }

  double _pointerTargetTop(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up =>
        guide.targetRect.bottom + targetGap,
      SpotlightGuideDirection.down =>
        guide.targetRect.top - size.height - targetGap,
      SpotlightGuideDirection.left ||
      SpotlightGuideDirection.right => guide.targetRect.top,
    };
  }

  double get _pointerTargetGap {
    return _finiteOrZero(_pointer?.targetGap ?? 0);
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

  double _resolveMarginSafeAnchorOffset(
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
      math.max(guide.anchorConnectionHalfExtent, guide.anchorSafeInset),
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
      switch (guide.anchorDirection) {
        SpotlightGuideDirection.up ||
        SpotlightGuideDirection.down =>
          guide.targetRect.center.dx - pointerTargetX + pointerBubbleX,
        SpotlightGuideDirection.left =>
          guide.targetRect.right + targetGap + pointerBubbleX,
        SpotlightGuideDirection.right =>
          guide.targetRect.left - targetGap - size.width + pointerBubbleX,
      },
      switch (guide.anchorDirection) {
        SpotlightGuideDirection.up =>
          guide.targetRect.bottom + targetGap + pointerBubbleY,
        SpotlightGuideDirection.down =>
          guide.targetRect.top - targetGap - size.height + pointerBubbleY,
        SpotlightGuideDirection.left ||
        SpotlightGuideDirection.right =>
          guide.targetRect.center.dy - pointerTargetY + pointerBubbleY,
      },
    );
  }

  SpotlightGuideBubbleSide get _layoutBubbleSide {
    final SpotlightGuidePointer? pointer = _pointer;
    if (pointer == null) {
      return SpotlightGuideBubbleSide.along;
    }
    return _resolvePointerLayoutBubbleSide(
      pointer: pointer,
      textDirection: _textDirection,
      targetDirection: _guide.anchorDirection,
    );
  }

  SpotlightGuideDirection get _anchorDirection {
    return switch (_layoutBubbleSide) {
      SpotlightGuideBubbleSide.along =>
        _guide.anchorDirection,
      SpotlightGuideBubbleSide.top =>
        SpotlightGuideDirection.down,
      SpotlightGuideBubbleSide.bottom =>
        SpotlightGuideDirection.up,
      SpotlightGuideBubbleSide.left =>
        SpotlightGuideDirection.right,
      SpotlightGuideBubbleSide.right =>
        SpotlightGuideDirection.left,
      SpotlightGuideBubbleSide.start ||
      SpotlightGuideBubbleSide.end => throw StateError(
        'semantic placements are resolved before anchor direction',
      ),
    };
  }

  double _pointerAnchorX(
    Size? size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return anchorOffset;
    }
    return _pointerLeft(size, anchorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: true, extent: size.width);
  }

  double _pointerAnchorY(
    Size? size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return anchorOffset;
    }
    return _pointerTop(size, anchorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: false, extent: size.height);
  }

  double _minimumBubbleAnchorSideExtent() {
    final bool sameAxis = _anchorDirection == _guide.anchorDirection;
    final double layoutExtent = sameAxis ? _guide.bubbleAnchorSideExtent : 0;
    final double safeExtent =
        math.max(_guide.anchorConnectionHalfExtent, _guide.anchorSafeInset) *
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
        : BoxConstraints.tight(_finiteSizeOrZero(fixedSize));
    pointer.layout(pointerConstraints, parentUsesSize: true);
    return pointer.size;
  }

  bool _resolvePaintReadiness(Size? pointerSize) {
    if (_pointerChild == null || _pointer == null || _pointer!.size != null) {
      return true;
    }
    if (pointerSize == null) {
      return true;
    }
    // Width-only images can report a transient zero height before decoding.
    return pointerSize.width.isFinite &&
        pointerSize.height.isFinite &&
        pointerSize.width > 0 &&
        pointerSize.height > 0;
  }

  _BubbleHintBubbleLayout _layoutBubble(
    double anchorOffset, {
    required Size? pointerSize,
  }) {
    final RenderBox bubble = _bubbleChild!;
    final SpotlightGuideAnchoredDecoration resolvedDecoration = _decoration
        .resolveAnchor(
          SpotlightGuideAnchorGeometry(
            direction: _anchorDirection,
            offset: anchorOffset,
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
    if (!_paintReady) {
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
    if (!_paintReady) {
      return false;
    }
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
    final _BubbleHintParentData childParentData =
        child.parentData! as _BubbleHintParentData;
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
