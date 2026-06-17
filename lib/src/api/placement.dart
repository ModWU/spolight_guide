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

/// Describes where an anchor point should be resolved on one axis.
///
/// Use this for both the bubble-anchor relationship
/// ([SpotlightGuideStepItem.targetAnchorPosition]) and the pointer-to-target
/// contact relationship ([SpotlightGuidePointer.pointerAnchorPosition]).
///
/// The [offset] value is intentionally signed. With [center], a positive
/// horizontal offset moves toward semantic end after [Directionality] is
/// resolved; on a vertical axis, positive moves toward the physical bottom.
/// With [start] and [end], the value is an inset from that semantic edge.
/// Negative values are allowed and may move the anchor outside the target or
/// pointer.
///
/// Example:
///
/// ```dart
/// // LTR: 10px from the left edge. RTL: 10px from the right edge.
/// const SpotlightGuideAnchorPosition.start(10);
///
/// // 8px after center on the current semantic horizontal axis.
/// const SpotlightGuideAnchorPosition.center(8);
/// ```
@immutable
class SpotlightGuideAnchorPosition {
  const SpotlightGuideAnchorPosition._(this.anchor, this.offset);

  const SpotlightGuideAnchorPosition.center([double offset = 0])
    : this._(SpotlightGuideAnchorAlignment.center, offset);

  const SpotlightGuideAnchorPosition.start([double offset = 0])
    : this._(SpotlightGuideAnchorAlignment.start, offset);

  const SpotlightGuideAnchorPosition.end([double offset = 0])
    : this._(SpotlightGuideAnchorAlignment.end, offset);

  final SpotlightGuideAnchorAlignment anchor;

  /// Signed offset applied after the base anchor point is resolved.
  ///
  /// [SpotlightGuideAnchorAlignment.start] and
  /// [SpotlightGuideAnchorAlignment.end] use this as an inset from the semantic
  /// edge. [SpotlightGuideAnchorAlignment.center] uses this as a signed offset
  /// from the center. Horizontal axes follow [Directionality]; vertical axes
  /// are physical, where positive moves down. Negative values are allowed and
  /// can move the point outside the target or pointer bounds.
  final double offset;
}
