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
