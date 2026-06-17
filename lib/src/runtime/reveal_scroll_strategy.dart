part of '../../spotlight_guide.dart';

/// Decides whether reveal scrolling is needed and which target should drive it.
class _SpotlightGuideRevealScrollStrategy {
  const _SpotlightGuideRevealScrollStrategy({
    required this.targetResolver,
    required this.viewportRect,
  });

  final _SpotlightGuideTargetResolver targetResolver;
  final Rect? Function() viewportRect;

  List<BuildContext> revealContextsForItem(
    SpotlightGuideStepItem item,
    SpotlightGuideRevealOptions revealOptions,
    TextDirection textDirection,
  ) {
    final List<BuildContext> targetContexts = targetResolver.contextsForItem(
      item,
    );
    if (targetContexts.isEmpty) {
      return targetContexts;
    }
    if (revealOptions.scrollPolicy ==
            SpotlightGuideRevealScrollPolicy.onlyIfNeeded &&
        isItemRevealSatisfied(item, revealOptions, textDirection)) {
      return const <BuildContext>[];
    }
    final List<BuildContext>? anchorContexts = _anchorContextsForItem(item);
    if (anchorContexts != null &&
        _shouldRevealAnchorTarget(item, revealOptions)) {
      return anchorContexts;
    }
    return targetContexts;
  }

  bool isItemRevealSatisfied(
    SpotlightGuideStepItem item,
    SpotlightGuideRevealOptions revealOptions,
    TextDirection textDirection,
  ) {
    if (revealOptions.scrollPolicy == SpotlightGuideRevealScrollPolicy.always) {
      return false;
    }
    final Rect? viewport = viewportRect();
    if (viewport == null) {
      return false;
    }
    final _SpotlightGuideTargetGeometry? geometry = targetResolver
        .geometryForItem(item, Rect.zero);
    if (geometry == null) {
      return false;
    }
    final Rect visibleViewport = _visibleViewportForReveal(
      viewport,
      revealOptions.visibilityPadding,
    );
    final bool targetIsVisible = switch (revealOptions.scrollTargetPolicy) {
      SpotlightGuideRevealScrollTargetPolicy.highlightedArea =>
        _isHighlightedAreaRevealSatisfied(visibleViewport, geometry),
      SpotlightGuideRevealScrollTargetPolicy.anchorTarget =>
        _isAnchorRevealSatisfied(visibleViewport, geometry, item) ??
            _isHighlightedAreaRevealSatisfied(visibleViewport, geometry),
      SpotlightGuideRevealScrollTargetPolicy
          .anchorTargetWhenHighlightedAreaCannotFit =>
        _highlightedAreaCanFit(visibleViewport, geometry)
            ? _isHighlightedAreaRevealSatisfied(visibleViewport, geometry)
            : _isAnchorRevealSatisfied(visibleViewport, geometry, item) ??
                  _isHighlightedAreaRevealSatisfied(visibleViewport, geometry),
    };
    if (!targetIsVisible) {
      return false;
    }
    if (!_targetContextsAreVisibleForReveal(
      item,
      revealOptions,
      visibleViewport,
      geometry,
    )) {
      return false;
    }
    return _hasEnoughHintSpace(
      viewport: viewport,
      visibleViewport: visibleViewport,
      geometry: geometry,
      item: item,
      textDirection: textDirection,
    );
  }

  bool shouldScrollTargetIntoView(
    BuildContext targetContext,
    SpotlightGuideRevealOptions revealOptions,
    bool forceScroll,
  ) {
    if (forceScroll) {
      return true;
    }
    switch (revealOptions.scrollPolicy) {
      case SpotlightGuideRevealScrollPolicy.always:
        return true;
      case SpotlightGuideRevealScrollPolicy.onlyIfNeeded:
        final Rect? viewport = viewportRect();
        final Rect? targetRect = targetResolver.rectForContext(targetContext);
        final Rect? visibleRect = targetResolver.visibleRectForContext(
          targetContext,
        );
        if (viewport == null || targetRect == null || visibleRect == null) {
          return true;
        }
        final Rect visibleViewport = _visibleViewportForReveal(
          viewport,
          revealOptions.visibilityPadding,
        );
        if (_rectCanFitInViewport(visibleViewport, targetRect)) {
          return !_viewportContainsRect(visibleRect, targetRect);
        }
        return !_viewportOverlapsRect(visibleRect, targetRect);
    }
  }

  bool _targetContextsAreVisibleForReveal(
    SpotlightGuideStepItem item,
    SpotlightGuideRevealOptions revealOptions,
    Rect visibleViewport,
    _SpotlightGuideTargetGeometry geometry,
  ) {
    final List<BuildContext>? anchorContexts = _anchorContextsForItem(item);
    final List<BuildContext> contexts =
        anchorContexts != null && _shouldRevealAnchorTarget(item, revealOptions)
        ? anchorContexts
        : targetResolver.contextsForItem(item);
    if (contexts.isEmpty) {
      return false;
    }
    for (final BuildContext targetContext in contexts) {
      final Rect? targetRect = targetResolver.rectForContext(targetContext);
      final Rect? visibleRect = targetResolver.visibleRectForContext(
        targetContext,
      );
      if (targetRect == null || visibleRect == null) {
        return false;
      }
      final Rect revealRect = _rectForContextWithinGeometry(
        targetRect,
        geometry,
      );
      if (_rectCanFitInViewport(visibleViewport, revealRect)) {
        if (!_viewportContainsRect(visibleRect, revealRect)) {
          return false;
        }
      } else if (!_viewportOverlapsRect(visibleRect, revealRect)) {
        return false;
      }
    }
    return true;
  }

  Rect _rectForContextWithinGeometry(
    Rect targetRect,
    _SpotlightGuideTargetGeometry geometry,
  ) {
    for (final Rect rect in geometry.rects) {
      if (_rectsNearlyEqual(rect, targetRect)) {
        return rect;
      }
    }
    return targetRect;
  }

  bool _hasEnoughHintSpace({
    required Rect viewport,
    required Rect visibleViewport,
    required _SpotlightGuideTargetGeometry geometry,
    required SpotlightGuideStepItem item,
    required TextDirection textDirection,
  }) {
    final EdgeInsets margin = (item.margin ?? const EdgeInsets.all(16)).resolve(
      textDirection,
    );
    final EdgeInsets decorationPadding = item.targetDecoration.padding.resolve(
      textDirection,
    );
    final Rect targetRect = geometry.anchorRect.inflateRect(decorationPadding);
    final SpotlightGuidePlacement placement = _HintLayout._resolvePlacement(
      screenSize: viewport.size,
      targetRect: targetRect,
      step: item,
      margin: margin,
      hintSize: null,
      textDirection: textDirection,
      layoutGap: null,
    );
    final double reserve = _estimatedHintMainAxisExtent(
      viewport: viewport,
      margin: margin,
      item: item,
      placement: placement,
    );
    final double start = math.max(
      visibleViewport.top,
      viewport.top + margin.top,
    );
    final double end = math.min(
      visibleViewport.bottom,
      viewport.bottom - margin.bottom,
    );
    final double left = math.max(
      visibleViewport.left,
      viewport.left + margin.left,
    );
    final double right = math.min(
      visibleViewport.right,
      viewport.right - margin.right,
    );
    return switch (placement) {
      SpotlightGuidePlacement.top =>
        targetRect.top - _finiteOrZero(item.gap) - reserve >= start,
      SpotlightGuidePlacement.bottom =>
        targetRect.bottom + _finiteOrZero(item.gap) + reserve <= end,
      SpotlightGuidePlacement.left =>
        targetRect.left - _finiteOrZero(item.gap) - reserve >= left,
      SpotlightGuidePlacement.right =>
        targetRect.right + _finiteOrZero(item.gap) + reserve <= right,
      SpotlightGuidePlacement.auto ||
      SpotlightGuidePlacement.verticalAuto ||
      SpotlightGuidePlacement.horizontalAuto ||
      SpotlightGuidePlacement.start ||
      SpotlightGuidePlacement.end => throw StateError(
        'placements must be resolved before reveal space checks',
      ),
    };
  }

  double _estimatedHintMainAxisExtent({
    required Rect viewport,
    required EdgeInsets margin,
    required SpotlightGuideStepItem item,
    required SpotlightGuidePlacement placement,
  }) {
    final bool vertical =
        placement == SpotlightGuidePlacement.top ||
        placement == SpotlightGuidePlacement.bottom;
    final double available = math.max(
      0,
      vertical
          ? viewport.height - margin.vertical
          : viewport.width - margin.horizontal,
    );
    final double fallback = vertical
        ? math.min(180, math.max(96, available * 0.35))
        : math.min(260, math.max(120, available * 0.5));
    final double? configuredMin = vertical ? item.minHeight : item.minWidth;
    final double? configuredMax = vertical ? item.maxHeight : item.maxWidth;
    final double effectiveMax =
        configuredMax == null || configuredMax.isInfinite
        ? available
        : math.min(configuredMax, available);
    return math.min(
      math.max(configuredMin ?? 0, fallback),
      math.max(0, effectiveMax),
    );
  }

  bool _shouldRevealAnchorTarget(
    SpotlightGuideStepItem item,
    SpotlightGuideRevealOptions revealOptions,
  ) {
    switch (revealOptions.scrollTargetPolicy) {
      case SpotlightGuideRevealScrollTargetPolicy.highlightedArea:
        return false;
      case SpotlightGuideRevealScrollTargetPolicy.anchorTarget:
        return true;
      case SpotlightGuideRevealScrollTargetPolicy
          .anchorTargetWhenHighlightedAreaCannotFit:
        final Rect? viewport = viewportRect();
        if (viewport == null) {
          return false;
        }
        final _SpotlightGuideTargetGeometry? geometry = targetResolver
            .geometryForItem(item, Rect.zero);
        if (geometry == null) {
          return false;
        }
        final Rect visibleViewport = _visibleViewportForReveal(
          viewport,
          revealOptions.visibilityPadding,
        );
        return !_highlightedAreaCanFit(visibleViewport, geometry);
    }
  }

  List<BuildContext>? _anchorContextsForItem(SpotlightGuideStepItem item) {
    if (!_hasUsableAnchorTarget(item)) {
      return null;
    }
    final List<BuildContext> anchorContexts = targetResolver
        .anchorContextsForItem(item);
    return anchorContexts.isEmpty ? null : anchorContexts;
  }

  bool _hasUsableAnchorTarget(SpotlightGuideStepItem item) {
    return targetResolver.anchorContextsForItem(item).isNotEmpty;
  }

  bool _isHighlightedAreaRevealSatisfied(
    Rect visibleViewport,
    _SpotlightGuideTargetGeometry geometry,
  ) {
    final Rect groupRect = _unionRects(geometry.rects);
    if (_rectCanFitInViewport(visibleViewport, groupRect)) {
      return _viewportContainsRect(visibleViewport, groupRect);
    }
    return false;
  }

  bool? _isAnchorRevealSatisfied(
    Rect visibleViewport,
    _SpotlightGuideTargetGeometry geometry,
    SpotlightGuideStepItem item,
  ) {
    if (!_hasUsableAnchorTarget(item)) {
      return null;
    }
    final Rect anchorRect = geometry.anchorRect;
    if (_rectCanFitInViewport(visibleViewport, anchorRect)) {
      return _viewportContainsRect(visibleViewport, anchorRect);
    }
    return _viewportOverlapsRect(visibleViewport, anchorRect);
  }

  bool _highlightedAreaCanFit(
    Rect visibleViewport,
    _SpotlightGuideTargetGeometry geometry,
  ) {
    return _rectCanFitInViewport(visibleViewport, _unionRects(geometry.rects));
  }

  Rect _visibleViewportForReveal(Rect viewport, EdgeInsets padding) {
    final Rect paddedViewport = padding.deflateRect(viewport);
    if (paddedViewport.isEmpty ||
        paddedViewport.width <= 0 ||
        paddedViewport.height <= 0) {
      return viewport;
    }
    return paddedViewport;
  }

  Rect _unionRects(List<Rect> rects) {
    return rects.reduce((Rect value, Rect rect) => value.expandToInclude(rect));
  }

  bool _rectCanFitInViewport(Rect viewport, Rect rect) {
    const double tolerance = 0.5;
    return rect.width <= viewport.width + tolerance &&
        rect.height <= viewport.height + tolerance;
  }

  bool _viewportContainsRect(Rect viewport, Rect rect) {
    const double tolerance = 0.5;
    return rect.left >= viewport.left - tolerance &&
        rect.top >= viewport.top - tolerance &&
        rect.right <= viewport.right + tolerance &&
        rect.bottom <= viewport.bottom + tolerance;
  }

  bool _viewportOverlapsRect(Rect viewport, Rect rect) {
    const double tolerance = 0.5;
    return rect.right > viewport.left + tolerance &&
        rect.left < viewport.right - tolerance &&
        rect.bottom > viewport.top + tolerance &&
        rect.top < viewport.bottom - tolerance;
  }

  bool _rectsNearlyEqual(Rect a, Rect b) {
    const double tolerance = 0.5;
    return (a.left - b.left).abs() <= tolerance &&
        (a.top - b.top).abs() <= tolerance &&
        (a.right - b.right).abs() <= tolerance &&
        (a.bottom - b.bottom).abs() <= tolerance;
  }
}
