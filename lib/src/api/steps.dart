part of '../../spotlight_guide.dart';

/// Describes one hint bubble shown inside a [SpotlightGuideStep].
///
/// One step item means one [hintBuilder] result: a single bubble (and optional
/// [SpotlightGuideStepItem.pointer] image). A [SpotlightGuideStep] may contain
/// several items when the same step should show several bubbles at once.
///
/// **Choosing how many items to use**
///
/// - Use **one item with [targetId]** when one sentence points at one widget.
///   If several mounted [SpotlightGuideTarget] widgets share that id, they are
///   treated as one logical target group and placement uses the group's union
///   rect instead of choosing one instance. Set
///   [SpotlightGuideTarget.anchorId] on one instance when the group should stay
///   highlighted but one concrete instance should drive the bubble anchor.
/// - Use **one item with [targetIds]** when one sentence should light several
///   nearby related widgets together (for example a button plus its caption).
///   Every id in [targetIds] gets a spotlight hole, but the bubble anchor and
///   optional [SpotlightGuideStepItem.pointer] still form **one** pointing
///   chain. Set [anchorTargetId] to the id or
///   [SpotlightGuideTarget.anchorId] the hand or anchor should aim at; the
///   other ids are only co-highlighted. When no anchor is set, placement uses
///   the union rect of all targets, which works best when they are close
///   together.
/// - Use **several items in the same step** when each area needs its own copy or
///   its own pointer. For distant targets that should be explained one after
///   another, prefer multiple items plus [SpotlightGuideStep.autoScrollOptions]
///   instead of one item with widely separated [targetIds].
/// - This component does **not** draw multiple pointers for one item. To point
///   at two places with two hands, use two items or a fully custom [hintBuilder].
///
/// Use [targetKey] when the target is outside a convenient [SpotlightGuideTarget]
/// wrapper or when a [GlobalKey] already exists.
///
/// Before the hint is shown, the portal calls [onReveal] and then, by default,
/// calls [Scrollable.ensureVisible] for any available target contexts. This
/// means already-built offscreen targets are handled automatically. For lazy
/// list targets that do not exist yet, provide [onReveal] to scroll or load
/// until the target is built.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'more-button',
///   placement: SpotlightGuidePlacement.verticalAuto,
///   targetAnchorPosition: const SpotlightGuideAnchorPosition.end(8),
///   targetDecoration: const SpotlightGuideTargetDecoration(
///     padding: EdgeInsets.all(6),
///     shape: SpotlightGuideRoundedRectShape(
///       borderRadius: BorderRadius.all(Radius.circular(10)),
///     ),
///   ),
///   margin: const EdgeInsets.symmetric(horizontal: 12),
///   maxWidth: double.infinity,
///   decoration: const SpotlightGuideBubbleDecoration(
///     borderRadius: 8,
///     anchor: SpotlightGuideTriangleAnchor(
///       size: Size(24, 16),
///       tipArcAngle: math.pi / 6,
///     ),
///   ),
///   hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
///     return SpotlightGuideBubbleHint(
///       guide: guide,
///       child: TextButton(
///         onPressed: guide.next,
///         child: const Text('I know'),
///       ),
///     );
///   },
/// )
/// ```
class SpotlightGuideStepItem {
  const SpotlightGuideStepItem({
    required this.hintBuilder,
    this.key,
    this.targetId,
    this.targetIds,
    this.anchorTargetId,
    this.targetKey,
    this.onReveal,
    this.revealOptions,
    this.missingTargetBehavior,
    this.placement = SpotlightGuidePlacement.verticalAuto,
    this.targetAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.decoration = const SpotlightGuideBubbleDecoration(),
    this.pointer,
    this.targetDecoration = const SpotlightGuideTargetDecoration(),
    this.allowTargetInteraction = false,
    this.gap = 8,
    this.margin,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
  }) : assert(
         targetId == null || targetIds == null,
         'Use either targetId or targetIds for a spotlight guide item.',
       ),
       assert(
         targetKey == null || (targetId == null && targetIds == null),
         'Use either targetKey, targetId, or targetIds for a spotlight guide item.',
       ),
       assert(
         targetIds == null || targetIds.length > 0,
         'targetIds must not be empty.',
       ),
       assert(
         anchorTargetId == null || targetIds != null || targetId != null,
         'anchorTargetId requires targetId or targetIds.',
       );

  /// Builds this item's visual hint.
  ///
  /// The builder may return [SpotlightGuideBubbleHint],
  /// [SpotlightGuideBubble], an image-based hint, or any custom widget. Use
  /// [SpotlightGuidePaintGate] inside custom widgets when async visual content
  /// should delay the target hole and hint until the same stable frame.
  final SpotlightGuideHintBuilder hintBuilder;

  /// Optional stable label for analytics, copy lookup, or configuration.
  ///
  /// This is not related to [SpotlightGuideTarget.id]. It identifies the step
  /// item itself and is exposed through [SpotlightGuideAutoScrollDetails.key].
  final Object? key;

  /// Registered [SpotlightGuideTarget.id] values highlighted by this item.
  ///
  /// Empty when the item uses [targetKey] or highlights the whole portal child.
  List<Object> get highlightTargetIds {
    if (targetId != null) {
      return <Object>[targetId!];
    }
    if (targetIds != null) {
      return _uniqueObjects(targetIds!);
    }
    return const <Object>[];
  }

  /// A convenience id when [highlightTargetIds] is not empty.
  Object? get primaryTargetId {
    if (targetId != null) {
      return targetId;
    }
    if (anchorTargetId != null) {
      return anchorTargetId;
    }
    if (targetIds != null && targetIds!.isNotEmpty) {
      return targetIds!.first;
    }
    return null;
  }

  /// Whether this item highlights the whole [SpotlightGuidePortal.child].
  bool get highlightsWholePortalChild {
    return targetId == null && targetIds == null && targetKey == null;
  }

  /// Highlights one registered target for this single hint bubble.
  ///
  /// Mutually exclusive with [targetIds]. A target id may be referenced by
  /// multiple steps. If several active [SpotlightGuideTarget] widgets share the
  /// same id, their rects are treated as one target group and placement uses
  /// the union rect. The guide never chooses an arbitrary first/last instance;
  /// set [SpotlightGuideTarget.anchorId] on one concrete instance and pass that
  /// value to [anchorTargetId] while keeping the full group highlighted.
  final Object? targetId;

  /// Highlights several registered targets at once for this single hint bubble.
  ///
  /// The barrier opens one hole per id, but bubble placement, the anchor, and an
  /// optional [pointer] still use **one** anchor only.
  /// Prefer this when several widgets belong to the same message (label plus
  /// field, button plus helper text). Prefer multiple step items when each
  /// widget needs different copy or its own pointer.
  ///
  /// When [anchorTargetId] is set, the anchor and pointer aim at that id; other
  /// ids in the list stay lit without their own pointer. If that id has several
  /// mounted targets, those targets are treated as one anchor group. If the id
  /// is not one of the highlighted ids, the resolver looks for a highlighted
  /// [SpotlightGuideTarget.anchorId] with that value. When no anchor is set,
  /// the union rect of every listed target drives placement, which is usually
  /// awkward if the targets are far apart on screen.
  ///
  /// Mutually exclusive with [targetId].
  final List<Object>? targetIds;

  /// Chooses which [SpotlightGuideTarget.id] the bubble anchor and [pointer]
  /// align to.
  ///
  /// Usually one of the ids listed in [targetIds] (or [targetId] when only one
  /// id is highlighted). It may also match [SpotlightGuideTarget.anchorId] on a
  /// highlighted target when a repeated id group needs one concrete anchor.
  /// Other highlighted ids are not pointed at individually. If the chosen id is
  /// registered by multiple targets, the anchor uses that id's union rect
  /// instead of picking one target by mount order. When null and [targetIds]
  /// contains more than one id, placement falls back to the union rect of all
  /// targets.
  final Object? anchorTargetId;

  /// Directly points to a target widget by [GlobalKey].
  ///
  /// This is mutually exclusive with [targetId] and [targetIds].
  final GlobalKey? targetKey;

  /// Optional callback used to reveal this item's target before showing.
  ///
  /// Use this when the target may not be built yet. If the target is already
  /// built but simply outside a scrollable viewport, the default
  /// [Scrollable.ensureVisible] behavior is usually enough.
  final SpotlightGuideRevealCallback? onReveal;

  /// Reveal behavior for this item.
  ///
  /// When null, [SpotlightGuideStep.revealOptions] is used.
  final SpotlightGuideRevealOptions? revealOptions;

  /// How this item behaves when its target is missing after reveal preparation.
  ///
  /// Null means inherit from [SpotlightGuidePortal.missingTargetBehavior].
  /// Items that highlight the whole portal child never need this behavior
  /// because they do not depend on a registered target.
  final SpotlightGuideMissingTargetBehavior? missingTargetBehavior;

  /// Preferred side used to place this hint around the target.
  final SpotlightGuidePlacement placement;

  /// Anchor point used by the bubble anchor.
  ///
  /// Without a pointer, this resolves on the layout rect that the bubble anchor
  /// should point to. That rect is the [anchorTargetId] target or
  /// [SpotlightGuideTarget.anchorId] target when used, the [targetId] rect,
  /// the [targetKey] rect, or the union of all [targetIds] when no anchor is
  /// set. Repeated ids resolve as target groups, so this rect may also be a
  /// group's union rect. It is not applied separately to every highlighted id.
  ///
  /// When a [SpotlightGuideBubbleHint] pointer participates in the default
  /// pointer anchor chain, this resolves on the pointer instead. In that case
  /// [SpotlightGuidePointer.pointerAnchorPosition] controls where the
  /// pointer touches the target, while this value controls where the bubble
  /// anchor attaches to the pointer. For example, `center(4)` keeps the pointer
  /// contact stable and offsets the bubble anchor 4 logical pixels from the
  /// pointer center.
  ///
  /// For top/bottom placements this resolves on the horizontal axis. For
  /// left/right placements this resolves on the vertical axis.
  final SpotlightGuideAnchorPosition targetAnchorPosition;

  /// Decoration used by built-in hint widgets.
  ///
  /// The decoration owns bubble color, padding, border, radius, shadow and the
  /// preferred anchor size. [SpotlightGuideBubbleHint] uses this by default, but
  /// custom hint builders may ignore it or pass it to [SpotlightGuideBubble].
  final SpotlightGuideAnchoredDecoration decoration;

  /// Optional visual pointer used by built-in hint widgets.
  ///
  /// Keep pointer configuration here instead of inside the hint widget so the
  /// portal can reserve the target-to-pointer gap and pointer size before
  /// reveal scrolling, auto placement, and safe-area checks run.
  ///
  /// [SpotlightGuideBubbleHint] and [SpotlightGuideTextHint] use this pointer
  /// automatically through [SpotlightGuideStepContext.pointer]. A fully custom
  /// hint can also read that context field and compose the pointer manually.
  final SpotlightGuidePointer? pointer;

  /// Visual decoration for the spotlight target hole.
  ///
  /// The decoration owns the hole padding, shape and optional paint layers such
  /// as outer rings, glows, and shadows. It decorates the overlay hole only; it does not
  /// modify the real target widget.
  final SpotlightGuideTargetDecoration targetDecoration;

  /// Whether taps over this item's target pass through to the widget behind the
  /// guide.
  ///
  /// When false (the default), the barrier absorbs every tap so the page cannot
  /// be interacted with while the guide is visible. Set it to true when the
  /// onboarding step wants the user to actually press the highlighted control,
  /// such as "tap this button to continue".
  ///
  /// Only the raw target rect passes through; the surrounding
  /// [SpotlightGuideTargetDecoration.padding] band stays absorbed so a
  /// neighbouring control is not hit by accident.
  final bool allowTargetInteraction;

  /// Signed main-axis distance from the target to the first visual guide piece.
  ///
  /// When [pointer] participates in the anchor chain with
  /// [SpotlightGuidePointerAnchorMode.pointer], the pointer touches the target
  /// side and this is the pointer-to-bubble-anchor distance. Without such a
  /// pointer, this is the target-to-hint distance.
  ///
  /// The sign follows the final resolved placement, including auto and semantic
  /// placements. Positive values move the first guide piece away from the
  /// target: down for [SpotlightGuidePlacement.bottom], up for
  /// [SpotlightGuidePlacement.top], left for [SpotlightGuidePlacement.left],
  /// and right for [SpotlightGuidePlacement.right]. Negative values move it in
  /// the opposite direction, back toward or across the target.
  final double gap;

  /// Screen edge margin used by hint placement.
  ///
  /// [EdgeInsetsDirectional] is resolved with [Directionality].
  final EdgeInsetsGeometry? margin;

  /// Minimum hint width after [margin] and available space are considered.
  final double? minWidth;

  /// Minimum hint height after [margin] and available space are considered.
  final double? minHeight;

  /// Maximum hint width after [margin] and available space are considered.
  ///
  /// Set this to [double.infinity] to expand to the maximum available width.
  final double? maxWidth;

  /// Maximum hint height after [margin] and available space are considered.
  ///
  /// Set this to [double.infinity] to expand to the maximum available height.
  final double? maxHeight;
}

/// A single onboarding step.
///
/// A step contains one or more [SpotlightGuideStepItem]s. Items in the same
/// step are shown at the same time and share the same barrier style. Use
/// several [SpotlightGuideStep] objects when the guide should advance through
/// multiple moments with [SpotlightGuidePortalController.next].
///
/// [barrier] is merged over [SpotlightGuidePortal.barrier]. Leave a field null
/// to inherit the portal value, and set only the fields this step needs to
/// change.
///
/// For scrollable or paged content, use [onReveal] for work that affects the
/// whole step, such as switching tabs or jumping a lazy list close to the
/// target. Each item can still provide its own
/// [SpotlightGuideStepItem.onReveal] for item-specific work.
///
/// Example:
///
/// ```dart
/// final steps = <SpotlightGuideStep>[
///   SpotlightGuideStep.item(
///     SpotlightGuideStepItem(
///       targetId: 'search',
///       hintBuilder: buildSearchHint,
///     ),
///   ),
///   SpotlightGuideStep(
///     items: <SpotlightGuideStepItem>[
///       SpotlightGuideStepItem(
///         targetId: 'calendar',
///         hintBuilder: buildCalendarHint,
///       ),
///       SpotlightGuideStepItem(
///         targetId: 'add-button',
///         hintBuilder: buildAddHint,
///       ),
///     ],
///   ),
/// ];
/// ```
class SpotlightGuideStep {
  const SpotlightGuideStep({
    required this.items,
    this.onReveal,
    this.revealOptions = const SpotlightGuideRevealOptions(),
    this.autoScrollOptions = const SpotlightGuideAutoScrollOptions(),
    this.barrier = const SpotlightGuideBarrierStyle(),
  }) : assert(items.length > 0, 'items must not be empty.');

  SpotlightGuideStep.item(
    SpotlightGuideStepItem item, {
    this.onReveal,
    this.revealOptions = const SpotlightGuideRevealOptions(),
    this.autoScrollOptions = const SpotlightGuideAutoScrollOptions(),
    this.barrier = const SpotlightGuideBarrierStyle(),
  }) : items = <SpotlightGuideStepItem>[item];

  /// Hints displayed at the same step index.
  final List<SpotlightGuideStepItem> items;

  /// Optional callback used to reveal page state before item-level reveal.
  ///
  /// Typical uses are switching tabs, expanding a panel, or navigating to a
  /// section before individual item targets are handled.
  final SpotlightGuideRevealCallback? onReveal;

  /// Default reveal behavior inherited by items that do not provide their own
  /// [SpotlightGuideStepItem.revealOptions].
  final SpotlightGuideRevealOptions revealOptions;

  /// Automatic scroll behavior for later items in the same step.
  final SpotlightGuideAutoScrollOptions autoScrollOptions;

  /// Visual style of the full-screen step barrier.
  final SpotlightGuideBarrierStyle barrier;
}

/// Layout information passed to [SpotlightGuideHintBuilder].
///
/// This object is the bridge between the portal's positioning logic and custom
/// hint UI. It contains the current step index, item index, target rects,
/// resolved placement, anchor metrics, constraints-related measurements and the
/// active [SpotlightGuidePortalController].
///
/// Call [next], [finish] or [reset] from buttons inside the hint instead of
/// requiring every caller to keep an external controller.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'profile',
///   hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
///     return SpotlightGuideBubbleHint(
///       guide: guide,
///       child: Column(
///         mainAxisSize: MainAxisSize.min,
///         children: <Widget>[
///           const Text('This is your profile.'),
///           TextButton(onPressed: guide.next, child: const Text('Next')),
///         ],
///       ),
///     );
///   },
/// )
/// ```
class SpotlightGuideStepContext {
  SpotlightGuideStepContext({
    required this.index,
    required this.total,
    required this.itemIndex,
    required this.itemTotal,
    required this.targetRect,
    required this.targetRects,
    required this.stepTargetRects,
    required this.targetAnchorPoint,
    this.targetAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    required this.overlaySize,
    required this.hintRect,
    required this.hintConstraints,
    required this.margin,
    required this.placement,
    required this.anchorDirection,
    required this.anchorOffset,
    required this.anchorSafeInset,
    required this.bubbleAnchorSideExtent,
    required this.contentSize,
    required this.gap,
    required this.decoration,
    this.pointer,
    required this.anchorSize,
    required this.anchorConnectionHalfExtent,
    required this.controller,
  });

  /// Zero-based step index in the active guide sequence.
  int index;

  /// Total number of steps in the active guide sequence.
  int total;

  /// Zero-based item index inside the current [SpotlightGuideStep.items].
  int itemIndex;

  /// Total number of items in the current step.
  int itemTotal;

  /// Rect used for hint placement.
  ///
  /// For a single target this is that target. For
  /// [SpotlightGuideStepItem.targetIds] it is either
  /// [SpotlightGuideStepItem.anchorTargetId]'s rect, a highlighted
  /// [SpotlightGuideTarget.anchorId] rect, or the union of all target rects.
  Rect targetRect;

  /// All spotlight target rects kept visible by the overlay.
  List<Rect> targetRects;

  /// All target rects kept visible in the current step.
  List<Rect> stepTargetRects;

  /// Global overlay point where the pointer or visual anchor should aim.
  Offset targetAnchorPoint;

  /// Anchor position requested by the current step item.
  ///
  /// Built-in bubble hints use this to resolve the bubble anchor against the
  /// pointer when a pointer participates in the default anchor chain. Without a
  /// pointer, [targetAnchorPoint] already contains this position resolved
  /// against the target.
  SpotlightGuideAnchorPosition targetAnchorPosition;

  /// Size of the overlay used by the guide.
  Size overlaySize;

  /// Resolved hint rect in overlay coordinates.
  Rect hintRect;

  /// Resolved constraints intended for the hint body.
  ///
  /// Built-in bubble hints apply these constraints to the bubble body while
  /// still allowing visual pointer widgets to expand the overall interactive
  /// layout bounds.
  BoxConstraints hintConstraints;

  /// Resolved screen edge margin used by hint placement and safety checks.
  EdgeInsets margin;

  /// Final physical placement after resolving auto placement and semantic
  /// [SpotlightGuidePlacement.start]/[SpotlightGuidePlacement.end] options.
  SpotlightGuidePlacement placement;

  /// Physical direction used by the bubble anchor.
  SpotlightGuideDirection anchorDirection;

  /// Offset from the physical leading edge of the hint bubble's anchor side to
  /// the anchor tip.
  double anchorOffset;

  /// Minimum distance from the anchor tip center to either edge of the bubble
  /// side that owns the anchor.
  double anchorSafeInset;

  /// The resolved size of the hint bubble edge that owns the anchor.
  ///
  /// For up/down anchors this is the bubble width. For left/right anchors this
  /// is the bubble height. Safe-area expansion is included in this value.
  double bubbleAnchorSideExtent;

  /// The measured natural size of the hint content. When no measurement is
  /// available yet, this equals the current hint rect size.
  Size contentSize;

  /// Main-axis distance configured by [SpotlightGuideStepItem.gap].
  ///
  /// Built-in hint widgets treat this as the active anchor-chain distance:
  /// pointer to bubble anchor when a pointer participates in the chain, or
  /// target to hint when no such pointer exists.
  double gap;

  /// Decoration configured on the current [SpotlightGuideStepItem].
  SpotlightGuideAnchoredDecoration decoration;

  /// Pointer configured on the current [SpotlightGuideStepItem], if any.
  SpotlightGuidePointer? pointer;

  /// Preferred visual anchor size used by layout on the axis perpendicular to
  /// the bubble edge.
  Size anchorSize;

  /// Half of the range where the current visual anchor connects to the bubble.
  ///
  /// This can differ from [anchorSize]. A custom anchor may be visually wide
  /// while touching the bubble with a narrow connection range.
  double anchorConnectionHalfExtent;

  /// The active controller used by this guide. It is either user-provided or
  /// internally created by [SpotlightGuidePortal].
  SpotlightGuidePortalController controller;

  void _absorbLayout(SpotlightGuideStepContext other) {
    index = other.index;
    total = other.total;
    itemIndex = other.itemIndex;
    itemTotal = other.itemTotal;
    targetRect = other.targetRect;
    targetRects = other.targetRects;
    stepTargetRects = other.stepTargetRects;
    targetAnchorPoint = other.targetAnchorPoint;
    targetAnchorPosition = other.targetAnchorPosition;
    overlaySize = other.overlaySize;
    hintRect = other.hintRect;
    hintConstraints = other.hintConstraints;
    margin = other.margin;
    placement = other.placement;
    anchorDirection = other.anchorDirection;
    anchorOffset = other.anchorOffset;
    anchorSafeInset = other.anchorSafeInset;
    bubbleAnchorSideExtent = other.bubbleAnchorSideExtent;
    contentSize = other.contentSize;
    gap = other.gap;
    decoration = other.decoration;
    pointer = other.pointer;
    anchorSize = other.anchorSize;
    anchorConnectionHalfExtent = other.anchorConnectionHalfExtent;
    controller = other.controller;
  }

  bool get isFirst => index == 0;

  bool get isLast => index == total - 1;

  bool get isFirstItem => itemIndex == 0;

  bool get isLastItem => itemIndex == itemTotal - 1;

  void next() => controller.next();

  void previous() => controller.previous();

  void goTo(int index) => controller.goTo(index);

  void hide() => controller.hide();

  void finish() => controller.finish();

  void reset() => controller.reset();
}
