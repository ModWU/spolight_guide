part of '../../spotlight_guide.dart';

/// Preferred side used to place a hint around its target.
///
/// [verticalAuto] is the default because most onboarding bubbles appear above
/// or below the target. Use [auto] when the hint may choose any side based on
/// available space, and [horizontalAuto] when the hint should only choose
/// between left and right.
///
/// [left] and [right] are physical screen sides. Use [start] and [end] when
/// the horizontal side should follow [Directionality], such as Arabic or Hebrew
/// UI where semantic start is physically right.
///
/// Auto placement is resolved against the full overlay visible area because
/// hints are rendered in that overlay. A target's nearest scrollable viewport
/// is used for reveal scrolling, not for choosing the hint side. The automatic
/// side with the largest usable directional space wins; after the hint is
/// measured, a side that can fit the measured hint is preferred.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'bottom-tab',
///   placement: SpotlightGuidePlacement.verticalAuto,
///   hintBuilder: buildHint,
/// )
/// ```
enum SpotlightGuidePlacement {
  /// Automatically choose from top, bottom, left and right.
  auto,

  /// Automatically choose between top and bottom only.
  verticalAuto,

  /// Automatically choose between physical left and right only.
  horizontalAuto,

  /// Place the hint above the target.
  top,

  /// Place the hint below the target.
  bottom,

  /// Place the hint on the physical left side of the target.
  left,

  /// Place the hint on the physical right side of the target.
  right,

  /// Place the hint on the semantic start side of the target.
  ///
  /// Resolves to [left] in LTR and [right] in RTL.
  start,

  /// Place the hint on the semantic end side of the target.
  ///
  /// Resolves to [right] in LTR and [left] in RTL.
  end,
}

/// Physical direction of the visual anchor drawn by a bubble.
///
/// This is resolved by [SpotlightGuidePlacement] and is intentionally not
/// mirrored by [TextDirection]. For example, a hint placed below a target uses
/// [up] in both LTR and RTL because the anchor points upward toward the target.
/// Use [SpotlightGuideAnchorPosition.start] and
/// [SpotlightGuideAnchorPosition.end] for direction-aware alignment along the
/// target or pointer axis.
enum SpotlightGuideDirection { up, down, left, right }

/// Semantic alignment used by [SpotlightGuideAnchorPosition].
///
/// [start] and [end] follow [Directionality] on horizontal axes. In RTL
/// layouts, [start] means the right edge and [end] means the left edge.
enum SpotlightGuideAnchorAlignment { center, start, end }

/// Base class for semantic positions resolved on a guide connection axis.
///
/// The resolved main axis is horizontal for top/bottom guide sides and
/// vertical for left/right guide sides. Horizontal axes follow
/// [Directionality]; vertical axes are physical. Concrete subclasses decide
/// whether the position is one-dimensional, as with
/// [SpotlightGuideAnchorPosition], or also has a cross-axis correction, as with
/// [SpotlightGuidePointPosition].
@immutable
abstract class SpotlightGuideAxisPosition {
  const SpotlightGuideAxisPosition(this.alignment, this.mainAxisOffset);

  /// Base alignment on the resolved main axis.
  final SpotlightGuideAnchorAlignment alignment;

  /// Signed offset applied along the resolved main axis of the referenced rect.
  ///
  /// [SpotlightGuideAnchorAlignment.center] offsets from the center. Positive
  /// values move toward semantic end on horizontal axes and down on vertical
  /// axes; negative values move the opposite way.
  ///
  /// [SpotlightGuideAnchorAlignment.start] and
  /// [SpotlightGuideAnchorAlignment.end] offset from their resolved edge. A
  /// positive value moves inward from that edge. A negative value moves outward
  /// beyond that edge.
  final double mainAxisOffset;
}

/// Describes an anchor connection point on a target, pointer, or bubble edge.
///
/// Use this value with fields that name the relationship being configured,
/// such as [SpotlightGuideStepItem.anchorTargetPosition],
/// [SpotlightGuidePointer.anchorPointerPosition]. The field name says which
/// two objects are being connected; this class only says which point to use.
///
/// This is intentionally one-dimensional. It moves the anchor point along the
/// resolved edge; it does not move the target or pointer widget itself. Use
/// [SpotlightGuidePointPosition] for the pointer-to-target relationship when a
/// custom pointer needs cross-axis correction.
///
/// [mainAxisOffset] moves along the main axis of the connection point:
///
/// * For top or bottom hints, the main axis is horizontal along the target,
///   pointer, or bubble edge. Positive `center(offset)` moves toward the
///   semantic end: right in LTR and left in RTL. `start(inset)` is from the
///   left edge in LTR and from the right edge in RTL. `end(inset)` is from the
///   opposite edge. Positive `start` and `end` values move inward; negative
///   values move outward beyond that edge.
/// * For left or right hints, the main axis is vertical along the target,
///   pointer, or bubble edge. Positive `center(offset)` moves down.
///   `start(inset)` means from the top edge, and `end(inset)` means from the
///   bottom edge. Positive `start` and `end` values move inward; negative
///   values move outward. RTL does not mirror vertical start and end.
///
/// Negative values are allowed. They can move the resolved point outside the
/// target or pointer when a custom composition needs that.
///
/// Example:
///
/// ```dart
/// // LTR: 10px from the left edge. RTL: 10px from the right edge.
/// const SpotlightGuideAnchorPosition.start(10);
///
/// // 8px from center on the resolved main axis.
/// const SpotlightGuideAnchorPosition.center(8);
///
/// // 10px inward from the end edge. Use -10 to move 10px outward instead.
/// const SpotlightGuideAnchorPosition.end(10);
/// ```
@immutable
class SpotlightGuideAnchorPosition extends SpotlightGuideAxisPosition {
  const SpotlightGuideAnchorPosition._(super.alignment, super.mainAxisOffset);

  const SpotlightGuideAnchorPosition.center([double mainAxisOffset = 0])
    : this._(SpotlightGuideAnchorAlignment.center, mainAxisOffset);

  const SpotlightGuideAnchorPosition.start([double mainAxisOffset = 0])
    : this._(SpotlightGuideAnchorAlignment.start, mainAxisOffset);

  const SpotlightGuideAnchorPosition.end([double mainAxisOffset = 0])
    : this._(SpotlightGuideAnchorAlignment.end, mainAxisOffset);
}

/// Describes a two-dimensional pointer position relative to a target.
///
/// This is used by [SpotlightGuidePointer.pointerTargetPosition], where the
/// pointer widget is positioned relative to the target. [mainAxisOffset] chooses
/// the point along the target side. The pointer's matching point is aligned to
/// that target point on the main axis: start to start, center to center, and
/// end to end. The same [mainAxisOffset] is not applied again to the pointer.
///
/// For example, `end(16)` chooses a target point 16px inward from the target's
/// end edge, then aligns the pointer's end edge to that point. `end(-16)`
/// chooses a target point 16px outward beyond the target's end edge, then still
/// aligns the pointer's end edge to that point.
///
/// [crossAxisOffset] moves the pointer on the axis perpendicular to that target
/// side; it does not move the bubble anchor.
///
/// Most pointers only need `center()`, `center(mainAxisOffset)`,
/// `start(inset)`, or `end(inset)`. Use the optional second value only when
/// the pointer itself should sit away from, toward, or slightly across the
/// target side.
///
/// Cross-axis signs are resolved from the final physical hint side:
///
/// * Positive [crossAxisOffset] moves the pointer away from the target in the
///   resolved placement direction: down for bottom hints, up for top hints,
///   right for right hints, and left for left hints.
/// * Negative [crossAxisOffset] moves the pointer back toward or across the
///   target. This is physical after [SpotlightGuidePlacement.start] and
///   [SpotlightGuidePlacement.end] resolve.
///
/// Example:
///
/// ```dart
/// // Common: pointer center is placed at the target center.
/// const SpotlightGuidePointPosition.center();
///
/// // 20px from target center on the resolved main axis.
/// const SpotlightGuidePointPosition.center(20);
///
/// // 20px on the target main axis and -8px on the target cross axis.
/// const SpotlightGuidePointPosition.center(20, -8);
///
/// // Pointer end edge aligns 12px inward from the target end edge.
/// const SpotlightGuidePointPosition.end(12);
/// ```
@immutable
class SpotlightGuidePointPosition extends SpotlightGuideAxisPosition {
  const SpotlightGuidePointPosition._(
    super.alignment,
    super.mainAxisOffset,
    this.crossAxisOffset,
  );

  const SpotlightGuidePointPosition.center([
    double mainAxisOffset = 0,
    double crossAxisOffset = 0,
  ]) : this._(
         SpotlightGuideAnchorAlignment.center,
         mainAxisOffset,
         crossAxisOffset,
       );

  const SpotlightGuidePointPosition.start([
    double mainAxisOffset = 0,
    double crossAxisOffset = 0,
  ]) : this._(
         SpotlightGuideAnchorAlignment.start,
         mainAxisOffset,
         crossAxisOffset,
       );

  const SpotlightGuidePointPosition.end([
    double mainAxisOffset = 0,
    double crossAxisOffset = 0,
  ]) : this._(
         SpotlightGuideAnchorAlignment.end,
         mainAxisOffset,
         crossAxisOffset,
       );

  /// Signed pointer offset on the axis perpendicular to [mainAxisOffset].
  ///
  /// This belongs to the pointer-to-target relationship only. It moves the
  /// pointer widget relative to the target and does not change where the bubble
  /// anchor connects to the pointer.
  final double crossAxisOffset;
}
