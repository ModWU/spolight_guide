part of '../../spotlight_guide.dart';

/// Marks a widget as a reusable target for [SpotlightGuidePortal].
///
/// Wrap any widget inside [SpotlightGuidePortal.child] with this component, then
/// point a [SpotlightGuideStepItem.targetId] at the same [id]. The id can be
/// a string, enum, or any stable object that implements equality correctly.
///
/// The same id can be referenced by many different steps or step items. If
/// several mounted targets share the same id, they are highlighted as one
/// logical group and the guide uses the group's union rect for placement. Use
/// that only when every instance should be introduced together. If one instance
/// needs to be the precise anchor while the group stays highlighted, set
/// [anchorId] on that instance and use the same value as
/// [SpotlightGuideStepItem.anchorTargetId].
///
/// This widget only registers targets that are already mounted. If a target
/// lives in a lazy list range that has not been built yet, use
/// [SpotlightGuideStep.onReveal] or [SpotlightGuideStepItem.onReveal] to scroll,
/// switch tabs, expand content, or load data before the portal measures it.
///
/// Example:
///
/// ```dart
/// SpotlightGuidePortal(
///   steps: <SpotlightGuideStep>[
///     SpotlightGuideStep.item(
///       SpotlightGuideStepItem(
///         targetId: 'more-button',
///         hintBuilder: buildHint,
///       ),
///     ),
///   ],
///   child: Row(
///     children: <Widget>[
///       const Spacer(),
///       SpotlightGuideTarget(
///         id: 'more-button',
///         child: IconButton(
///           icon: const Icon(Icons.more_horiz),
///           onPressed: openMenu,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
class SpotlightGuideTarget extends StatefulWidget {
  const SpotlightGuideTarget({
    super.key,
    required this.id,
    required this.child,
    this.anchorId,
    this.enabled = true,
  });

  /// Stable id used by [SpotlightGuideStepItem.targetId] or
  /// [SpotlightGuideStepItem.targetIds].
  final Object id;

  /// Widget whose bounds are used as the target rect.
  final Widget child;

  /// Optional id used only for selecting this target as a guide anchor.
  ///
  /// This does not create another spotlight hole by itself. It lets an item
  /// highlight a repeated [id] group while pointing the bubble at this specific
  /// target:
  ///
  /// ```dart
  /// SpotlightGuideTarget(
  ///   id: 'summary-card',
  ///   anchorId: 'summary-total-cost',
  ///   child: totalCostCard,
  /// )
  ///
  /// SpotlightGuideStepItem(
  ///   targetId: 'summary-card',
  ///   anchorTargetId: 'summary-total-cost',
  ///   hintBuilder: buildHint,
  /// )
  /// ```
  final Object? anchorId;

  /// Whether this target should be registered by the nearest portal.
  ///
  /// Set this to false when the widget remains in the tree but should not be
  /// available for guide placement.
  final bool enabled;

  @override
  State<SpotlightGuideTarget> createState() => _SpotlightGuideTargetState();
}

/// Registers and unregisters [SpotlightGuideTarget] with the nearest portal.
class _SpotlightGuideTargetState extends State<SpotlightGuideTarget> {
  _SpotlightGuidePortalState? _portal;
  Object? _registeredId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRegistration();
  }

  @override
  void didUpdateWidget(covariant SpotlightGuideTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.enabled != widget.enabled) {
      _syncRegistration(force: true);
    } else if (oldWidget.anchorId != widget.anchorId) {
      _portal?._scheduleTargetRefresh();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _syncRegistration({bool force = false}) {
    final _SpotlightGuidePortalState? portal =
        _SpotlightGuideTargetScope.maybeOf(context);
    if (!widget.enabled || portal == null) {
      _unregister();
      _portal = portal;
      return;
    }
    if (!force && _portal == portal && _registeredId == widget.id) {
      return;
    }
    _unregister();
    _portal = portal;
    _registeredId = widget.id;
    portal._registerTarget(widget.id, this);
  }

  void _unregister() {
    final _SpotlightGuidePortalState? portal = _portal;
    final Object? id = _registeredId;
    if (portal != null && id != null) {
      portal._unregisterTarget(id, this);
    }
    _registeredId = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Internal scope used by targets to find their owning portal.
class _SpotlightGuideTargetScope extends InheritedWidget {
  const _SpotlightGuideTargetScope({
    required this.portal,
    required super.child,
  });

  final _SpotlightGuidePortalState portal;

  static _SpotlightGuidePortalState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SpotlightGuideTargetScope>()
        ?.portal;
  }

  @override
  bool updateShouldNotify(covariant _SpotlightGuideTargetScope oldWidget) {
    return oldWidget.portal != portal;
  }
}
