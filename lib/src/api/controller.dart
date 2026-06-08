part of '../../spotlight_guide.dart';

/// Imperative controller for [SpotlightGuidePortal].
///
/// The controller is optional. If a portal is created without one, it creates
/// an internal controller and exposes it through [SpotlightGuideStepContext].
/// Pass an external controller when another part of the page must start,
/// restart or finish the guide.
///
/// The controller keeps its active state and index when it is replaced by a new
/// controller on the same portal. This makes rebuilds and hot-reload-like
/// updates less surprising.
///
/// Example:
///
/// ```dart
/// final controller = SpotlightGuidePortalController();
///
/// SpotlightGuidePortal(
///   controller: controller,
///   steps: steps,
///   child: page,
/// );
///
/// // Later:
/// controller.showPortal();       // Show SpotlightGuidePortal.steps.
/// controller.showSteps(steps);   // Show runtime steps built after data loads.
/// controller.next();             // Advance, or finish on the last step.
/// controller.hide();             // Close without calling onFinish.
/// controller.finish();           // Close and call onFinish.
/// ```
class SpotlightGuidePortalController {
  _SpotlightGuidePortalState? _state;
  final List<_SpotlightGuidePortalControllerCommand> _pendingCommands =
      <_SpotlightGuidePortalControllerCommand>[];
  List<SpotlightGuideStep>? _steps;
  int _index = 0;
  bool _active = false;

  /// Whether the guide is currently visible or preparing to become visible.
  bool get isShowing => _state?._isGuideShowing ?? _active;

  /// Current step index.
  ///
  /// If the step list shrinks while the guide is active, this value is clamped
  /// to the nearest valid index.
  int get index => _state?._effectiveIndex ?? _index;

  /// Total number of steps in the active guide sequence.
  ///
  /// For [showSteps] this is the runtime sequence length after target
  /// availability filtering. For [showPortal] or [reset] this is
  /// [SpotlightGuidePortal.steps] after the same filtering while the controller
  /// is attached.
  int get total => _state?._steps.length ?? _steps?.length ?? 0;

  int get _effectiveControllerIndex {
    final int count = total;
    if (count == 0) {
      return 0;
    }
    return index.clamp(0, count - 1).toInt();
  }

  /// Whether the guide is on the first step.
  bool get isFirst => total > 0 && _effectiveControllerIndex == 0;

  /// Whether the guide is on the last step.
  bool get isLast => total > 0 && _effectiveControllerIndex == total - 1;

  /// Continue to the next step. If the current step is the last one,
  /// [finish] is called automatically.
  void next() {
    _runOrPending(
      const _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.next,
      ),
    );
  }

  /// Go back to the previous step.
  ///
  /// Does nothing when the guide is already on the first step. It never calls
  /// [finish].
  void previous() {
    _runOrPending(
      const _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.previous,
      ),
    );
  }

  /// Jump directly to [index] and show that step.
  ///
  /// The index is clamped to the valid range. If the guide is not visible yet,
  /// it is shown at that step.
  void goTo(int index) {
    _runOrPending(
      _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.goTo,
        index,
      ),
    );
  }

  /// Finish the guide immediately.
  void finish() {
    _runOrPending(
      const _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.finish,
      ),
    );
  }

  /// Hide the guide without calling [SpotlightGuidePortal.onFinish].
  void hide() {
    _runOrPending(
      const _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.hide,
      ),
    );
  }

  /// Restart from the first step and show the guide.
  void reset() {
    _runOrPending(
      const _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.reset,
      ),
    );
  }

  /// Show [SpotlightGuidePortal.steps].
  void showPortal({int index = 0}) {
    _runOrPending(
      _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.showPortal,
        index,
      ),
    );
  }

  /// Show a runtime guide sequence.
  ///
  /// Use this for steps produced after data loading or feature-flag decisions.
  /// Runtime steps take priority for this controller until [showPortal] is
  /// called. Passing an empty list closes the guide without calling
  /// [SpotlightGuidePortal.onFinish].
  void showSteps(List<SpotlightGuideStep> steps, {int index = 0}) {
    final List<SpotlightGuideStep> runtimeSteps =
        List<SpotlightGuideStep>.unmodifiable(steps);
    _runOrPending(
      _SpotlightGuidePortalControllerCommand(
        _SpotlightGuidePortalControllerCommandType.showSteps,
        index,
        runtimeSteps,
      ),
    );
  }

  /// Show a guide sequence.
  ///
  /// Prefer [showPortal] or [showSteps] in new code.
  @Deprecated('Use showPortal() or showSteps(steps) instead.')
  void show({List<SpotlightGuideStep>? steps, int index = 0}) {
    if (steps == null) {
      showPortal(index: index);
    } else {
      showSteps(steps, index: index);
    }
  }

  void _attach(_SpotlightGuidePortalState state) {
    _state = state;
    final List<_SpotlightGuidePortalControllerCommand> commands =
        List<_SpotlightGuidePortalControllerCommand>.of(_pendingCommands);
    _pendingCommands.clear();
    if (commands.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_state == state && state.mounted) {
          for (final _SpotlightGuidePortalControllerCommand command
              in commands) {
            state._handleControllerCommand(command);
          }
        }
      });
      return;
    }
    if (_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_state == state && state.mounted) {
          state._applyControllerSnapshot(this);
        }
      });
    }
  }

  void _detach(_SpotlightGuidePortalState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void _runOrPending(_SpotlightGuidePortalControllerCommand command) {
    final _SpotlightGuidePortalState? state = _state;
    if (state == null) {
      _pendingCommands.add(command);
      switch (command.type) {
        case _SpotlightGuidePortalControllerCommandType.finish:
        case _SpotlightGuidePortalControllerCommandType.hide:
          _active = false;
          break;
        case _SpotlightGuidePortalControllerCommandType.reset:
          _active = true;
          _index = 0;
          break;
        case _SpotlightGuidePortalControllerCommandType.goTo:
          _active = true;
          _index = command.index ?? 0;
          break;
        case _SpotlightGuidePortalControllerCommandType.showPortal:
          _steps = null;
          _active = true;
          _index = command.index ?? 0;
          break;
        case _SpotlightGuidePortalControllerCommandType.showSteps:
          _steps = command.steps == null || command.steps!.isEmpty
              ? null
              : command.steps;
          _active = command.steps != null && command.steps!.isNotEmpty;
          _index = command.index ?? 0;
          break;
        case _SpotlightGuidePortalControllerCommandType.next:
        case _SpotlightGuidePortalControllerCommandType.previous:
          _active = true;
          break;
      }
      return;
    }
    state._handleControllerCommand(command);
  }

  void _absorbFrom(SpotlightGuidePortalController oldController) {
    oldController._snapshotFromState();
    _index = oldController._index;
    _active = oldController._active;
    _steps = oldController._steps;
    _pendingCommands
      ..clear()
      ..addAll(oldController._pendingCommands);
    oldController._pendingCommands.clear();
  }

  void _snapshotFromState() {
    final _SpotlightGuidePortalState? state = _state;
    if (state == null) {
      return;
    }
    _index = state._effectiveIndex;
    _active = state._isGuideShowing;
    _steps = state._runtimeSteps;
  }

  void _syncFromState(_SpotlightGuidePortalState state) {
    if (_state != state) {
      return;
    }
    _index = state._effectiveIndex;
    _active = state._isGuideShowing;
    _steps = state._runtimeSteps;
  }
}

enum _SpotlightGuidePortalControllerCommandType {
  next,
  previous,
  finish,
  hide,
  reset,
  goTo,
  showPortal,
  showSteps,
}

/// One queued controller action, optionally carrying a target step index.
class _SpotlightGuidePortalControllerCommand {
  const _SpotlightGuidePortalControllerCommand(
    this.type, [
    this.index,
    this.steps,
  ]);

  final _SpotlightGuidePortalControllerCommandType type;
  final int? index;
  final List<SpotlightGuideStep>? steps;
}
