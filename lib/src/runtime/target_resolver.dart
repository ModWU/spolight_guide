part of '../../spotlight_guide.dart';

/// Resolves guide item targets into mounted contexts and overlay geometry.
///
/// Target lookup supports target ids, repeated-id groups, anchor aliases,
/// global keys, and whole-portal highlighting. This resolver keeps those rules
/// in one place so the portal can focus on guide orchestration.
class _SpotlightGuideTargetResolver {
  const _SpotlightGuideTargetResolver({
    required this.portalContext,
    required this.targets,
  });

  final BuildContext portalContext;
  final Map<Object, Set<_SpotlightGuideTargetState>> targets;

  List<BuildContext> contextsForStep(SpotlightGuideStep step) {
    final List<BuildContext> contexts = <BuildContext>[];
    for (final SpotlightGuideStepItem item in step.items) {
      _addTargetContexts(contexts, contextsForItem(item));
    }
    return contexts;
  }

  List<BuildContext> contextsForItem(SpotlightGuideStepItem item) {
    final List<BuildContext> contexts = <BuildContext>[];
    if (item.targetKey != null) {
      _addTargetContext(contexts, item.targetKey!.currentContext);
      return contexts;
    }
    if (item.targetId != null) {
      _addTargetContextsForId(contexts, item.targetId!);
      return contexts;
    }
    if (item.targetIds != null) {
      final Object? anchorTargetId = item.anchorTargetId;
      final List<Object> targetIds = _uniqueObjects(item.targetIds!);
      for (final Object id in targetIds) {
        if (id == anchorTargetId) {
          continue;
        }
        _addTargetContextsForId(contexts, id);
      }
      if (anchorTargetId != null && targetIds.contains(anchorTargetId)) {
        _addTargetContextsForId(contexts, anchorTargetId);
      }
      return contexts;
    }
    return contexts;
  }

  List<BuildContext> contextsForId(Object id) {
    final List<BuildContext> contexts = <BuildContext>[];
    _addTargetContextsForId(contexts, id);
    return contexts;
  }

  int resolvedItemCountForStep(SpotlightGuideStep? step, Rect childRect) {
    if (step == null) {
      return 0;
    }
    int count = 0;
    for (final SpotlightGuideStepItem item in step.items) {
      if (geometryForItem(item, childRect) != null) {
        count++;
      }
    }
    return count;
  }

  bool hasResolvedGeometry(SpotlightGuideStepItem item, Rect childRect) {
    return geometryForItem(item, childRect) != null;
  }

  _SpotlightGuideTargetGeometry? geometryForItem(
    SpotlightGuideStepItem item,
    Rect childRect,
  ) {
    if (item.targetKey != null) {
      final Rect? rect = rectForContext(item.targetKey!.currentContext);
      return rect == null
          ? null
          : _SpotlightGuideTargetGeometry(
              anchorRect: rect,
              rects: <Rect>[rect],
            );
    }
    if (item.targetId != null) {
      return _geometryForIds(item, <Object>[item.targetId!]);
    }
    if (item.targetIds != null) {
      return _geometryForIds(item, _uniqueObjects(item.targetIds!));
    }
    return _SpotlightGuideTargetGeometry(
      anchorRect: childRect,
      rects: <Rect>[childRect],
    );
  }

  Rect? rectForContext(BuildContext? targetContext) {
    final RenderObject? targetObject;
    final RenderObject? overlayObject;
    try {
      targetObject = targetContext?.findRenderObject();
      overlayObject = Overlay.of(portalContext).context.findRenderObject();
    } catch (_) {
      return null;
    }
    if (targetObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !targetObject.attached ||
        !overlayObject.attached ||
        !targetObject.hasSize ||
        !overlayObject.hasSize) {
      return null;
    }

    return MatrixUtils.transformRect(
      targetObject.getTransformTo(overlayObject),
      Offset.zero & targetObject.size,
    );
  }

  Rect? visibleRectForContext(BuildContext? targetContext) {
    final RenderObject? targetObject;
    final RenderObject? overlayObject;
    try {
      targetObject = targetContext?.findRenderObject();
      overlayObject = Overlay.of(portalContext).context.findRenderObject();
    } catch (_) {
      return null;
    }
    if (targetObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !targetObject.attached ||
        !overlayObject.attached ||
        !targetObject.hasSize ||
        !overlayObject.hasSize) {
      return null;
    }

    Rect visibleRect = MatrixUtils.transformRect(
      targetObject.getTransformTo(overlayObject),
      Offset.zero & targetObject.size,
    ).intersect(Offset.zero & overlayObject.size);
    final Set<RenderObject> visitedViewports = <RenderObject>{};
    targetContext?.visitAncestorElements((Element element) {
      final RenderObject? renderObject = element.renderObject;
      if (renderObject is RenderBox &&
          renderObject is RenderAbstractViewport &&
          renderObject.attached &&
          renderObject.hasSize &&
          visitedViewports.add(renderObject)) {
        final Rect viewportRect = MatrixUtils.transformRect(
          renderObject.getTransformTo(overlayObject),
          Offset.zero & renderObject.size,
        );
        visibleRect = visibleRect.intersect(viewportRect);
      }
      return !visibleRect.isEmpty &&
          visibleRect.width > 0 &&
          visibleRect.height > 0;
    });
    if (visibleRect.isEmpty ||
        visibleRect.width <= 0 ||
        visibleRect.height <= 0) {
      return null;
    }
    return visibleRect;
  }

  List<BuildContext> anchorContextsForItem(SpotlightGuideStepItem item) {
    final Object? anchorTargetId = item.anchorTargetId;
    if (anchorTargetId == null || item.targetKey != null) {
      return const <BuildContext>[];
    }
    if (item.targetId != null) {
      if (item.targetId == anchorTargetId) {
        return contextsForId(anchorTargetId);
      }
      return _contextsForAnchorIdInIds(anchorTargetId, <Object>[
        item.targetId!,
      ]);
    }
    if (item.targetIds != null) {
      final List<Object> targetIds = _uniqueObjects(item.targetIds!);
      if (targetIds.contains(anchorTargetId)) {
        final List<BuildContext> idContexts = contextsForId(anchorTargetId);
        if (idContexts.isNotEmpty) {
          return idContexts;
        }
      }
      return _contextsForAnchorIdInIds(anchorTargetId, targetIds);
    }
    return const <BuildContext>[];
  }

  _SpotlightGuideTargetGeometry? _geometryForIds(
    SpotlightGuideStepItem item,
    List<Object> ids,
  ) {
    final List<_SpotlightGuideResolvedTarget> resolvedTargets =
        <_SpotlightGuideResolvedTarget>[];
    for (final Object id in _uniqueObjects(ids)) {
      final Set<_SpotlightGuideTargetState>? targetStates = targets[id];
      if (targetStates == null || targetStates.isEmpty) {
        return null;
      }
      bool resolvedAny = false;
      for (final _SpotlightGuideTargetState target in targetStates) {
        if (!target.mounted) {
          continue;
        }
        final Rect? rect = rectForContext(target.context);
        if (rect == null) {
          continue;
        }
        resolvedAny = true;
        resolvedTargets.add(
          _SpotlightGuideResolvedTarget(
            id: id,
            anchorId: target.widget.anchorId,
            rect: rect,
          ),
        );
      }
      if (!resolvedAny) {
        return null;
      }
    }
    if (resolvedTargets.isEmpty) {
      return null;
    }
    final Rect unionRect = resolvedTargets
        .map((target) => target.rect)
        .reduce((Rect value, Rect rect) => value.expandToInclude(rect));
    final Rect anchorRect =
        _anchorRectForItem(item, resolvedTargets) ?? unionRect;
    return _SpotlightGuideTargetGeometry(
      anchorRect: anchorRect,
      rects: resolvedTargets
          .map((target) => target.rect)
          .toList(growable: false),
    );
  }

  Rect? _anchorRectForItem(
    SpotlightGuideStepItem item,
    List<_SpotlightGuideResolvedTarget> resolvedTargets,
  ) {
    final Object? anchorTargetId = item.anchorTargetId;
    if (anchorTargetId == null) {
      return null;
    }
    return _unionRectForId(resolvedTargets, anchorTargetId) ??
        _unionRectForAnchorId(resolvedTargets, anchorTargetId);
  }

  Rect? _unionRectForId(
    List<_SpotlightGuideResolvedTarget> resolvedTargets,
    Object id,
  ) {
    Rect? union;
    for (final _SpotlightGuideResolvedTarget target in resolvedTargets) {
      if (target.id != id) {
        continue;
      }
      union = union == null ? target.rect : union.expandToInclude(target.rect);
    }
    return union;
  }

  Rect? _unionRectForAnchorId(
    List<_SpotlightGuideResolvedTarget> resolvedTargets,
    Object anchorId,
  ) {
    Rect? union;
    for (final _SpotlightGuideResolvedTarget target in resolvedTargets) {
      if (target.anchorId != anchorId) {
        continue;
      }
      union = union == null ? target.rect : union.expandToInclude(target.rect);
    }
    return union;
  }

  List<BuildContext> _contextsForAnchorIdInIds(
    Object anchorId,
    List<Object> ids,
  ) {
    final List<BuildContext> contexts = <BuildContext>[];
    for (final Object id in _uniqueObjects(ids)) {
      final Set<_SpotlightGuideTargetState>? targetStates = targets[id];
      if (targetStates == null || targetStates.isEmpty) {
        continue;
      }
      for (final _SpotlightGuideTargetState target in targetStates) {
        if (target.widget.anchorId != anchorId || !target.mounted) {
          continue;
        }
        _addTargetContext(contexts, target.context);
      }
    }
    return contexts;
  }

  void _addTargetContextsForId(List<BuildContext> contexts, Object id) {
    final Set<_SpotlightGuideTargetState>? targetStates = targets[id];
    if (targetStates == null || targetStates.isEmpty) {
      return;
    }
    for (final _SpotlightGuideTargetState target in targetStates) {
      if (!target.mounted) {
        continue;
      }
      _addTargetContext(contexts, target.context);
    }
  }

  void _addTargetContexts(
    List<BuildContext> contexts,
    List<BuildContext> additions,
  ) {
    for (final BuildContext targetContext in additions) {
      _addTargetContext(contexts, targetContext);
    }
  }

  void _addTargetContext(
    List<BuildContext> contexts,
    BuildContext? targetContext,
  ) {
    if (!_isUsableTargetContext(targetContext) ||
        contexts.contains(targetContext)) {
      return;
    }
    contexts.add(targetContext!);
  }

  bool _isUsableTargetContext(BuildContext? targetContext) {
    if (targetContext == null || !targetContext.mounted) {
      return false;
    }
    try {
      final RenderObject? renderObject = targetContext.findRenderObject();
      return renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize;
    } catch (_) {
      return false;
    }
  }
}
