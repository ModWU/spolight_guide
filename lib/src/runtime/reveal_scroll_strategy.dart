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
  ) {
    final List<BuildContext> targetContexts = targetResolver.contextsForItem(
      item,
    );
    if (targetContexts.isEmpty) {
      return targetContexts;
    }
    if (revealOptions.scrollPolicy ==
            SpotlightGuideRevealScrollPolicy.onlyIfNeeded &&
        isItemRevealSatisfied(item, revealOptions)) {
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
    switch (revealOptions.scrollTargetPolicy) {
      case SpotlightGuideRevealScrollTargetPolicy.highlightedArea:
        return _isHighlightedAreaRevealSatisfied(visibleViewport, geometry);
      case SpotlightGuideRevealScrollTargetPolicy.anchorTarget:
        return _isAnchorRevealSatisfied(visibleViewport, geometry, item) ??
            _isHighlightedAreaRevealSatisfied(visibleViewport, geometry);
      case SpotlightGuideRevealScrollTargetPolicy
          .anchorTargetWhenHighlightedAreaCannotFit:
        if (_highlightedAreaCanFit(visibleViewport, geometry)) {
          return _isHighlightedAreaRevealSatisfied(visibleViewport, geometry);
        }
        return _isAnchorRevealSatisfied(visibleViewport, geometry, item) ??
            _isHighlightedAreaRevealSatisfied(visibleViewport, geometry);
    }
  }

  bool shouldScrollTargetIntoView(
    BuildContext targetContext,
    SpotlightGuideRevealOptions revealOptions,
  ) {
    switch (revealOptions.scrollPolicy) {
      case SpotlightGuideRevealScrollPolicy.always:
        return true;
      case SpotlightGuideRevealScrollPolicy.onlyIfNeeded:
        final Rect? viewport = viewportRect();
        final Rect? targetRect = targetResolver.rectForContext(targetContext);
        if (viewport == null || targetRect == null) {
          return true;
        }
        return !_viewportContainsRect(
          _visibleViewportForReveal(viewport, revealOptions.visibilityPadding),
          targetRect,
        );
    }
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
}
