part of '../../spotlight_guide.dart';

/// Builds the visual hint for one [SpotlightGuideStepItem].
///
/// The [guide] argument contains the resolved target rect, hint rect, anchor
/// direction, anchor offset and the active
/// [SpotlightGuidePortalController]. Most callers pass it directly to
/// [SpotlightGuideBubbleHint], but it can also be used to build a completely
/// custom hint UI. When custom hint content contains async image or animation
/// layout that should be ready before the target hole appears, wrap that
/// content with [SpotlightGuidePaintGate].
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'search-button',
///   hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
///     return SpotlightGuideBubbleHint(
///       guide: guide,
///       child: TextButton(
///         onPressed: guide.next,
///         child: const Text('Next'),
///       ),
///     );
///   },
/// )
/// ```
typedef SpotlightGuideHintBuilder =
    Widget Function(BuildContext context, SpotlightGuideStepContext guide);

/// Called before a step is shown.
///
/// Return a [Future] to wait for page scrolling, data loading, tab switching or
/// another transition before the overlay is painted. If the callback throws,
/// the error is reported through [FlutterError.reportError] and the step is not
/// shown.
///
/// Example:
///
/// ```dart
/// SpotlightGuidePortal(
///   onStepWillShow: (int index, SpotlightGuideStep step) async {
///     if (index == 1) {
///       await scrollController.animateTo(
///         300,
///         duration: const Duration(milliseconds: 250),
///         curve: Curves.easeOut,
///       );
///     }
///   },
///   steps: steps,
///   child: page,
/// )
/// ```
typedef SpotlightGuideStepWillShowCallback =
    FutureOr<void> Function(int index, SpotlightGuideStep step);

/// Called when the dim barrier is tapped.
///
/// The barrier absorbs taps everywhere except holes opened by
/// [SpotlightGuideStepItem.allowTargetInteraction]. This callback receives the
/// active controller so it can react without an external controller reference,
/// for example `onBarrierTap: (controller) => controller.next()` for
/// "tap anywhere to continue".
typedef SpotlightGuideBarrierTapCallback =
    void Function(SpotlightGuidePortalController controller);

/// Built-in behavior for taps on the dim barrier.
enum SpotlightGuideDismissBehavior {
  /// Barrier taps are absorbed and do not close the guide.
  disabled,

  /// Barrier taps finish the guide only after the flow is fully presented.
  ///
  /// This means the active step is the last step, preparation has settled, and
  /// same-step scroll has reached its final item when auto scroll is active.
  onComplete,

  /// Barrier taps finish the guide at any visible step.
  anytime,
}

/// Why [SpotlightGuidePortal.onStateChanged] fired.
enum SpotlightGuideStateChangeReason {
  /// A guide step became visible after preparation.
  shown,

  /// The guide was hidden.
  hidden,

  /// The configured portal steps changed while the guide was active.
  stepsChanged,

  /// A target registered or unregistered while the guide was active.
  targetsChanged,
}

/// Public state snapshot reported by [SpotlightGuidePortal.onStateChanged].
class SpotlightGuideStateDetails {
  const SpotlightGuideStateDetails({
    required this.reason,
    required this.controller,
    required this.isShowing,
    required this.index,
    required this.total,
    required this.resolvedItemCount,
    this.step,
  });

  /// Why this callback fired.
  final SpotlightGuideStateChangeReason reason;

  /// Active guide controller.
  final SpotlightGuidePortalController controller;

  /// Whether the guide is visible or preparing to become visible.
  final bool isShowing;

  /// Current active step index.
  final int index;

  /// Total number of steps in the active sequence.
  final int total;

  /// Current active step, if any.
  final SpotlightGuideStep? step;

  /// Number of items in [step] whose targets currently resolve.
  ///
  /// This can change when a [SpotlightGuideTarget] is inserted, removed, or
  /// toggled. It lets callers react to optional target availability without
  /// parsing widget geometry.
  final int resolvedItemCount;

  bool get isFirst => total > 0 && index == 0;

  bool get isLast => total > 0 && index == total - 1;

  bool get hasResolvedContent => resolvedItemCount > 0;
}

/// Called when guide visibility, active step, active step count, or target
/// resolution changes.
typedef SpotlightGuideStateCallback =
    void Function(SpotlightGuideStateDetails details);

/// Visual style for the full-screen barrier behind a guide step.
///
/// The barrier is step-level state because it describes the atmosphere around
/// all hints in that step. Target holes, hole padding, hole radius and target
/// interaction stay on [SpotlightGuideStepItem] because each highlighted widget
/// can need different treatment.
///
/// [blurSigma] is clipped to the dimmed barrier shape, so spotlight holes remain
/// sharp and keep the original target brightness/clarity.
///
/// Example:
///
/// ```dart
/// SpotlightGuidePortal(
///   barrier: const SpotlightGuideBarrierStyle(
///     color: Color(0x8C000000),
///     blurSigma: 4,
///   ),
///   steps: <SpotlightGuideStep>[
///     SpotlightGuideStep(
///       // Only color is overridden here; blurSigma is inherited from portal.
///       barrier: SpotlightGuideBarrierStyle(color: Colors.black54),
///       items: items,
///     ),
///   ],
///   child: page,
/// )
/// ```
class SpotlightGuideBarrierStyle {
  const SpotlightGuideBarrierStyle({this.color, this.blurSigma})
    : assert(
        blurSigma == null || blurSigma >= 0,
        'blurSigma must not be negative.',
      );

  /// Built-in fallback used before portal and step styles are merged.
  static const SpotlightGuideBarrierStyle fallback = SpotlightGuideBarrierStyle(
    color: Color(0x99000000),
    blurSigma: 0,
  );

  /// Color painted over the non-highlighted area.
  ///
  /// Null means inherit from the portal or built-in fallback.
  final Color? color;

  /// Background blur applied to the non-highlighted area.
  ///
  /// A value of zero disables blur. The blur is clipped with the same holes as
  /// [color], so highlighted targets are not blurred.
  /// Null means inherit from the portal or built-in fallback.
  final double? blurSigma;

  /// Resolved color after applying the built-in fallback.
  Color get effectiveColor => color ?? fallback.color!;

  /// Resolved blur sigma after applying the built-in fallback.
  double get effectiveBlurSigma {
    return _nonNegativeFiniteOrZero(blurSigma ?? fallback.blurSigma!);
  }

  bool get hasBlur => effectiveBlurSigma > 0;

  SpotlightGuideBarrierStyle copyWith({Color? color, double? blurSigma}) {
    return SpotlightGuideBarrierStyle(
      color: color ?? this.color,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  /// Returns this style with non-null fields from [other] replacing it.
  ///
  /// This mirrors the way [TextStyle.merge] is commonly used: portal style can
  /// define shared defaults, and a step style can override only the fields it
  /// needs.
  SpotlightGuideBarrierStyle merge(SpotlightGuideBarrierStyle? other) {
    if (other == null) {
      return this;
    }
    return SpotlightGuideBarrierStyle(
      color: other.color ?? color,
      blurSigma: other.blurSigma ?? blurSigma,
    );
  }

  /// Applies the built-in fallback so every field has an effective value.
  SpotlightGuideBarrierStyle resolve() {
    return fallback.merge(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideBarrierStyle &&
        other.color == color &&
        other.blurSigma == blurSigma;
  }

  @override
  int get hashCode => Object.hash(color, blurSigma);
}

/// Called before a step or item attempts its default reveal behavior.
///
/// Use this callback when the target may not exist yet, such as a
/// [ListView.builder] item below the currently built range, a target behind a
/// collapsed panel, or a target on another tab. The callback can scroll, switch
/// tabs, expand content or load data. After the callback completes, the portal
/// waits for layout and then attempts the default [Scrollable.ensureVisible]
/// behavior when [SpotlightGuideRevealOptions.enabled] is true.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'trade-row-20',
///   onReveal: (SpotlightGuideRevealContext context) async {
///     await itemScrollController.scrollTo(
///       index: 20,
///       duration: const Duration(milliseconds: 300),
///     );
///   },
///   hintBuilder: buildHint,
/// )
/// ```
typedef SpotlightGuideRevealCallback =
    FutureOr<void> Function(SpotlightGuideRevealContext context);

/// Default reveal behavior applied before a hint is shown.
///
/// The default value calls [Scrollable.ensureVisible] only when a target is not
/// fully visible. This handles the common case where a target is already built
/// but outside the viewport of a scrollable page without moving content that is
/// already comfortably visible.
///
/// Set [enabled] to false when [SpotlightGuideRevealCallback] fully controls
/// visibility or when the guide should never scroll automatically.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStepItem(
///   targetId: 'footer-button',
///   revealOptions: const SpotlightGuideRevealOptions(
///     alignment: 0.85,
///     duration: Duration(milliseconds: 350),
///     curve: Curves.easeOutCubic,
///   ),
///   hintBuilder: buildHint,
/// )
/// ```
class SpotlightGuideRevealOptions {
  const SpotlightGuideRevealOptions({
    this.enabled = true,
    this.scrollPolicy = SpotlightGuideRevealScrollPolicy.onlyIfNeeded,
    this.targetPolicy = SpotlightGuideRevealTargetPolicy.highlightedAreaIfFits,
    this.visibilityPadding = EdgeInsets.zero,
    this.alignment = 0.5,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    this.alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
  });

  /// Whether the portal should call [Scrollable.ensureVisible].
  final bool enabled;

  /// When automatic reveal scrolling should run.
  final SpotlightGuideRevealScrollPolicy scrollPolicy;

  /// Which highlighted area should drive reveal visibility and scrolling.
  final SpotlightGuideRevealTargetPolicy targetPolicy;

  /// Insets applied to the viewport before checking whether the target is
  /// already visible.
  ///
  /// Use this to keep a target away from sticky headers, bottom bars, or visual
  /// edges before deciding that no scroll is needed.
  final EdgeInsets visibilityPadding;

  /// Alignment passed to [Scrollable.ensureVisible].
  final double alignment;

  /// Animation duration passed to [Scrollable.ensureVisible].
  final Duration duration;

  /// Animation curve passed to [Scrollable.ensureVisible].
  final Curve curve;

  /// Alignment policy passed to [Scrollable.ensureVisible].
  final ScrollPositionAlignmentPolicy alignmentPolicy;
}

/// When [SpotlightGuideRevealOptions] should scroll a mounted target.
enum SpotlightGuideRevealScrollPolicy {
  /// Scroll only when the target is not fully inside the visible viewport.
  onlyIfNeeded,

  /// Always call [Scrollable.ensureVisible] and use the configured alignment.
  always,
}

/// Which part of a guide item should drive reveal scrolling.
enum SpotlightGuideRevealTargetPolicy {
  /// Use every resolved target context as the reveal subject.
  ///
  /// For [SpotlightGuideStepItem.targetIds], this preserves the highlighted
  /// area as the priority even when an [SpotlightGuideStepItem.anchorTargetId]
  /// is set.
  highlightedArea,

  /// Use [SpotlightGuideStepItem.anchorTargetId] as the reveal subject when it
  /// is available, otherwise fall back to [highlightedArea].
  anchorTarget,

  /// Use the highlighted area when it can fit in the viewport, otherwise use
  /// [SpotlightGuideStepItem.anchorTargetId] when it is available.
  ///
  /// This is the default because it keeps compact groups fully visible, but
  /// avoids moving the page just because a very large highlighted area cannot
  /// fully fit while its important anchor is already visible.
  highlightedAreaIfFits,
}

/// Why the guide is in a reveal transition.
///
/// A reveal transition is any moment where the portal is preparing target
/// geometry before presenting a hint, such as step startup, lazy-list
/// preparation, or same-step scroll.
enum SpotlightGuideRevealReason {
  /// The active step is preparing before its first visible hint is shown.
  stepPreparation,

  /// A later item in the same step is being revealed by same-step scroll.
  sameStepScroll,
}

/// How the overlay should render while a target is being revealed.
enum SpotlightGuideRevealMode {
  /// Keep the dim barrier but hide hint bubbles and spotlight holes until the
  /// reveal transition settles.
  barrierOnly,

  /// Keep rendering resolved hints and holes while target geometry moves.
  liveOverlay,
}

/// Information passed to [SpotlightGuideRevealStrategy].
class SpotlightGuideRevealDetails {
  const SpotlightGuideRevealDetails({
    required this.reason,
    required this.stepIndex,
    required this.total,
    required this.step,
    this.itemIndex,
    this.item,
  }) : assert(
         (item == null) == (itemIndex == null),
         'item and itemIndex must both be provided for item transitions.',
       );

  /// Why the overlay is in a reveal transition.
  final SpotlightGuideRevealReason reason;

  /// Index of the [SpotlightGuideStep] being prepared.
  final int stepIndex;

  /// Total number of steps in the active guide sequence.
  final int total;

  /// Step being prepared.
  final SpotlightGuideStep step;

  /// Item index being revealed, or null for step-level preparation.
  final int? itemIndex;

  /// Item being revealed, or null for step-level preparation.
  final SpotlightGuideStepItem? item;

  /// Whether this transition is for a concrete step item.
  bool get hasItem => item != null;

  /// Whether this transition is preparing the active step before the first hint.
  bool get isStepPreparation =>
      reason == SpotlightGuideRevealReason.stepPreparation;

  /// Whether this transition is same-step scroll moving to a later item.
  bool get isSameStepScroll =>
      reason == SpotlightGuideRevealReason.sameStepScroll;
}

/// Controls how hints and spotlight holes render while reveal scrolling runs.
///
/// The default strategy hides guide content during reveal transitions and shows
/// it only after scrolling/layout settles. This avoids detached hints during
/// animated scroll and works well for lazy targets that are built by
/// [SpotlightGuideStepItem.onReveal].
///
/// Extend this class to choose a different mode for selected transitions.
abstract class SpotlightGuideRevealStrategy {
  const SpotlightGuideRevealStrategy();

  SpotlightGuideRevealMode resolve(SpotlightGuideRevealDetails details);
}

/// Default reveal presentation: dim the page first, then show hints after
/// target preparation settles.
class SpotlightGuideDeferredReveal extends SpotlightGuideRevealStrategy {
  const SpotlightGuideDeferredReveal();

  @override
  SpotlightGuideRevealMode resolve(SpotlightGuideRevealDetails details) {
    return SpotlightGuideRevealMode.barrierOnly;
  }
}

/// Reveal presentation that keeps hints and holes live during target movement.
///
/// Use this when an app prefers the guide to visibly track animated scrolling
/// instead of waiting until the final target position is stable.
class SpotlightGuideLiveReveal extends SpotlightGuideRevealStrategy {
  const SpotlightGuideLiveReveal();

  @override
  SpotlightGuideRevealMode resolve(SpotlightGuideRevealDetails details) {
    return SpotlightGuideRevealMode.liveOverlay;
  }
}

/// Details for [SpotlightGuideAutoScrollCallback].
///
/// Use [itemIndex] and [itemTotal] for step copy such as "2 / 5". Use
/// [highlightTargetIds] when the focused item highlights one or more registered
/// target ids ([SpotlightGuideStepItem.targetId] or [SpotlightGuideStepItem.targetIds]).
/// Use [key] when the item defines a stable business label. When the item
/// highlights the whole portal child, [highlightTargetIds] is empty.
class SpotlightGuideAutoScrollDetails {
  const SpotlightGuideAutoScrollDetails({
    required this.stepIndex,
    required this.itemIndex,
    required this.itemTotal,
    required this.item,
  });

  /// Index of the [SpotlightGuideStep] that owns [item].
  final int stepIndex;

  /// Index of the focused item inside [SpotlightGuideStep.items].
  final int itemIndex;

  /// Total number of items in the step.
  final int itemTotal;

  /// The focused step item.
  final SpotlightGuideStepItem item;

  /// Optional stable key from [SpotlightGuideStepItem.key].
  Object? get key => item.key;

  /// Registered target ids currently highlighted by [item].
  List<Object> get highlightTargetIds => item.highlightTargetIds;

  /// A convenience id for analytics when [highlightTargetIds] is not empty.
  ///
  /// Returns [SpotlightGuideStepItem.targetId],
  /// [SpotlightGuideStepItem.anchorTargetId] (including a matched
  /// [SpotlightGuideTarget.anchorId]), or the first entry in
  /// [SpotlightGuideStepItem.targetIds].
  Object? get primaryTargetId => item.primaryTargetId;

  /// Whether [item] highlights the whole [SpotlightGuidePortal.child].
  bool get highlightsWholePortalChild => item.highlightsWholePortalChild;
}

/// Called when same-step scroll focuses a new item.
///
/// Fires only while sequential same-step scroll is active (a later item
/// is still hidden). The first item uses [SpotlightGuideAutoScrollDetails.itemIndex]
/// `0`. The callback does not repeat for the same index across overlay motion
/// refreshes.
typedef SpotlightGuideAutoScrollCallback =
    void Function(SpotlightGuideAutoScrollDetails details);

/// What to do when a targeted guide item cannot resolve its target.
///
/// The portal defaults to [skip], which keeps guide progress aligned with the
/// current widget tree. Use [wait] when the target may appear later without an
/// immediate reveal hook, such as content inserted after another state update.
enum SpotlightGuideMissingTargetBehavior {
  /// Keep the guide active and show the item once its target appears.
  wait,

  /// Skip unavailable API-driven targets.
  ///
  /// A step whose unresolved targets have no reveal path is removed from the
  /// active sequence. If an item or step has `onReveal`, the step is kept until
  /// reveal preparation runs so lazy targets can be built first.
  skip,
}

/// Automatic scrolling behavior for multiple items in the same step.
///
/// When a step contains several [SpotlightGuideStepItem]s, some targets may sit
/// outside the current viewport even though they belong to the same onboarding
/// moment. The default behavior keeps the first item visible when the step
/// opens, then waits for [interval] before scrolling to later items that are not
/// fully visible.
///
/// This is only a viewing aid. It does not change the current step index and it
/// is cancelled automatically when the guide advances, finishes or rebuilds with
/// different steps.
///
/// Example:
///
/// ```dart
/// SpotlightGuideStep(
///   autoScrollOptions: SpotlightGuideAutoScrollOptions(
///     interval: const Duration(milliseconds: 900),
///     onItemChanged: (SpotlightGuideAutoScrollDetails details) {
///       // Use details.itemIndex / details.itemTotal for copy.
///       // Use details.highlightTargetIds or details.key for analytics.
///     },
///   ),
///   items: items,
/// )
/// ```
class SpotlightGuideAutoScrollOptions {
  const SpotlightGuideAutoScrollOptions({
    this.enabled = true,
    this.interval = const Duration(milliseconds: 800),
    this.onlyWhenNeeded = true,
    this.onItemChanged,
  });

  /// Whether later items in the same step may be revealed by automatic scroll.
  final bool enabled;

  /// Delay before moving from the currently visible item to the next hidden one.
  final Duration interval;

  /// When true, already fully visible targets are skipped.
  final bool onlyWhenNeeded;

  /// Notifies when sequential same-step scroll focuses a new item in the current step.
  ///
  /// Not called when every item is already on screen (same-step scroll does not run).
  final SpotlightGuideAutoScrollCallback? onItemChanged;
}

/// Information passed to [SpotlightGuideRevealCallback].
///
/// [item] and [itemIndex] are null for a step-level reveal callback and non-null
/// for an item-level callback. [targetContexts] contains currently mounted
/// target contexts, if any. It can be empty when a lazy list item has not been
/// built yet.
///
/// Call [ensureVisible] from custom reveal code when the target exists but a
/// caller wants custom timing or alignment.
class SpotlightGuideRevealContext {
  const SpotlightGuideRevealContext({
    required this.context,
    required this.index,
    required this.step,
    required this.controller,
    required this.targetContexts,
    this.itemIndex,
    this.item,
  });

  /// Portal build context.
  final BuildContext context;

  /// Step index being prepared.
  final int index;

  /// Step being prepared.
  final SpotlightGuideStep step;

  /// Item index being prepared, or null for a step-level callback.
  final int? itemIndex;

  /// Item being prepared, or null for a step-level callback.
  final SpotlightGuideStepItem? item;

  /// Active portal controller.
  final SpotlightGuidePortalController controller;

  /// Currently mounted target contexts for this reveal scope.
  final List<BuildContext> targetContexts;

  /// Whether at least one target context is currently available.
  bool get hasTargetContext => targetContexts.isNotEmpty;

  /// Scrolls a [ScrollController] to an offset and waits for layout.
  ///
  /// Use this from [SpotlightGuideStep.onReveal] or
  /// [SpotlightGuideStepItem.onReveal] when a target is in a lazy scrollable and
  /// is not built yet. After this method returns, the portal resolves targets
  /// again and applies [SpotlightGuideRevealOptions] as a final visibility pass.
  Future<void> scrollToOffset({
    required ScrollController controller,
    required double offset,
    Duration duration = Duration.zero,
    Curve curve = Curves.easeInOut,
    bool clamp = true,
    int settleFrames = 1,
  }) async {
    await waitForLayout(frames: 1);
    if (!controller.hasClients) {
      return;
    }
    final ScrollPosition position = controller.position;
    double safeOffset = _finiteOrZero(offset);
    double targetOffset = clamp
        ? safeOffset
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble()
        : safeOffset;
    if (duration <= Duration.zero) {
      controller.jumpTo(targetOffset);
    } else {
      await controller.animateTo(
        targetOffset,
        duration: duration,
        curve: curve,
      );
    }
    await waitForLayout(frames: settleFrames);
  }

  /// Scrolls a fixed-extent lazy list so [index] can be built.
  ///
  /// [alignment] follows [Scrollable.ensureVisible] semantics: `0` places the
  /// item near the leading edge, `0.5` centers it when possible, and `1` places
  /// it near the trailing edge.
  Future<void> scrollToIndex({
    required ScrollController controller,
    required int index,
    required double itemExtent,
    double alignment = 0,
    Duration duration = Duration.zero,
    Curve curve = Curves.easeInOut,
    int settleFrames = 1,
  }) async {
    assert(index >= 0, 'index must not be negative.');
    assert(itemExtent > 0, 'itemExtent must be greater than zero.');
    assert(
      alignment >= 0 && alignment <= 1,
      'alignment must be between 0 and 1.',
    );
    await waitForLayout(frames: 1);
    if (index < 0 || itemExtent <= 0 || !itemExtent.isFinite) {
      return;
    }
    double viewportExtent = controller.hasClients
        ? controller.position.viewportDimension
        : 0;
    double safeAlignment = _finiteOrZero(alignment).clamp(0, 1).toDouble();
    double targetOffset =
        index * itemExtent -
        math.max(0, viewportExtent - itemExtent) * safeAlignment;
    await scrollToOffset(
      controller: controller,
      offset: targetOffset,
      duration: duration,
      curve: curve,
      settleFrames: settleFrames,
    );
  }

  /// Waits for one or more layout frames.
  Future<void> waitForLayout({int frames = 1}) async {
    assert(frames >= 0, 'frames must not be negative.');
    int safeFrames = math.max(0, frames);
    for (int i = 0; i < safeFrames; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Calls [Scrollable.ensureVisible] for every available target context.
  Future<void> ensureVisible({
    double alignment = 0.5,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
  }) async {
    for (final BuildContext targetContext in targetContexts) {
      if (!targetContext.mounted) {
        continue;
      }
      await Scrollable.ensureVisible(
        targetContext,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
      );
    }
  }
}

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

/// Semantic anchor used by [SpotlightGuideAnchorPosition].
///
/// [start] and [end] follow [Directionality] on horizontal axes. In RTL
/// layouts, [start] means the right edge and [end] means the left edge.
enum SpotlightGuideAnchor { center, start, end }

/// Describes where an anchor point should be resolved on one axis.
///
/// Use this for both the bubble-anchor relationship
/// ([SpotlightGuideStepItem.targetAnchorPosition]) and the pointer-to-target
/// contact relationship ([SpotlightGuidePointer.pointerAnchorPosition]).
///
/// The [offset] value is intentionally signed. For [center], a positive
/// horizontal offset moves toward the semantic end in LTR and toward the
/// semantic end in RTL after mirroring. For [start] and [end], the value is an
/// inset from that semantic edge. Negative values are allowed and may move the
/// anchor outside the target or pointer.
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
class SpotlightGuideAnchorPosition {
  const SpotlightGuideAnchorPosition._(this.anchor, this.offset);

  const SpotlightGuideAnchorPosition.center([double offset = 0])
    : this._(SpotlightGuideAnchor.center, offset);

  const SpotlightGuideAnchorPosition.start([double offset = 0])
    : this._(SpotlightGuideAnchor.start, offset);

  const SpotlightGuideAnchorPosition.end([double offset = 0])
    : this._(SpotlightGuideAnchor.end, offset);

  final SpotlightGuideAnchor anchor;

  /// Offset applied to the resolved anchor.
  ///
  /// [SpotlightGuideAnchor.start]/[SpotlightGuideAnchor.end] use this as an
  /// inset from the semantic edge. [SpotlightGuideAnchor.center] uses this as
  /// a signed offset from the center. On horizontal axes, semantic edges and
  /// positive center offsets follow [Directionality]. Negative values are
  /// allowed and can move the point outside the target/pointer bounds.
  final double offset;
}

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
