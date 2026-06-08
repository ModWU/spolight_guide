part of '../../spotlight_guide.dart';

/// Hosts a spotlight guide over [child].
///
/// Place one portal around the page or page section that owns the targets.
/// Wrap any interesting child widget with [SpotlightGuideTarget], then describe
/// the guide using [steps]. The portal paints a dim barrier, cuts holes for the
/// active targets, measures hints, resolves placement, and renders every hint
/// in the current step.
///
/// By default, when [controller] is omitted, the guide starts automatically once
/// [enabled] is true and steps are available. Use [autoStart] to override that
/// behavior. When a page needs to show steps after data loads or after a user
/// action, pass a [controller] and call
/// [SpotlightGuidePortalController.showSteps]. In hint buttons, use
/// [SpotlightGuideStepContext.next] and [SpotlightGuideStepContext.finish] so
/// callers do not need to thread the controller into every hint.
///
/// Before each step is painted, the portal waits for [onStepWillShow], then
/// step/item reveal callbacks, then the default [Scrollable.ensureVisible]
/// behavior. Simple scroll pages usually need no extra code; lazy lists,
/// collapsed sections and tabs can opt into reveal callbacks only where needed.
///
/// [barrier] provides the default background style for every step. A
/// [SpotlightGuideStep.barrier] can partially override it, similar to
/// [TextStyle.merge].
///
/// Example:
///
/// ```dart
/// SpotlightGuidePortal(
///   enabled: shouldShowGuide,
///   barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
///   steps: <SpotlightGuideStep>[
///     SpotlightGuideStep(
///       items: <SpotlightGuideStepItem>[
///         SpotlightGuideStepItem(
///           targetId: 'more',
///           hintBuilder: (context, guide) => SpotlightGuideBubbleHint(
///             guide: guide,
///             child: TextButton(
///               onPressed: guide.next,
///               child: const Text('I know'),
///             ),
///           ),
///         ),
///       ],
///     ),
///   ],
///   onFinish: () {
///     // Persist "guide has been seen" here.
///   },
///   child: Scaffold(
///     appBar: AppBar(
///       actions: <Widget>[
///         SpotlightGuideTarget(
///           id: 'more',
///           child: IconButton(
///             icon: const Icon(Icons.more_horiz),
///             onPressed: openMenu,
///           ),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
class SpotlightGuidePortal extends StatefulWidget {
  const SpotlightGuidePortal({
    super.key,
    required this.child,
    this.steps = const <SpotlightGuideStep>[],
    this.enabled = true,
    this.autoStart,
    this.missingTargetBehavior = SpotlightGuideMissingTargetBehavior.wait,
    this.controller,
    this.onStepWillShow,
    this.onStateChanged,
    this.onFinish,
    this.onBarrierTap,
    this.barrierDismissBehavior = SpotlightGuideBarrierDismissBehavior.disabled,
    this.barrier = const SpotlightGuideBarrierStyle(),
    this.blockInteractionDuringPreparation = true,
    this.revealPresentationStrategy =
        const SpotlightGuideDeferredRevealPresentationStrategy(),
  });

  /// Widget subtree that contains the guide targets.
  final Widget child;

  /// Ordered guide steps owned by the portal.
  ///
  /// These are the portal's default steps. Leave this empty when the page is
  /// fully driven by [SpotlightGuidePortalController.showSteps].
  final List<SpotlightGuideStep> steps;

  /// Whether the guide is allowed to show.
  ///
  /// Turning this off hides the guide without calling [onFinish].
  final bool enabled;

  /// Whether the portal should block page interaction while a guide step is
  /// preparing before the first hint and spotlight holes are ready.
  ///
  /// This is separate from [enabled]: [enabled] controls whether the guide is
  /// allowed to run, while this option controls the short startup/reveal window
  /// after the guide has started but before target geometry has settled. The
  /// default blocks interaction by showing the barrier-only overlay during
  /// preparation after route transitions settle. It does not keep blocking once
  /// preparation has finished and the guide is only waiting for a missing target
  /// to mount. Set this to false to preserve pass-through behavior until the
  /// visible guide overlay is ready.
  final bool blockInteractionDuringPreparation;

  /// Whether the guide starts automatically when [enabled] is true and steps
  /// are available.
  ///
  /// When null, portals without an external [controller] auto-start, and
  /// portals with an external controller wait for controller commands. Set this
  /// to true when a page wants both an external controller and automatic first
  /// display. Set it to false when the page should only show the guide from
  /// controller commands.
  final bool? autoStart;

  /// Default behavior for targeted items whose targets cannot be resolved.
  ///
  /// The default [SpotlightGuideMissingTargetBehavior.wait] keeps late-target
  /// behavior: the guide stays active and the hint appears when the target
  /// later mounts. Use [SpotlightGuideMissingTargetBehavior.skip] for
  /// API-driven guides where missing target ids should not leave a blank guide
  /// on screen. Individual items can override this through
  /// [SpotlightGuideStepItem.missingTargetBehavior].
  final SpotlightGuideMissingTargetBehavior missingTargetBehavior;

  /// Optional external controller.
  ///
  /// If omitted, the portal creates an internal controller. Automatic startup is
  /// controlled by [autoStart].
  final SpotlightGuidePortalController? controller;

  /// Optional hook called before a step is shown.
  final SpotlightGuideStepCallback? onStepWillShow;

  /// Called when visibility, active step metadata, or target availability
  /// changes while the guide is active.
  final SpotlightGuideStateCallback? onStateChanged;

  /// Called when the guide finishes normally through [next] on the last step
  /// or [SpotlightGuidePortalController.finish].
  final VoidCallback? onFinish;

  /// Optional callback invoked when the dim barrier is tapped.
  ///
  /// The barrier absorbs taps everywhere except holes opened by
  /// [SpotlightGuideStepItem.allowTargetInteraction]. When this callback is
  /// provided, a tap on the barrier additionally runs it. The callback receives
  /// the active controller (the external one if supplied, otherwise the portal's
  /// internal controller), so "tap anywhere to continue" works without an
  /// external controller: `onBarrierTap: (controller) => controller.next()`.
  /// When null, taps are still absorbed but nothing else happens.
  final SpotlightGuideBarrierTapCallback? onBarrierTap;

  /// Built-in behavior for taps on the dim barrier.
  ///
  /// Defaults to [SpotlightGuideBarrierDismissBehavior.disabled] so users cannot
  /// accidentally close an in-progress guide by tapping empty space. Use
  /// [SpotlightGuideBarrierDismissBehavior.onComplete] for flows that should be
  /// dismissible only after the last step or same-step item has been presented,
  /// or [SpotlightGuideBarrierDismissBehavior.anytime] when tapping outside
  /// should finish the guide even mid-flow.
  ///
  /// When [onBarrierTap] is provided, it takes precedence over this built-in
  /// dismissal behavior.
  final SpotlightGuideBarrierDismissBehavior barrierDismissBehavior;

  /// Default barrier style inherited by every step.
  ///
  /// A [SpotlightGuideStep.barrier] can override only the fields it needs. Any
  /// value left null falls back to this style, then to
  /// [SpotlightGuideBarrierStyle.fallback].
  final SpotlightGuideBarrierStyle barrier;

  /// How hints and spotlight holes render while reveal scrolling prepares a
  /// target.
  ///
  /// The default [SpotlightGuideDeferredRevealPresentationStrategy] keeps the
  /// dim barrier visible but hides hint content until reveal scrolling and
  /// layout have settled. Use [SpotlightGuideLiveRevealPresentationStrategy],
  /// or a custom [SpotlightGuideRevealPresentationStrategy], when an app wants
  /// a different transition effect.
  final SpotlightGuideRevealPresentationStrategy revealPresentationStrategy;

  @override
  State<SpotlightGuidePortal> createState() => _SpotlightGuidePortalState();
}

/// Coordinates controller state, target registration and overlay rendering.
class _SpotlightGuidePortalState extends State<SpotlightGuidePortal> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  late final SpotlightGuidePortalController _internalController =
      SpotlightGuidePortalController();
  int _index = 0;
  bool _preparing = false;
  bool _autoStarted = false;
  bool _targetRefreshScheduled = false;
  bool _overlayHidePending = false;
  bool _hasShownGuideContent = false;
  bool _waitingForRouteTransition = false;
  int _overlayMotionToken = 0;
  bool _autoScrollSequenceActive = false;
  bool _autoScrollPresentationActive = false;
  int? _autoScrollFocusedItemIndex;
  int? _autoScrollTransitionItemIndex;
  int? _autoScrollItemIndexNotified;
  int _autoScrollToken = 0;
  Timer? _autoScrollDelayTimer;
  Completer<void>? _autoScrollDelayCompleter;
  final Map<Object, Set<_SpotlightGuideTargetState>> _targets =
      <Object, Set<_SpotlightGuideTargetState>>{};
  late final _SpotlightGuideStepSource _stepSource;
  List<SpotlightGuideStep>? _targetFilteredSteps;

  List<SpotlightGuideStep> get _sourceSteps => _stepSource.steps;

  List<SpotlightGuideStep> get _steps => _targetFilteredSteps ?? _sourceSteps;

  List<SpotlightGuideStep>? get _runtimeSteps => _stepSource.runtimeSteps;

  _SpotlightGuideTargetResolver get _targetResolver =>
      _SpotlightGuideTargetResolver(portalContext: context, targets: _targets);

  _SpotlightGuideMissingTargetPolicy get _missingTargetPolicy =>
      _SpotlightGuideMissingTargetPolicy(
        portalBehavior: widget.missingTargetBehavior,
        targetResolver: _targetResolver,
      );

  _SpotlightGuideRevealScrollStrategy get _revealScrollStrategy =>
      _SpotlightGuideRevealScrollStrategy(
        targetResolver: _targetResolver,
        viewportRect: _overlayViewportRect,
      );

  int get _effectiveIndex {
    if (_steps.isEmpty) {
      return 0;
    }
    return _index.clamp(0, _steps.length - 1).toInt();
  }

  SpotlightGuideStep get _step => _steps[_effectiveIndex];

  SpotlightGuidePortalController get _controller =>
      widget.controller ?? _internalController;

  bool get _shouldAutoStart => widget.autoStart ?? widget.controller == null;

  @override
  void initState() {
    super.initState();
    _stepSource = _SpotlightGuideStepSource(portalSteps: widget.steps);
    _controller._attach(this);
    _maybeAutoStart();
  }

  @override
  void didUpdateWidget(covariant SpotlightGuidePortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<SpotlightGuideStep> previousSourceSteps = _sourceSteps;
    final SpotlightGuidePortalController oldController =
        oldWidget.controller ?? _internalController;
    final SpotlightGuidePortalController newController = _controller;
    if (oldController != newController) {
      newController._absorbFrom(oldController);
      oldController._detach(this);
      newController._attach(this);
      _autoStarted = false;
    }
    if (oldWidget.autoStart != widget.autoStart) {
      _autoStarted = false;
    }
    if (oldWidget.enabled != widget.enabled) {
      _autoStarted = false;
      if (!widget.enabled) {
        _hideGuide(notifyFinish: false);
      }
    }
    if (oldWidget.missingTargetBehavior != widget.missingTargetBehavior) {
      _clearTargetFilteredSteps();
      _scheduleTargetRefresh();
    }
    if (_stepSource.updatePortalSteps(widget.steps)) {
      _clearTargetFilteredSteps();
      if (_isGuideShowing &&
          _sameStepAvailabilitySignatures(previousSourceSteps, _sourceSteps)) {
        _refreshTargetFilteredStepsForAvailability();
        _index = _effectiveIndex;
        _controller._syncFromState(this);
        return;
      }
      _handleStepsChanged();
    }
    _maybeAutoStart();
  }

  @override
  void dispose() {
    _cancelAutoScroll();
    _stopOverlayMotionRefresh();
    _controller._detach(this);
    _targets.clear();
    super.dispose();
  }

  void _maybeAutoStart() {
    if (!_shouldAutoStart || _autoStarted || !_canShowGuide) {
      return;
    }
    _autoStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shouldAutoStart) {
        _controller.reset();
      }
    });
  }

  bool get _isGuideShowing => _overlayController.isShowing || _preparing;

  bool get _canShowGuide => widget.enabled && _steps.isNotEmpty;

  void _clearTargetFilteredSteps() {
    _targetFilteredSteps = null;
  }

  bool _sameStepAvailabilitySignatures(
    List<SpotlightGuideStep> a,
    List<SpotlightGuideStep> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!_sameStepAvailabilitySignature(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _sameStepAvailabilitySignature(
    SpotlightGuideStep a,
    SpotlightGuideStep b,
  ) {
    if (a.items.length != b.items.length ||
        (a.onReveal != null) != (b.onReveal != null)) {
      return false;
    }
    for (int i = 0; i < a.items.length; i++) {
      if (!_sameItemAvailabilitySignature(a.items[i], b.items[i])) {
        return false;
      }
    }
    return true;
  }

  bool _sameItemAvailabilitySignature(
    SpotlightGuideStepItem a,
    SpotlightGuideStepItem b,
  ) {
    return a.targetId == b.targetId &&
        a.targetKey == b.targetKey &&
        a.anchorTargetId == b.anchorTargetId &&
        a.missingTargetBehavior == b.missingTargetBehavior &&
        (a.onReveal != null) == (b.onReveal != null) &&
        _sameObjectList(a.targetIds, b.targetIds);
  }

  bool _sameObjectList(List<Object>? a, List<Object>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  _SpotlightGuideTargetFilterRefresh
  _refreshTargetFilteredStepsForAvailability() {
    final List<SpotlightGuideStep> previousSteps = _steps;
    final SpotlightGuideStep? previousStep = previousSteps.isEmpty
        ? null
        : previousSteps[_effectiveIndex];
    final List<SpotlightGuideStep> sourceSteps = _sourceSteps;
    final List<SpotlightGuideStep> filteredSteps = sourceSteps
        .where(_missingTargetPolicy.shouldKeepStepBeforeReveal)
        .toList(growable: false);
    final List<SpotlightGuideStep>? nextFilteredSteps =
        filteredSteps.length == sourceSteps.length
        ? null
        : List<SpotlightGuideStep>.unmodifiable(filteredSteps);
    final List<SpotlightGuideStep> nextSteps = nextFilteredSteps ?? sourceSteps;

    if (listEquals(previousSteps, nextSteps)) {
      _index = _effectiveIndex;
      return const _SpotlightGuideTargetFilterRefresh();
    }

    _targetFilteredSteps = nextFilteredSteps;
    if (nextSteps.isEmpty) {
      _index = 0;
    } else if (previousStep == null) {
      _index = _effectiveIndex;
    } else {
      final int preservedIndex = nextSteps.indexOf(previousStep);
      _index = preservedIndex >= 0 ? preservedIndex : _effectiveIndex;
    }

    final SpotlightGuideStep? nextStep = nextSteps.isEmpty
        ? null
        : nextSteps[_effectiveIndex];
    return _SpotlightGuideTargetFilterRefresh(
      changed: true,
      currentStepChanged: previousStep != nextStep,
    );
  }

  void _registerTarget(Object id, _SpotlightGuideTargetState target) {
    (_targets[id] ??= <_SpotlightGuideTargetState>{}).add(target);
    _scheduleTargetRefresh();
  }

  void _unregisterTarget(Object id, _SpotlightGuideTargetState target) {
    final Set<_SpotlightGuideTargetState>? targets = _targets[id];
    if (targets == null) {
      return;
    }
    if (targets.remove(target) && targets.isEmpty) {
      _targets.remove(id);
    }
    _scheduleTargetRefresh();
  }

  void _scheduleTargetRefresh() {
    if (!_isGuideShowing || _targetRefreshScheduled) {
      return;
    }
    _targetRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _targetRefreshScheduled = false;
      if (mounted && _isGuideShowing) {
        final _SpotlightGuideTargetFilterRefresh refresh =
            _refreshTargetFilteredStepsForAvailability();
        if (refresh.changed) {
          _cancelAutoScroll();
          _controller._syncFromState(this);
          if (!_canShowGuide) {
            _notifyStateChanged(SpotlightGuideStateChangeReason.targetsChanged);
            _hideGuide(notifyFinish: false);
            return;
          }
          setState(() {});
          _notifyStateChanged(SpotlightGuideStateChangeReason.targetsChanged);
          if (refresh.currentStepChanged) {
            _prepareAndShow(restart: true);
            return;
          }
          if (!_preparing && _shouldSkipCurrentStepForMissingTargets()) {
            _advancePastSkippedStep(_prepareToken);
            return;
          }
          return;
        }
        if (!_preparing && _shouldSkipCurrentStepForMissingTargets()) {
          _notifyStateChanged(SpotlightGuideStateChangeReason.targetsChanged);
          _advancePastSkippedStep(_prepareToken);
          return;
        }
        setState(() {});
        _notifyStateChanged(SpotlightGuideStateChangeReason.targetsChanged);
      }
    });
  }

  int _prepareToken = 0;

  Future<void> _prepareAndShow({bool restart = false}) async {
    if (restart) {
      _cancelAutoScroll();
      _stopOverlayMotionRefresh();
      _prepareToken++;
      _preparing = false;
      _waitingForRouteTransition = false;
    }
    final _SpotlightGuideTargetFilterRefresh initialRefresh =
        _refreshTargetFilteredStepsForAvailability();
    if (initialRefresh.changed) {
      _controller._syncFromState(this);
    }
    if (!_canShowGuide) {
      _hideGuide(notifyFinish: false);
      return;
    }
    if (_preparing) {
      return;
    }
    final int token = ++_prepareToken;
    _autoScrollItemIndexNotified = null;
    _configureAutoScrollPresentationForStep(_step);
    _preparing = true;
    _waitingForRouteTransition = _isRouteTransitionInProgress;
    _controller._syncFromState(this);
    if (!_waitingForRouteTransition) {
      _showPreparationOverlayIfNeeded(token);
    }
    try {
      await _waitForRouteTransitionToSettle(token);
      if (!_finishPrepareIfCancelled(token)) {
        return;
      }
      if (_waitingForRouteTransition) {
        _waitingForRouteTransition = false;
        setState(() {});
        _showPreparationOverlayIfNeeded(token);
      }
      if (widget.onStepWillShow != null) {
        await widget.onStepWillShow!.call(_effectiveIndex, _step);
        await _waitForEndOfFrame(token);
        if (!_finishPrepareIfCancelled(token)) {
          return;
        }
      }
      if (!_overlayController.isShowing &&
          widget.blockInteractionDuringPreparation) {
        setState(() {});
        _showOverlay(token: token);
      }
      final bool revealMayHaveChangedLayout = await _revealStepTargets(token);
      if (revealMayHaveChangedLayout) {
        await _waitForEndOfFrame(token);
      }
      if (!_finishPrepareIfCancelled(token)) {
        return;
      }
      final _SpotlightGuideTargetFilterRefresh revealRefresh =
          _refreshTargetFilteredStepsForAvailability();
      if (revealRefresh.changed) {
        _controller._syncFromState(this);
        if (!_canShowGuide) {
          _hideGuide(notifyFinish: false);
          return;
        }
        if (revealRefresh.currentStepChanged) {
          _prepareAndShow(restart: true);
          return;
        }
      }
      if (_shouldSkipCurrentStepForMissingTargets()) {
        _advancePastSkippedStep(token);
        return;
      }
    } catch (error, stackTrace) {
      if (mounted && token == _prepareToken) {
        _preparing = false;
        _waitingForRouteTransition = false;
        _hideOverlay();
        _controller._syncFromState(this);
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'spotlight_guide',
          context: ErrorDescription('while preparing a spotlight guide step'),
        ),
      );
      return;
    }
    if (!mounted || token != _prepareToken) {
      return;
    }
    _preparing = false;
    _waitingForRouteTransition = false;
    _hasShownGuideContent = true;
    setState(() {});
    _showOverlay(token: token);
    if (_hasActiveScrollAnimation()) {
      _startOverlayMotionRefresh();
    }
    _controller._syncFromState(this);
    _notifyStateChanged(SpotlightGuideStateChangeReason.shown);
    if (_isAutoScrollSequenceActive(_step)) {
      _notifyAutoScrollItemChanged(_step, 0);
    }
    _startStepItemAutoScroll(token);
  }

  Future<bool> _revealStepTargets(int token) async {
    if (!mounted || token != _prepareToken || !_canShowGuide) {
      return false;
    }
    bool mayHaveChangedLayout = false;
    final int stepIndex = _effectiveIndex;
    final SpotlightGuideStep step = _step;
    if (step.onReveal != null) {
      await step.onReveal!.call(
        SpotlightGuideRevealContext(
          context: context,
          index: stepIndex,
          step: step,
          controller: _controller,
          targetContexts: _targetResolver.contextsForStep(step),
        ),
      );
      mayHaveChangedLayout = true;
      await _waitForEndOfFrame(token);
    }

    for (int itemIndex = 0; itemIndex < step.items.length; itemIndex++) {
      if (!mounted || token != _prepareToken || !_canShowGuide) {
        return mayHaveChangedLayout;
      }
      final SpotlightGuideStepItem item = step.items[itemIndex];
      // Defer later items of an auto-scroll step, including their onReveal hook,
      // to auto-scroll time. This keeps the first hint on screen before the
      // guide scrolls on, and a lazy later target is only built when it is about
      // to be revealed instead of being scrolled away immediately.
      if (_shouldAutoScrollStepItems(step) && itemIndex > 0) {
        continue;
      }
      mayHaveChangedLayout =
          await _runItemReveal(step, item, itemIndex, stepIndex, token) ||
          mayHaveChangedLayout;

      final SpotlightGuideRevealOptions revealOptions =
          item.revealOptions ?? step.revealOptions;
      if (!revealOptions.enabled) {
        continue;
      }
      mayHaveChangedLayout =
          await _ensureItemVisible(item, revealOptions, token, stepIndex) ||
          mayHaveChangedLayout;
    }
    return mayHaveChangedLayout;
  }

  Future<bool> _runItemReveal(
    SpotlightGuideStep step,
    SpotlightGuideStepItem item,
    int itemIndex,
    int stepIndex,
    int token,
  ) async {
    if (item.onReveal == null) {
      return false;
    }
    await item.onReveal!.call(
      SpotlightGuideRevealContext(
        context: context,
        index: stepIndex,
        step: step,
        itemIndex: itemIndex,
        item: item,
        controller: _controller,
        targetContexts: _targetResolver.contextsForItem(item),
      ),
    );
    await _waitForEndOfFrame(token);
    return true;
  }

  bool _shouldAutoScrollStepItems(SpotlightGuideStep step) {
    return step.autoScrollOptions.enabled && step.items.length > 1;
  }

  void _configureAutoScrollPresentationForStep(SpotlightGuideStep step) {
    _autoScrollSequenceActive =
        _shouldAutoScrollStepItems(step) && _needsAutoScrollSequence(step);
    _autoScrollPresentationActive =
        _shouldAutoScrollStepItems(step) &&
        _needsFocusedAutoScrollPresentation(step);
    _autoScrollFocusedItemIndex = _autoScrollPresentationActive ? 0 : null;
  }

  bool _isAutoScrollSequenceActive(SpotlightGuideStep step) {
    return _autoScrollSequenceActive && _shouldAutoScrollStepItems(step);
  }

  bool _isAutoScrollPresentationActive(SpotlightGuideStep step) {
    return _autoScrollPresentationActive && _shouldAutoScrollStepItems(step);
  }

  bool _needsAutoScrollSequence(SpotlightGuideStep step) {
    if (_hasHiddenAutoScrollItem(step)) {
      return true;
    }
    return _itemNeedsReveal(step.items.first);
  }

  bool _needsFocusedAutoScrollPresentation(SpotlightGuideStep step) {
    final SpotlightGuideStepAutoScrollOptions options = step.autoScrollOptions;
    if (_itemNeedsReveal(step.items.first)) {
      return true;
    }
    for (int itemIndex = 1; itemIndex < step.items.length; itemIndex++) {
      final SpotlightGuideStepItem item = step.items[itemIndex];
      final List<BuildContext> targetContexts = _targetResolver.contextsForItem(
        item,
      );
      if (targetContexts.isEmpty) {
        if (item.onReveal != null) {
          return true;
        }
        continue;
      }
      if (!options.onlyWhenNeeded || !_isItemFullyVisible(item)) {
        return true;
      }
    }
    return false;
  }

  bool _itemNeedsReveal(SpotlightGuideStepItem item) {
    if (item.highlightsWholePortalChild) {
      return false;
    }
    final List<BuildContext> targetContexts = _targetResolver.contextsForItem(
      item,
    );
    if (targetContexts.isEmpty) {
      return item.onReveal != null;
    }
    return !_isItemFullyVisible(item);
  }

  void _notifyAutoScrollItemChanged(SpotlightGuideStep step, int itemIndex) {
    if (!_isAutoScrollSequenceActive(step)) {
      return;
    }
    final SpotlightGuideAutoScrollItemCallback? callback =
        step.autoScrollOptions.onAutoScrollItemChanged;
    if (callback == null || _autoScrollItemIndexNotified == itemIndex) {
      return;
    }
    _autoScrollItemIndexNotified = itemIndex;
    callback(
      SpotlightGuideAutoScrollItemContext(
        stepIndex: _effectiveIndex,
        itemIndex: itemIndex,
        itemTotal: step.items.length,
        item: step.items[itemIndex],
      ),
    );
  }

  void _startStepItemAutoScroll(int token) {
    final SpotlightGuideStep step = _step;
    if (!_isAutoScrollSequenceActive(step)) {
      return;
    }
    final int autoScrollToken = ++_autoScrollToken;
    unawaited(_autoScrollStepItems(token, _effectiveIndex, autoScrollToken));
  }

  void _cancelAutoScroll() {
    _autoScrollToken++;
    _autoScrollSequenceActive = false;
    _autoScrollPresentationActive = false;
    _autoScrollFocusedItemIndex = null;
    _autoScrollTransitionItemIndex = null;
    _autoScrollDelayTimer?.cancel();
    _autoScrollDelayTimer = null;
    final Completer<void>? completer = _autoScrollDelayCompleter;
    _autoScrollDelayCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitForAutoScrollInterval(
    Duration interval,
    int autoScrollToken,
  ) async {
    if (interval <= Duration.zero) {
      return;
    }
    final Completer<void> completer = Completer<void>();
    _autoScrollDelayCompleter = completer;
    _autoScrollDelayTimer = Timer(interval, () {
      _autoScrollDelayTimer = null;
      _autoScrollDelayCompleter = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future;
    if (!_isAutoScrollActive(autoScrollToken)) {
      return;
    }
  }

  bool _isAutoScrollActive(int autoScrollToken) {
    return mounted && autoScrollToken == _autoScrollToken;
  }

  bool _hasHiddenAutoScrollItem(SpotlightGuideStep step) {
    final SpotlightGuideStepAutoScrollOptions options = step.autoScrollOptions;
    for (int itemIndex = 1; itemIndex < step.items.length; itemIndex++) {
      final SpotlightGuideStepItem item = step.items[itemIndex];
      final List<BuildContext> targetContexts = _targetResolver.contextsForItem(
        item,
      );
      if (targetContexts.isEmpty) {
        // A not-yet-built target can still be reached if it has an onReveal
        // hook that scrolls or expands its container into view.
        if (item.onReveal != null) {
          return true;
        }
        continue;
      }
      if (!options.onlyWhenNeeded || !_isItemFullyVisible(item)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _autoScrollStepItems(
    int token,
    int stepIndex,
    int autoScrollToken,
  ) async {
    if (!_isSamePreparedStep(token, stepIndex) ||
        !_isAutoScrollActive(autoScrollToken)) {
      return;
    }
    final SpotlightGuideStepAutoScrollOptions options =
        _steps[stepIndex].autoScrollOptions;
    for (
      int itemIndex = 1;
      itemIndex < _steps[stepIndex].items.length;
      itemIndex++
    ) {
      if (!_isSamePreparedStep(token, stepIndex) ||
          !_isAutoScrollActive(autoScrollToken)) {
        return;
      }
      await _waitForAutoScrollInterval(options.interval, autoScrollToken);
      if (!_isSamePreparedStep(token, stepIndex) ||
          !_isAutoScrollActive(autoScrollToken)) {
        return;
      }
      final SpotlightGuideStep step = _steps[stepIndex];
      final SpotlightGuideStepItem item = step.items[itemIndex];
      _beginAutoScrollRevealTransition(step, item, itemIndex, stepIndex);
      // Run the deferred onReveal hook now (after the interval) so a lazy or
      // collapsed later target is brought into the tree just before it is
      // revealed, instead of during the initial step preparation.
      await _runItemReveal(step, item, itemIndex, stepIndex, token);
      if (!_isSamePreparedStep(token, stepIndex) ||
          !_isAutoScrollActive(autoScrollToken)) {
        return;
      }
      if (options.onlyWhenNeeded && _isItemFullyVisible(item)) {
        _focusAutoScrollItem(itemIndex);
        await _waitForEndOfFrame(token);
        _notifyAutoScrollItemChanged(step, itemIndex);
        continue;
      }
      final SpotlightGuideRevealOptions revealOptions =
          item.revealOptions ?? step.revealOptions;
      if (!revealOptions.enabled) {
        _focusAutoScrollItem(itemIndex);
        await _waitForEndOfFrame(token);
        _notifyAutoScrollItemChanged(step, itemIndex);
        continue;
      }
      await _ensureItemVisible(item, revealOptions, token, stepIndex);
      if (!_isSamePreparedStep(token, stepIndex) ||
          !_isAutoScrollActive(autoScrollToken)) {
        return;
      }
      _focusAutoScrollItem(itemIndex);
      await _waitForEndOfFrame(token);
      _notifyAutoScrollItemChanged(step, itemIndex);
    }
  }

  void _focusAutoScrollItem(int itemIndex) {
    if (!_autoScrollPresentationActive) {
      if (_autoScrollTransitionItemIndex == null) {
        return;
      }
      setState(() {
        _autoScrollTransitionItemIndex = null;
      });
      return;
    }
    if (_autoScrollFocusedItemIndex == itemIndex &&
        _autoScrollTransitionItemIndex == null) {
      return;
    }
    setState(() {
      _autoScrollFocusedItemIndex = itemIndex;
      _autoScrollTransitionItemIndex = null;
    });
  }

  void _beginAutoScrollRevealTransition(
    SpotlightGuideStep step,
    SpotlightGuideStepItem item,
    int itemIndex,
    int stepIndex,
  ) {
    final bool hideContent = _shouldHideRevealTransitionContent(
      reason: SpotlightGuideRevealPresentationReason.sameStepAutoScroll,
      step: step,
      stepIndex: stepIndex,
      total: _steps.length,
      item: item,
      itemIndex: itemIndex,
    );
    final bool shouldClearFocus =
        hideContent &&
        _autoScrollPresentationActive &&
        _autoScrollFocusedItemIndex != null;
    if (_autoScrollTransitionItemIndex == itemIndex && !shouldClearFocus) {
      return;
    }
    setState(() {
      _autoScrollTransitionItemIndex = itemIndex;
      if (hideContent) {
        _autoScrollFocusedItemIndex = null;
      }
    });
  }

  Future<bool> _ensureItemVisible(
    SpotlightGuideStepItem item,
    SpotlightGuideRevealOptions revealOptions,
    int token,
    int stepIndex,
  ) async {
    if (!_isSamePreparingStep(token, stepIndex)) {
      return false;
    }
    bool didScroll = false;
    final List<BuildContext> targetContexts = _revealScrollStrategy
        .revealContextsForItem(item, revealOptions);
    for (final BuildContext targetContext in targetContexts) {
      if (!_isSamePreparingStep(token, stepIndex)) {
        return didScroll;
      }
      if (!targetContext.mounted) {
        continue;
      }
      final bool scrolled = await _scrollTargetIntoView(
        targetContext,
        revealOptions,
      );
      didScroll = scrolled || didScroll;
      if (scrolled) {
        await _waitForEndOfFrame(token);
      }
    }
    return didScroll;
  }

  /// Reveals [targetContext] according to [revealOptions] and rebuilds the
  /// overlay each frame while animated scrolling runs so spotlight holes track
  /// moving targets.
  Future<bool> _scrollTargetIntoView(
    BuildContext targetContext,
    SpotlightGuideRevealOptions revealOptions,
  ) async {
    if (!targetContext.mounted) {
      return false;
    }
    if (!_revealScrollStrategy.shouldScrollTargetIntoView(
      targetContext,
      revealOptions,
    )) {
      return false;
    }
    final Duration duration = revealOptions.duration;
    if (duration > Duration.zero && _overlayController.isShowing) {
      _startOverlayMotionRefresh(expectedDuration: duration);
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: revealOptions.alignment,
      duration: duration,
      curve: revealOptions.curve,
      alignmentPolicy: revealOptions.alignmentPolicy,
    );
    return true;
  }

  void _startOverlayMotionRefresh({Duration? expectedDuration}) {
    _overlayMotionToken++;
    final int token = _overlayMotionToken;
    unawaited(_runOverlayMotionRefresh(token, expectedDuration));
  }

  void _stopOverlayMotionRefresh() {
    _overlayMotionToken++;
  }

  Future<void> _runOverlayMotionRefresh(
    int token,
    Duration? expectedDuration,
  ) async {
    const int stableFramesRequired = 2;
    const double rectTolerance = 0.5;
    int stableFrames = 0;
    Rect? previousSignature;
    final Duration maxWait =
        (expectedDuration ?? const Duration(milliseconds: 250)) +
        const Duration(milliseconds: 400);
    final Stopwatch stopwatch = Stopwatch()..start();

    while (mounted &&
        token == _overlayMotionToken &&
        _overlayController.isShowing) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted ||
          token != _overlayMotionToken ||
          !_overlayController.isShowing) {
        return;
      }

      final bool scrolling = _hasActiveScrollAnimation();
      final Rect? signature = _overlayMotionSignature();
      if (!scrolling &&
          signature != null &&
          previousSignature != null &&
          _rectsNearlyEqual(signature, previousSignature, rectTolerance)) {
        stableFrames++;
        if (stableFrames >= stableFramesRequired) {
          return;
        }
      } else {
        stableFrames = 0;
      }
      previousSignature = signature ?? previousSignature;

      setState(() {});

      if (stopwatch.elapsed > maxWait) {
        return;
      }
    }
  }

  Rect? _overlayMotionSignature() {
    if (!mounted) {
      return null;
    }
    Rect? union;
    for (final SpotlightGuideStepItem item in _step.items) {
      for (final BuildContext targetContext in _targetResolver.contextsForItem(
        item,
      )) {
        if (!targetContext.mounted) {
          continue;
        }
        final Rect? rect = _targetResolver.rectForContext(targetContext);
        if (rect == null) {
          continue;
        }
        union = union == null ? rect : union.expandToInclude(rect);
      }
    }
    return union;
  }

  bool _hasActiveScrollAnimation() {
    for (final SpotlightGuideStepItem item in _step.items) {
      for (final BuildContext targetContext in _targetResolver.contextsForItem(
        item,
      )) {
        if (!targetContext.mounted) {
          continue;
        }
        final ScrollPosition? position = Scrollable.maybeOf(
          targetContext,
        )?.position;
        if (position != null && position.isScrollingNotifier.value) {
          return true;
        }
      }
    }
    return false;
  }

  bool _rectsNearlyEqual(Rect a, Rect b, double tolerance) {
    return (a.left - b.left).abs() <= tolerance &&
        (a.top - b.top).abs() <= tolerance &&
        (a.right - b.right).abs() <= tolerance &&
        (a.bottom - b.bottom).abs() <= tolerance;
  }

  bool _isSamePreparedStep(int token, int stepIndex) {
    return _isSamePreparingStep(token, stepIndex) &&
        _overlayController.isShowing;
  }

  bool _isSamePreparingStep(int token, int stepIndex) {
    return mounted &&
        token == _prepareToken &&
        _canShowGuide &&
        _steps.isNotEmpty &&
        _effectiveIndex == stepIndex;
  }

  bool _isItemFullyVisible(SpotlightGuideStepItem item) {
    final Rect? viewport = _overlayViewportRect();
    if (viewport == null) {
      return false;
    }
    final List<BuildContext> targetContexts = _targetResolver.contextsForItem(
      item,
    );
    if (targetContexts.isEmpty) {
      return false;
    }
    for (final BuildContext targetContext in targetContexts) {
      final Rect? rect = _targetResolver.rectForContext(targetContext);
      if (rect == null || !_viewportContainsRect(viewport, rect)) {
        return false;
      }
    }
    return true;
  }

  /// Edge-inclusive containment test.
  ///
  /// [Rect.contains] excludes the right and bottom edges, so a target flush to
  /// the viewport's bottom or right edge would be treated as not fully visible.
  /// That triggered spurious same-step auto scroll and left a pending timer.
  bool _viewportContainsRect(Rect viewport, Rect rect) {
    const double tolerance = 0.5;
    return rect.left >= viewport.left - tolerance &&
        rect.top >= viewport.top - tolerance &&
        rect.right <= viewport.right + tolerance &&
        rect.bottom <= viewport.bottom + tolerance;
  }

  /// Whether [rect] overlaps the visible [viewport] by more than a hairline.
  ///
  /// Used to decide whether a same-step auto scroll item's hint should render:
  /// the hint stays hidden while its target is fully off-screen and appears once
  /// any part of the target scrolls into view.
  bool _viewportOverlapsRect(Rect viewport, Rect rect) {
    const double tolerance = 0.5;
    return rect.right > viewport.left + tolerance &&
        rect.left < viewport.right - tolerance &&
        rect.bottom > viewport.top + tolerance &&
        rect.top < viewport.bottom - tolerance;
  }

  Rect? _overlayViewportRect() {
    final RenderObject? overlayObject;
    try {
      overlayObject = Overlay.of(context).context.findRenderObject();
    } catch (_) {
      return null;
    }
    if (overlayObject is! RenderBox ||
        !overlayObject.attached ||
        !overlayObject.hasSize) {
      return null;
    }
    return Offset.zero & overlayObject.size;
  }

  /// Hides the overlay safely.
  ///
  /// [OverlayPortalController.hide] cannot be called during the build/layout
  /// phase. When the guide is hidden from inside [didUpdateWidget] (for example
  /// when `enabled` is toggled off or the steps become empty), the hide is
  /// deferred to the end of the current frame. The build method already guards
  /// with [_canShowGuide], so the hint is not painted while the hide is pending.
  void _hideOverlay() {
    if (!_overlayController.isShowing) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_overlayHidePending) {
        return;
      }
      _overlayHidePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayHidePending = false;
        if (mounted && _overlayController.isShowing) {
          _overlayController.hide();
        }
      });
      return;
    }
    _overlayController.hide();
  }

  void _showPreparationOverlayIfNeeded(int token) {
    if (!widget.blockInteractionDuringPreparation ||
        _overlayController.isShowing ||
        !_canShowGuide) {
      return;
    }
    setState(() {});
    _showOverlay(token: token);
  }

  void _showOverlay({int? token}) {
    if (_overlayController.isShowing) {
      return;
    }
    if (!_canShowOverlayForToken(token)) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_overlayController.isShowing &&
            _canShowOverlayForToken(token)) {
          _overlayController.show();
        }
      });
      return;
    }
    _overlayController.show();
  }

  bool _canShowOverlayForToken(int? token) {
    if (!_canShowGuide) {
      return false;
    }
    if (token != null && token != _prepareToken) {
      return false;
    }
    return _preparing || _hasShownGuideContent;
  }

  Future<void> _waitForEndOfFrame(int token) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _prepareToken) {
      return;
    }
  }

  bool get _isRouteTransitionInProgress {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final Animation<double>? animation = route?.animation;
    return route != null &&
        animation != null &&
        animation.status == AnimationStatus.forward &&
        animation.value < 1;
  }

  Future<void> _waitForRouteTransitionToSettle(int token) async {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final Animation<double>? animation = route?.animation;
    if (route == null ||
        animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status != AnimationStatus.forward ||
        animation.value >= 1) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    late AnimationStatusListener listener;
    listener = (AnimationStatus status) {
      if (status == AnimationStatus.completed && !completer.isCompleted) {
        completer.complete();
      }
    };
    animation.addStatusListener(listener);
    try {
      if (animation.status != AnimationStatus.completed &&
          animation.value < 1 &&
          mounted &&
          token == _prepareToken) {
        await completer.future;
      }
    } finally {
      animation.removeStatusListener(listener);
    }
    if (mounted && token == _prepareToken) {
      await _waitForEndOfFrame(token);
    }
  }

  /// Returns false when preparation was cancelled (for example by [finish]).
  bool _finishPrepareIfCancelled(int token) {
    if (mounted && token == _prepareToken) {
      return true;
    }
    _preparing = false;
    _waitingForRouteTransition = false;
    _hideOverlay();
    _controller._syncFromState(this);
    return false;
  }

  void _next() {
    if (!_canShowGuide) {
      _hideGuide(notifyFinish: false);
      return;
    }
    final int currentIndex = _effectiveIndex;
    if (currentIndex >= _steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index = currentIndex + 1;
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: true);
  }

  void _controllerNext() {
    if (!_isGuideShowing) {
      _prepareAndShow();
      return;
    }
    _next();
  }

  void _controllerPrevious() {
    if (!_isGuideShowing) {
      _prepareAndShow();
      return;
    }
    _previous();
  }

  void _previous() {
    if (!_canShowGuide) {
      _hideGuide(notifyFinish: false);
      return;
    }
    final int currentIndex = _effectiveIndex;
    if (currentIndex <= 0) {
      return;
    }
    setState(() {
      _index = currentIndex - 1;
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: true);
  }

  void _controllerGoTo(int index) {
    if (!_canShowGuide) {
      _hideGuide(notifyFinish: false);
      return;
    }
    final int target = index.clamp(0, _steps.length - 1).toInt();
    final bool wasShowing = _isGuideShowing;
    if (wasShowing && _effectiveIndex == target) {
      return;
    }
    setState(() {
      _index = target;
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: wasShowing);
  }

  void _reset() {
    _clearTargetFilteredSteps();
    if (!_canShowGuide) {
      _hideGuide(notifyFinish: false);
      return;
    }
    _cancelAutoScroll();
    _prepareToken++;
    _preparing = false;
    _waitingForRouteTransition = false;
    _hasShownGuideContent = false;
    _hideOverlay();
    setState(() {
      _index = 0;
    });
    _controller._syncFromState(this);
    _prepareAndShow();
  }

  int _resolvedItemCountForStep(SpotlightGuideStep? step) {
    if (step == null || !_canShowGuide) {
      return 0;
    }
    return _targetResolver.resolvedItemCountForStep(step, Rect.zero);
  }

  void _notifyStateChanged(SpotlightGuideStateChangeReason reason) {
    final SpotlightGuideStateCallback? callback = widget.onStateChanged;
    if (callback == null) {
      return;
    }
    final bool hasSteps = _steps.isNotEmpty;
    final SpotlightGuideStep? step = hasSteps ? _step : null;
    callback(
      SpotlightGuideStateContext(
        reason: reason,
        controller: _controller,
        isShowing: _isGuideShowing,
        index: hasSteps ? _effectiveIndex : 0,
        total: _steps.length,
        step: step,
        resolvedItemCount: _resolvedItemCountForStep(step),
      ),
    );
  }

  bool _shouldSkipCurrentStepForMissingTargets() {
    if (!_canShowGuide) {
      return false;
    }
    return _missingTargetPolicy.shouldSkipStep(_step);
  }

  void _advancePastSkippedStep(int token) {
    if (!mounted || token != _prepareToken || !_canShowGuide) {
      return;
    }
    final int currentIndex = _effectiveIndex;
    if (currentIndex >= _steps.length - 1) {
      _hideGuide(notifyFinish: _hasShownGuideContent);
      return;
    }
    setState(() {
      _index = currentIndex + 1;
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: true);
  }

  void _showRuntimeSteps(List<SpotlightGuideStep> steps, int index) {
    _clearTargetFilteredSteps();
    if (steps.isEmpty) {
      _stepSource.usePortalSteps();
      _index = 0;
      _hideGuide(notifyFinish: false);
      _controller._syncFromState(this);
      return;
    }

    if (!widget.enabled) {
      _stepSource.useRuntimeSteps(steps);
      _index = index.clamp(0, steps.length - 1).toInt();
      _hideGuide(notifyFinish: false);
      _controller._syncFromState(this);
      return;
    }

    final bool wasShowing = _isGuideShowing;
    setState(() {
      _hasShownGuideContent = false;
      _stepSource.useRuntimeSteps(steps);
      _index = index.clamp(0, steps.length - 1).toInt();
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: wasShowing);
  }

  void _showPortalSteps(int index) {
    _clearTargetFilteredSteps();
    final List<SpotlightGuideStep> portalSteps = _stepSource.portalSteps;
    if (portalSteps.isEmpty || !widget.enabled) {
      _stepSource.usePortalSteps();
      _index = 0;
      _hideGuide(notifyFinish: false);
      _controller._syncFromState(this);
      return;
    }

    final bool wasShowing = _isGuideShowing;
    setState(() {
      _hasShownGuideContent = false;
      _stepSource.usePortalSteps();
      _index = index.clamp(0, portalSteps.length - 1).toInt();
    });
    _controller._syncFromState(this);
    _prepareAndShow(restart: wasShowing);
  }

  void _finish() {
    _hideGuide(notifyFinish: true);
  }

  void _hideGuide({required bool notifyFinish}) {
    if (!_isGuideShowing) {
      _controller._syncFromState(this);
      return;
    }
    _cancelAutoScroll();
    _stopOverlayMotionRefresh();
    _autoScrollItemIndexNotified = null;
    _autoScrollSequenceActive = false;
    _autoScrollPresentationActive = false;
    _autoScrollFocusedItemIndex = null;
    _autoScrollTransitionItemIndex = null;
    _prepareToken++;
    _preparing = false;
    _waitingForRouteTransition = false;
    _hideOverlay();
    _controller._syncFromState(this);
    if (notifyFinish) {
      widget.onFinish?.call();
    }
    _notifyStateChanged(SpotlightGuideStateChangeReason.hidden);
    _hasShownGuideContent = false;
  }

  void _handleStepsChanged() {
    final bool wasActive = _isGuideShowing;
    _cancelAutoScroll();
    _stopOverlayMotionRefresh();
    _prepareToken++;
    _preparing = false;
    _waitingForRouteTransition = false;

    if (_steps.isEmpty) {
      _hideOverlay();
      _index = 0;
      _controller._syncFromState(this);
      _autoStarted = false;
      _notifyStateChanged(SpotlightGuideStateChangeReason.stepsChanged);
      if (wasActive) {
        widget.onFinish?.call();
      }
      return;
    }

    if (!widget.enabled) {
      _index = _effectiveIndex;
      _controller._syncFromState(this);
      _autoStarted = false;
      return;
    }

    _index = _effectiveIndex;
    _controller._syncFromState(this);

    if (!wasActive) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _steps.isEmpty) {
        return;
      }
      _prepareAndShow(restart: true);
    });
  }

  void _applyControllerSnapshot(SpotlightGuidePortalController controller) {
    if (controller._steps == null) {
      _stepSource.usePortalSteps();
    } else {
      _stepSource.useRuntimeSteps(controller._steps!);
    }
    _clearTargetFilteredSteps();
    if (!_canShowGuide) {
      if (controller._active) {
        _hideGuide(notifyFinish: false);
      }
      return;
    }
    final int targetIndex = controller._index.clamp(0, _steps.length - 1);
    final bool indexChanged = _index != targetIndex;
    if (_index != targetIndex) {
      setState(() {
        _index = targetIndex;
      });
    }
    if (controller._active && !_isGuideShowing) {
      _prepareAndShow();
    } else if (controller._active && indexChanged) {
      _prepareAndShow(restart: true);
    } else if (!controller._active && _isGuideShowing) {
      _finish();
    } else {
      _controller._syncFromState(this);
    }
  }

  void _handleControllerCommand(
    _SpotlightGuidePortalControllerCommand command,
  ) {
    switch (command.type) {
      case _SpotlightGuidePortalControllerCommandType.next:
        _controllerNext();
        break;
      case _SpotlightGuidePortalControllerCommandType.previous:
        _controllerPrevious();
        break;
      case _SpotlightGuidePortalControllerCommandType.goTo:
        _controllerGoTo(command.index ?? 0);
        break;
      case _SpotlightGuidePortalControllerCommandType.finish:
        _finish();
        break;
      case _SpotlightGuidePortalControllerCommandType.hide:
        _hideGuide(notifyFinish: false);
        break;
      case _SpotlightGuidePortalControllerCommandType.reset:
        _reset();
        break;
      case _SpotlightGuidePortalControllerCommandType.showPortal:
        _showPortalSteps(command.index ?? 0);
        break;
      case _SpotlightGuidePortalControllerCommandType.showSteps:
        _showRuntimeSteps(
          command.steps ?? const <SpotlightGuideStep>[],
          command.index ?? 0,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      child: _SpotlightGuideTargetScope(portal: this, child: widget.child),
      overlayChildBuilder: (BuildContext context, OverlayChildLayoutInfo info) {
        if (!_canShowGuide) {
          return const SizedBox.expand();
        }
        final Rect childRect = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final List<SpotlightGuideStep> steps = _steps;
        final int stepIndex = _effectiveIndex;
        final SpotlightGuideStep step = steps[stepIndex];
        final List<_SpotlightGuideOverlayItem> overlayItems =
            <_SpotlightGuideOverlayItem>[];
        final List<_SpotlightGuideTargetHole> targetHoles =
            <_SpotlightGuideTargetHole>[];
        final _SpotlightGuideTargetResolver targetResolver = _targetResolver;
        final List<SpotlightGuideStepItem> items = step.items;
        if (items.isEmpty) {
          return const SizedBox.expand();
        }
        if (_preparing &&
            (_waitingForRouteTransition ||
                _shouldHideRevealTransitionContent(
                  reason:
                      SpotlightGuideRevealPresentationReason.stepPreparation,
                  step: step,
                  stepIndex: stepIndex,
                  total: steps.length,
                ))) {
          return _emptyOverlayLayout(
            step: step,
            stepIndex: stepIndex,
            total: steps.length,
            overlaySize: info.overlaySize,
          );
        }
        final List<_SpotlightGuideOverlayItem> resolvedOverlayItems =
            <_SpotlightGuideOverlayItem>[];
        for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
          final SpotlightGuideStepItem item = items[itemIndex];
          final _SpotlightGuideTargetGeometry? targetGeometry = targetResolver
              .geometryForItem(item, childRect);
          if (targetGeometry == null) {
            // Render the step's resolved items now and let an unresolved item
            // (for example a lazy list target that auto scroll has not built
            // yet) join on a later rebuild once its target mounts. Its index is
            // preserved, so the remaining items keep their original item index.
            continue;
          }
          if (_shouldSkipHiddenAutoScrollItem(step, item, targetGeometry)) {
            // In same-step auto scroll, an already mounted target can still be
            // outside the viewport. Do not clamp its hint back onto the screen;
            // wait until auto scroll brings the target into view so hint, arrow
            // and spotlight hole stay visually connected.
            continue;
          }

          final List<Rect> targetRects = targetGeometry.rects
              .map((Rect rect) => rect.inflateRect(item.targetPadding))
              .map((Rect rect) => _clipTargetHoleRect(rect, info.overlaySize))
              .whereType<Rect>()
              .toList(growable: false);
          final Rect targetRect = targetGeometry.anchorRect.inflateRect(
            item.targetPadding,
          );
          resolvedOverlayItems.add(
            _SpotlightGuideOverlayItem(
              item: item,
              itemIndex: itemIndex,
              targetRect: targetRect,
              targetRects: targetRects,
              rawTargetRects: targetGeometry.rects,
            ),
          );
        }

        final List<_SpotlightGuideOverlayItem> itemsToRender =
            _focusedAutoScrollOverlayItems(step, resolvedOverlayItems);
        for (final _SpotlightGuideOverlayItem overlayItem in itemsToRender) {
          overlayItems.add(overlayItem);
          for (final Rect rect in overlayItem.targetRects) {
            _addTargetHole(
              targetHoles,
              _SpotlightGuideTargetHole(
                rect: rect,
                radius: overlayItem.item.targetRadius,
              ),
            );
          }
        }

        // Nothing has resolved yet (for example the first item's target is not
        // mounted). Keep the overlay empty until at least one item resolves.
        if (overlayItems.isEmpty) {
          final int? transitionItemIndex = _autoScrollTransitionItemIndex;
          if (_isAutoScrollTransitioning(step, resolvedOverlayItems) &&
              transitionItemIndex != null &&
              transitionItemIndex < step.items.length &&
              _shouldHideRevealTransitionContent(
                reason:
                    SpotlightGuideRevealPresentationReason.sameStepAutoScroll,
                step: step,
                stepIndex: stepIndex,
                total: steps.length,
                item: step.items[transitionItemIndex],
                itemIndex: transitionItemIndex,
              )) {
            return _emptyOverlayLayout(
              step: step,
              stepIndex: stepIndex,
              total: steps.length,
              overlaySize: info.overlaySize,
            );
          }
          if (_preparing && widget.blockInteractionDuringPreparation) {
            return _emptyOverlayLayout(
              step: step,
              stepIndex: stepIndex,
              total: steps.length,
              overlaySize: info.overlaySize,
            );
          }
          return const SizedBox.expand();
        }

        return _SpotlightGuideOverlayLayout(
          controller: _controller,
          step: step,
          barrier: _effectiveBarrier(step),
          index: stepIndex,
          total: steps.length,
          items: overlayItems,
          targetHoles: targetHoles,
          onBarrierTap: _effectiveBarrierTapCallback,
          overlaySize: info.overlaySize,
        );
      },
    );
  }

  Widget _emptyOverlayLayout({
    required SpotlightGuideStep step,
    required int stepIndex,
    required int total,
    required Size overlaySize,
  }) {
    return _SpotlightGuideOverlayLayout(
      controller: _controller,
      step: step,
      barrier: _effectiveBarrier(step),
      index: stepIndex,
      total: total,
      items: const <_SpotlightGuideOverlayItem>[],
      targetHoles: const <_SpotlightGuideTargetHole>[],
      onBarrierTap: _effectiveBarrierTapCallback,
      overlaySize: overlaySize,
    );
  }

  SpotlightGuideBarrierStyle _effectiveBarrier(SpotlightGuideStep step) {
    return SpotlightGuideBarrierStyle.fallback
        .merge(widget.barrier)
        .merge(step.barrier);
  }

  SpotlightGuideBarrierTapCallback? get _effectiveBarrierTapCallback {
    final SpotlightGuideBarrierTapCallback? custom = widget.onBarrierTap;
    if (custom != null) {
      return custom;
    }
    switch (widget.barrierDismissBehavior) {
      case SpotlightGuideBarrierDismissBehavior.disabled:
        return null;
      case SpotlightGuideBarrierDismissBehavior.onComplete:
        return _canDismissBarrierOnComplete ? _finishFromBarrierTap : null;
      case SpotlightGuideBarrierDismissBehavior.anytime:
        return _finishFromBarrierTap;
    }
  }

  bool get _canDismissBarrierOnComplete {
    if (!_canShowGuide ||
        _preparing ||
        !_overlayController.isShowing ||
        _steps.isEmpty ||
        _effectiveIndex != _steps.length - 1) {
      return false;
    }
    final SpotlightGuideStep step = _step;
    if (!_isAutoScrollSequenceActive(step)) {
      return true;
    }
    return _autoScrollTransitionItemIndex == null &&
        _autoScrollFocusedItemIndex == step.items.length - 1;
  }

  void _finishFromBarrierTap(SpotlightGuidePortalController controller) {
    controller.finish();
  }

  bool _shouldHideRevealTransitionContent({
    required SpotlightGuideRevealPresentationReason reason,
    required SpotlightGuideStep step,
    required int stepIndex,
    required int total,
    SpotlightGuideStepItem? item,
    int? itemIndex,
  }) {
    return widget.revealPresentationStrategy.resolve(
          SpotlightGuideRevealPresentationContext(
            reason: reason,
            stepIndex: stepIndex,
            total: total,
            step: step,
            itemIndex: itemIndex,
            item: item,
          ),
        ) ==
        SpotlightGuideRevealPresentationMode.barrierOnly;
  }

  /// When same-step auto scroll still has hidden later items, only the highest
  /// [itemIndex] that is currently renderable is shown so users see one hint at
  /// a time instead of two overlapping hints during a scroll transition.
  List<_SpotlightGuideOverlayItem> _focusedAutoScrollOverlayItems(
    SpotlightGuideStep step,
    List<_SpotlightGuideOverlayItem> resolvedOverlayItems,
  ) {
    if (resolvedOverlayItems.isEmpty ||
        !_isAutoScrollPresentationActive(step)) {
      return resolvedOverlayItems;
    }
    final int? focusedItemIndex = _autoScrollFocusedItemIndex;
    if (focusedItemIndex == null) {
      return const <_SpotlightGuideOverlayItem>[];
    }
    return resolvedOverlayItems
        .where(
          (_SpotlightGuideOverlayItem item) =>
              item.itemIndex == focusedItemIndex,
        )
        .toList(growable: false);
  }

  bool _isAutoScrollTransitioning(
    SpotlightGuideStep step,
    List<_SpotlightGuideOverlayItem> resolvedOverlayItems,
  ) {
    return resolvedOverlayItems.isNotEmpty &&
        _isAutoScrollPresentationActive(step) &&
        _autoScrollTransitionItemIndex != null &&
        _autoScrollFocusedItemIndex == null;
  }

  bool _shouldSkipHiddenAutoScrollItem(
    SpotlightGuideStep step,
    SpotlightGuideStepItem item,
    _SpotlightGuideTargetGeometry targetGeometry,
  ) {
    if (!_shouldAutoScrollStepItems(step) || item.highlightsWholePortalChild) {
      return false;
    }
    final Rect? viewport = _overlayViewportRect();
    if (viewport == null) {
      return false;
    }
    // Skip the hint only while the target is entirely off-screen. As soon as any
    // part of the target overlaps the viewport, render its hint so it stays
    // connected to the visible portion. Using overlap rather than full
    // containment also covers a target taller or wider than the viewport, which
    // can never be fully contained and would otherwise stay hidden forever.
    return !targetGeometry.rects.any(
      (Rect rect) => _viewportOverlapsRect(viewport, rect),
    );
  }

  Rect? _clipTargetHoleRect(Rect rect, Size overlaySize) {
    final Rect overlayRect = Offset.zero & overlaySize;
    final Rect clippedRect = rect.intersect(overlayRect);
    if (clippedRect.isEmpty ||
        clippedRect.width <= 0 ||
        clippedRect.height <= 0) {
      return null;
    }
    return clippedRect;
  }

  void _addTargetHole(
    List<_SpotlightGuideTargetHole> targetHoles,
    _SpotlightGuideTargetHole targetHole,
  ) {
    final bool exists = targetHoles.any(
      (_SpotlightGuideTargetHole hole) =>
          hole.rect == targetHole.rect && hole.radius == targetHole.radius,
    );
    if (!exists) {
      targetHoles.add(targetHole);
    }
  }
}

class _SpotlightGuideTargetFilterRefresh {
  const _SpotlightGuideTargetFilterRefresh({
    this.changed = false,
    this.currentStepChanged = false,
  });

  final bool changed;
  final bool currentStepChanged;
}
