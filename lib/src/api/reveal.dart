part of '../../spotlight_guide.dart';

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
@immutable
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
@immutable
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
@immutable
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
@immutable
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
@immutable
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
@immutable
class SpotlightGuideAutoScrollOptions {
  const SpotlightGuideAutoScrollOptions({
    this.enabled = true,
    this.interval = const Duration(milliseconds: 800),
    this.skipVisibleItems = true,
    this.onItemChanged,
  });

  /// Whether later items in the same step may be revealed by automatic scroll.
  final bool enabled;

  /// Delay before moving from the currently visible item to the next hidden one.
  final Duration interval;

  /// When true, already fully visible targets are skipped.
  final bool skipVisibleItems;

  /// Notifies when sequential same-step scroll focuses a new item in the
  /// current step.
  ///
  /// With the default [skipVisibleItems] value, already fully visible later
  /// items are skipped, so this callback does not run when every item is
  /// already on screen. Set [skipVisibleItems] to false when each item should
  /// receive a timed focus callback even while already visible.
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
