part of '../../spotlight_guide.dart';

/// Paint order used for [SpotlightGuideStepItem.pointer].
enum SpotlightGuidePointerPaintOrder {
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
      SpotlightGuideDirection.up => const SpotlightGuidePointerDirection.up(),
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
@immutable
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
@immutable
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
@immutable
class SpotlightGuidePointer {
  const SpotlightGuidePointer({
    required this.child,
    this.builder,
    this.size,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.targetGap = 0,
    this.paintOrder = SpotlightGuidePointerPaintOrder.belowBubble,
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
    this.paintOrder = SpotlightGuidePointerPaintOrder.belowBubble,
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
  final SpotlightGuidePointerPaintOrder paintOrder;

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
  final SpotlightGuideBubbleSide bubbleSide = _resolvePointerBubbleSide(
    pointer,
    textDirection,
  );
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
  final SpotlightGuideBubbleSide placement = pointer.bubbleSide;
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
    SpotlightGuideBubbleSide.top => SpotlightGuideDirection.down,
    SpotlightGuideBubbleSide.bottom => SpotlightGuideDirection.up,
    SpotlightGuideBubbleSide.left => SpotlightGuideDirection.right,
    SpotlightGuideBubbleSide.right => SpotlightGuideDirection.left,
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
  final SpotlightGuideBubbleSide placement = _resolvePointerBubbleSide(
    pointer,
    textDirection,
  );
  if (placement == SpotlightGuideBubbleSide.along) {
    return placement;
  }
  final SpotlightGuideDirection anchorDirection = _pointerBubbleAnchorDirection(
    targetDirection,
    placement,
  );
  if (anchorDirection == targetDirection) {
    return SpotlightGuideBubbleSide.along;
  }
  return placement;
}

SpotlightGuideDirection _oppositeDirection(SpotlightGuideDirection direction) {
  return switch (direction) {
    SpotlightGuideDirection.up => SpotlightGuideDirection.down,
    SpotlightGuideDirection.down => SpotlightGuideDirection.up,
    SpotlightGuideDirection.left => SpotlightGuideDirection.right,
    SpotlightGuideDirection.right => SpotlightGuideDirection.left,
  };
}
