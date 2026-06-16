part of '../../spotlight_guide.dart';

/// Overlay widget that measures hints and renders the active step.
class _SpotlightGuideOverlayLayout extends StatefulWidget {
  const _SpotlightGuideOverlayLayout({
    required this.controller,
    required this.step,
    required this.barrier,
    required this.index,
    required this.total,
    required this.items,
    required this.targetHoles,
    required this.overlaySize,
    this.onBarrierTap,
  });

  final SpotlightGuidePortalController controller;
  final SpotlightGuideStep step;
  final SpotlightGuideBarrierStyle barrier;
  final int index;
  final int total;
  final List<_SpotlightGuideOverlayItem> items;
  final List<_SpotlightGuideTargetHole> targetHoles;
  final Size overlaySize;
  final SpotlightGuideBarrierTapCallback? onBarrierTap;

  @override
  State<_SpotlightGuideOverlayLayout> createState() =>
      _SpotlightGuideOverlayLayoutState();
}

/// Keeps measured hint sizes and rebuilds when step geometry changes.
class _SpotlightGuideOverlayLayoutState
    extends State<_SpotlightGuideOverlayLayout> {
  static const int _minHiddenMeasurePassesBeforeVisible = 3;
  static const int _maxHiddenMeasurePasses = 24;
  static const double _measureTolerance = 0.5;

  final Map<int, Size> _hintSizes = <int, Size>{};
  final Set<int> _visibleHintItems = <int>{};
  final Map<int, int> _hiddenMeasurePasses = <int, int>{};

  @override
  void didUpdateWidget(covariant _SpotlightGuideOverlayLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _hintSizes.clear();
      _visibleHintItems.clear();
      _hiddenMeasurePasses.clear();
    } else if (!_sameOverlayItemMeasurementInputs(
      oldWidget.items,
      widget.items,
    )) {
      _retainHintSizesForCurrentItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final List<Rect> stepTargetRects = widget.targetHoles
        .map((_SpotlightGuideTargetHole hole) => hole.rect)
        .toList(growable: false);
    // Pass-through uses the unpadded target rects so taps only reach the real
    // highlighted widget, not the surrounding target decoration padding (which
    // could sit over an unrelated control on the page).
    final List<Rect> interactiveHoleRects = <Rect>[];
    for (final _SpotlightGuideOverlayItem overlayItem in widget.items) {
      if (overlayItem.item.allowTargetInteraction) {
        interactiveHoleRects.addAll(overlayItem.rawTargetRects);
      }
    }
    final List<_SpotlightGuideRenderedItem> renderedItems =
        <_SpotlightGuideRenderedItem>[];
    for (final _SpotlightGuideOverlayItem overlayItem in widget.items) {
      final Size? hintSize = _hintSizes[overlayItem.itemIndex];
      final SpotlightGuideAnchoredDecoration decoration =
          overlayItem.item.decoration;
      final _HintLayout layout = _HintLayout.compute(
        screenSize: widget.overlaySize,
        targetRect: overlayItem.targetRect,
        step: overlayItem.item,
        textDirection: textDirection,
        hintSize: hintSize,
      );
      final SpotlightGuideStepContext contextInfo = SpotlightGuideStepContext(
        index: widget.index,
        total: widget.total,
        itemIndex: overlayItem.itemIndex,
        // The true number of items in the step, which may exceed the rendered
        // subset while a lazy item's target has not resolved yet.
        itemTotal: widget.step.items.length,
        targetRect: overlayItem.targetRect,
        targetRects: overlayItem.targetRects,
        stepTargetRects: stepTargetRects,
        targetAnchorPoint: layout.targetAnchorPoint,
        targetAnchorPosition: overlayItem.item.targetAnchorPosition,
        overlaySize: widget.overlaySize,
        hintRect: layout.rect,
        margin: layout.margin,
        placement: layout.placement,
        indicatorDirection: layout.indicatorDirection,
        indicatorOffset: layout.indicatorOffset,
        indicatorSafeInset: layout.indicatorSafeInset,
        bubbleIndicatorSideExtent: layout.bubbleIndicatorSideExtent,
        contentSize: hintSize ?? layout.rect.size,
        gap: overlayItem.item.gap,
        decoration: decoration,
        indicatorSize: decoration.anchorSize,
        anchorConnectionHalfExtent: decoration.anchorConnectionHalfExtent,
        controller: widget.controller,
      );
      renderedItems.add(
        _SpotlightGuideRenderedItem(
          overlayItem: overlayItem,
          layout: layout,
          contextInfo: contextInfo,
        ),
      );
    }

    // A transparency Material does not absorb pointer events, which lets taps
    // inside an interactive spotlight hole reach the widget behind the guide.
    // The dim barrier still absorbs everywhere else via [_SpotlightBarrierRegion].
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _buildBarrier(
              interactiveHoleRects,
              textDirection,
              devicePixelRatio,
            ),
          ),
          for (final _SpotlightGuideRenderedItem renderedItem in renderedItems)
            Positioned(
              left: renderedItem.layout.rect.left,
              top: renderedItem.layout.rect.top,
              child: _buildMeasuredHint(context, renderedItem),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasuredHint(
    BuildContext context,
    _SpotlightGuideRenderedItem renderedItem,
  ) {
    final int itemIndex = renderedItem.overlayItem.itemIndex;
    final bool visible = _visibleHintItems.contains(itemIndex);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: Opacity(
          opacity: visible ? 1 : 0,
          alwaysIncludeSemantics: visible,
          child: ConstrainedBox(
            constraints: renderedItem.layout.measureConstraints,
            child: _MeasuredSize(
              key: _hintMeasureKey(renderedItem.overlayItem),
              notifyAlways: !visible,
              onChanged: (Size size) {
                _handleHintSizeChanged(itemIndex, _hintSizes[itemIndex], size);
              },
              // Keep one user-built hint tree alive: it is transparent while
              // measuring and becomes visible only after the overlay has stable
              // geometry. This avoids remounting stateful hints on the first
              // painted frame.
              child: renderedItem.overlayItem.item.hintBuilder(
                context,
                renderedItem.contextInfo,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarrier(
    List<Rect> interactiveHoleRects,
    TextDirection textDirection,
    double devicePixelRatio,
  ) {
    final SpotlightGuideBarrierStyle barrier = widget.barrier;
    final List<Widget> barrierLayers = <Widget>[
      if (barrier.hasBlur)
        ClipPath(
          clipper: _SpotlightBarrierClipper(
            widget.targetHoles,
            textDirection,
            devicePixelRatio,
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: barrier.effectiveBlurSigma,
              sigmaY: barrier.effectiveBlurSigma,
            ),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
      CustomPaint(
        painter: _SpotlightBarrierPainter(
          targetHoles: widget.targetHoles,
          color: barrier.effectiveColor,
          textDirection: textDirection,
          devicePixelRatio: devicePixelRatio,
        ),
      ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: widget.onBarrierTap == null
          ? () {}
          : () => widget.onBarrierTap!(widget.controller),
      child: _SpotlightBarrierRegion(
        interactiveHoles: interactiveHoleRects,
        child: Stack(fit: StackFit.expand, children: barrierLayers),
      ),
    );
  }

  void _handleHintSizeChanged(
    int itemIndex,
    Size? measuredWithSize,
    Size size,
  ) {
    if (!mounted) {
      return;
    }
    final Size? currentSize = _hintSizes[itemIndex];
    final bool alreadyVisible = _visibleHintItems.contains(itemIndex);
    final bool measuredCurrentLayout = _sizesNearlyEqual(
      currentSize,
      measuredWithSize,
    );
    final bool stableForCurrentLayout =
        _sizesNearlyEqual(currentSize, size) && measuredCurrentLayout;
    if (alreadyVisible && !measuredCurrentLayout) {
      return;
    }
    if (stableForCurrentLayout) {
      if (alreadyVisible) {
        return;
      }
      final int hiddenPasses = (_hiddenMeasurePasses[itemIndex] ?? 0) + 1;
      if (hiddenPasses < _minHiddenMeasurePassesBeforeVisible) {
        setState(() {
          _hiddenMeasurePasses[itemIndex] = hiddenPasses;
        });
        return;
      }
      setState(() {
        _visibleHintItems.add(itemIndex);
        _hiddenMeasurePasses.remove(itemIndex);
      });
      return;
    }

    if (_sizesNearlyEqual(currentSize, size)) {
      return;
    }

    final int hiddenPasses = alreadyVisible
        ? 0
        : (_hiddenMeasurePasses[itemIndex] ?? 0) + 1;
    setState(() {
      _hintSizes[itemIndex] = size;
      if (!alreadyVisible) {
        _hiddenMeasurePasses[itemIndex] = hiddenPasses;
        if (hiddenPasses >= _maxHiddenMeasurePasses) {
          _visibleHintItems.add(itemIndex);
          _hiddenMeasurePasses.remove(itemIndex);
        }
      }
    });
  }

  bool _sizesNearlyEqual(Size? a, Size? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return (a.width - b.width).abs() <= _measureTolerance &&
        (a.height - b.height).abs() <= _measureTolerance;
  }

  void _retainHintSizesForCurrentItems() {
    final Set<int> currentItemIndices = widget.items
        .map((_SpotlightGuideOverlayItem item) => item.itemIndex)
        .toSet();
    _hintSizes.removeWhere(
      (int itemIndex, Size size) => !currentItemIndices.contains(itemIndex),
    );
    _visibleHintItems.removeWhere(
      (int itemIndex) => !currentItemIndices.contains(itemIndex),
    );
    _hiddenMeasurePasses.removeWhere(
      (int itemIndex, int count) => !currentItemIndices.contains(itemIndex),
    );
  }

  Key _hintMeasureKey(_SpotlightGuideOverlayItem overlayItem) {
    return ValueKey<String>(
      '${widget.index}:${overlayItem.itemIndex}:'
      '${identityHashCode(overlayItem.item)}',
    );
  }
}

/// Combines one overlay item with its computed layout and public context.
class _SpotlightGuideRenderedItem {
  const _SpotlightGuideRenderedItem({
    required this.overlayItem,
    required this.layout,
    required this.contextInfo,
  });

  final _SpotlightGuideOverlayItem overlayItem;
  final _HintLayout layout;
  final SpotlightGuideStepContext contextInfo;
}

/// Pure layout result for one hint.
class _HintLayout {
  const _HintLayout({
    required this.rect,
    required this.targetAnchorPoint,
    required this.margin,
    required this.placement,
    required this.indicatorOffset,
    required this.indicatorSafeInset,
    required this.bubbleIndicatorSideExtent,
    required this.indicatorDirection,
    required this.measureConstraints,
    required this.expandWidth,
    required this.expandHeight,
  });

  final Rect rect;
  final Offset targetAnchorPoint;
  final EdgeInsets margin;
  final SpotlightGuidePlacement placement;
  final double indicatorOffset;
  final double indicatorSafeInset;
  final double bubbleIndicatorSideExtent;
  final SpotlightGuideIndicatorDirection indicatorDirection;
  final BoxConstraints measureConstraints;
  final bool expandWidth;
  final bool expandHeight;

  static _HintLayout compute({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required TextDirection textDirection,
    Size? hintSize,
  }) {
    final EdgeInsets margin = (step.margin ?? const EdgeInsets.all(16)).resolve(
      textDirection,
    );
    final SpotlightGuidePlacement placement = _resolvePlacement(
      screenSize: screenSize,
      targetRect: targetRect,
      step: step,
      margin: margin,
      hintSize: hintSize,
      textDirection: textDirection,
    );

    return switch (placement) {
      SpotlightGuidePlacement.top => _vertical(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: placement,
        indicatorDirection: SpotlightGuideIndicatorDirection.down,
        textDirection: textDirection,
        hintSize: hintSize,
      ),
      SpotlightGuidePlacement.bottom ||
      SpotlightGuidePlacement.auto => _vertical(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: SpotlightGuidePlacement.bottom,
        indicatorDirection: SpotlightGuideIndicatorDirection.up,
        textDirection: textDirection,
        hintSize: hintSize,
      ),
      SpotlightGuidePlacement.verticalAuto ||
      SpotlightGuidePlacement.horizontalAuto ||
      SpotlightGuidePlacement.start ||
      SpotlightGuidePlacement.end => throw StateError(
        'auto and semantic placements must be resolved before layout',
      ),
      SpotlightGuidePlacement.left => _horizontal(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: placement,
        indicatorDirection: SpotlightGuideIndicatorDirection.right,
        textDirection: textDirection,
        hintSize: hintSize,
      ),
      SpotlightGuidePlacement.right => _horizontal(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: placement,
        indicatorDirection: SpotlightGuideIndicatorDirection.left,
        textDirection: textDirection,
        hintSize: hintSize,
      ),
    };
  }

  static SpotlightGuidePlacement _resolvePlacement({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required EdgeInsets margin,
    required Size? hintSize,
    required TextDirection textDirection,
  }) {
    final SpotlightGuidePlacement placement = _resolveDirectionalPlacement(
      step.placement,
      textDirection,
    );
    if (placement != SpotlightGuidePlacement.auto &&
        placement != SpotlightGuidePlacement.verticalAuto &&
        placement != SpotlightGuidePlacement.horizontalAuto) {
      return placement;
    }

    // Hints are painted in the full-screen overlay, so auto placement must use
    // the overlay's visible area. A target's nearest scrollable parent may be
    // much smaller, but that viewport is only relevant to reveal scrolling.
    final List<_PlacementSpace> verticalSpaces = [
      _PlacementSpace(
        placement: SpotlightGuidePlacement.bottom,
        width: screenSize.width - margin.horizontal,
        height:
            screenSize.height - margin.bottom - targetRect.bottom - step.gap,
      ),
      _PlacementSpace(
        placement: SpotlightGuidePlacement.top,
        width: screenSize.width - margin.horizontal,
        height: targetRect.top - step.gap - margin.top,
      ),
    ];
    final List<_PlacementSpace> horizontalSpaces = [
      _PlacementSpace(
        placement: SpotlightGuidePlacement.right,
        width: screenSize.width - margin.right - targetRect.right - step.gap,
        height: screenSize.height - margin.vertical,
      ),
      _PlacementSpace(
        placement: SpotlightGuidePlacement.left,
        width: targetRect.left - step.gap - margin.left,
        height: screenSize.height - margin.vertical,
      ),
    ];

    final List<_PlacementSpace> spaces = switch (placement) {
      SpotlightGuidePlacement.verticalAuto => verticalSpaces,
      SpotlightGuidePlacement.horizontalAuto => horizontalSpaces,
      SpotlightGuidePlacement.auto => [...verticalSpaces, ...horizontalSpaces],
      SpotlightGuidePlacement.top ||
      SpotlightGuidePlacement.bottom ||
      SpotlightGuidePlacement.left ||
      SpotlightGuidePlacement.right ||
      SpotlightGuidePlacement.start ||
      SpotlightGuidePlacement.end => throw StateError(
        'fixed placements must return before auto resolution',
      ),
    };
    spaces.sort((a, b) => _comparePlacementSpace(a, b, hintSize));
    return spaces.first.placement;
  }

  static SpotlightGuidePlacement _resolveDirectionalPlacement(
    SpotlightGuidePlacement placement,
    TextDirection textDirection,
  ) {
    return switch (placement) {
      SpotlightGuidePlacement.start => switch (textDirection) {
        TextDirection.ltr => SpotlightGuidePlacement.left,
        TextDirection.rtl => SpotlightGuidePlacement.right,
      },
      SpotlightGuidePlacement.end => switch (textDirection) {
        TextDirection.ltr => SpotlightGuidePlacement.right,
        TextDirection.rtl => SpotlightGuidePlacement.left,
      },
      SpotlightGuidePlacement.auto ||
      SpotlightGuidePlacement.verticalAuto ||
      SpotlightGuidePlacement.horizontalAuto ||
      SpotlightGuidePlacement.top ||
      SpotlightGuidePlacement.bottom ||
      SpotlightGuidePlacement.left ||
      SpotlightGuidePlacement.right => placement,
    };
  }

  static int _comparePlacementSpace(
    _PlacementSpace a,
    _PlacementSpace b,
    Size? hintSize,
  ) {
    final int fitComparison = _fitRank(
      b,
      hintSize,
    ).compareTo(_fitRank(a, hintSize));
    if (fitComparison != 0) {
      return fitComparison;
    }
    final int areaComparison = b.area.compareTo(a.area);
    if (areaComparison != 0) {
      return areaComparison;
    }
    final int depthComparison = b.depth.compareTo(a.depth);
    if (depthComparison != 0) {
      return depthComparison;
    }
    return _placementTieBreakRank(
      a.placement,
    ).compareTo(_placementTieBreakRank(b.placement));
  }

  static int _fitRank(_PlacementSpace space, Size? hintSize) {
    if (hintSize == null) {
      return 0;
    }
    const double tolerance = 0.5;
    return space.width + tolerance >= hintSize.width &&
            space.height + tolerance >= hintSize.height
        ? 1
        : 0;
  }

  static int _placementTieBreakRank(SpotlightGuidePlacement placement) {
    return switch (placement) {
      SpotlightGuidePlacement.bottom => 0,
      SpotlightGuidePlacement.top => 1,
      SpotlightGuidePlacement.right => 2,
      SpotlightGuidePlacement.left => 3,
      SpotlightGuidePlacement.auto ||
      SpotlightGuidePlacement.verticalAuto ||
      SpotlightGuidePlacement.horizontalAuto ||
      SpotlightGuidePlacement.start ||
      SpotlightGuidePlacement.end => 4,
    };
  }

  static _HintLayout _vertical({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required EdgeInsets margin,
    required SpotlightGuidePlacement placement,
    required SpotlightGuideIndicatorDirection indicatorDirection,
    required TextDirection textDirection,
    required Size? hintSize,
  }) {
    final double maxWidth = _resolveMaxExtent(
      step.maxWidth,
      screenSize.width - margin.horizontal,
    );
    final double availableHeight = math.max(
      0,
      placement == SpotlightGuidePlacement.bottom
          ? screenSize.height - margin.bottom - targetRect.bottom
          : targetRect.top - margin.top,
    );
    final double maxHeight = _resolveMaxExtent(step.maxHeight, availableHeight);
    final double minWidth = _resolveMinExtent(step.minWidth, maxWidth);
    final double minHeight = _resolveMinExtent(step.minHeight, maxHeight);
    final bool expandWidth = step.maxWidth?.isInfinite == true;
    final bool expandHeight = step.maxHeight?.isInfinite == true;
    final bool hasMeasuredHint = hintSize != null;
    final Offset targetAnchorPoint = _targetAnchorPoint(
      targetRect: targetRect,
      step: step,
      textDirection: textDirection,
      isHorizontalSide: true,
    );
    final double width = expandWidth
        ? maxWidth
        : _resolveExtent(hintSize?.width ?? maxWidth, minWidth, maxWidth);
    final double height = expandHeight
        ? maxHeight
        : _resolveExtent(hintSize?.height ?? maxHeight, minHeight, maxHeight);
    final _AxisLayout arrowSideLayout = _resolveAxisLayout(
      anchor: targetAnchorPoint.dx,
      extent: width,
      minOrigin: margin.left,
      maxEnd: screenSize.width - margin.right,
      maxExtent: maxWidth,
      connectionHalfExtent: step.decoration.anchorConnectionHalfExtent,
      safeInset: step.decoration.anchorSafeInset,
    );
    // The gap is signed in the resolved placement direction. For a top hint,
    // subtracting it moves positive values upward, away from the target.
    final double preferredTop = placement == SpotlightGuidePlacement.bottom
        ? targetRect.bottom + step.gap
        : targetRect.top - step.gap - height;
    final double top = _clampDouble(
      preferredTop,
      margin.top,
      screenSize.height - margin.bottom - height,
    );
    final Rect rect = Rect.fromLTWH(
      arrowSideLayout.origin,
      top,
      arrowSideLayout.extent,
      height,
    );

    return _HintLayout(
      rect: rect,
      targetAnchorPoint: targetAnchorPoint,
      margin: margin,
      placement: placement,
      indicatorOffset: arrowSideLayout.indicatorOffset,
      indicatorSafeInset: arrowSideLayout.safeInset,
      bubbleIndicatorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandWidth,
      ),
      indicatorDirection: indicatorDirection,
      measureConstraints: BoxConstraints(
        minWidth: math.max(
          minWidth,
          _expandedArrowSideMeasureExtent(
            arrowSideLayout,
            expandSideAxis: expandWidth,
            hasMeasuredHint: hasMeasuredHint,
            safeInset: step.decoration.anchorSafeInset,
            maxExtent: maxWidth,
          ),
        ),
        maxWidth: maxWidth,
        minHeight: expandHeight ? maxHeight : minHeight,
        maxHeight: maxHeight,
      ),
      expandWidth: expandWidth,
      expandHeight: expandHeight,
    );
  }

  static _HintLayout _horizontal({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required EdgeInsets margin,
    required SpotlightGuidePlacement placement,
    required SpotlightGuideIndicatorDirection indicatorDirection,
    required TextDirection textDirection,
    required Size? hintSize,
  }) {
    final double availableWidth = math.max(
      0,
      placement == SpotlightGuidePlacement.right
          ? screenSize.width - margin.right - targetRect.right
          : targetRect.left - margin.left,
    );
    final double maxWidth = _resolveMaxExtent(step.maxWidth, availableWidth);
    final double maxHeight = _resolveMaxExtent(
      step.maxHeight,
      screenSize.height - margin.vertical,
    );
    final double minWidth = _resolveMinExtent(step.minWidth, maxWidth);
    final double minHeight = _resolveMinExtent(step.minHeight, maxHeight);
    final bool expandWidth = step.maxWidth?.isInfinite == true;
    final bool expandHeight = step.maxHeight?.isInfinite == true;
    final bool hasMeasuredHint = hintSize != null;
    final Offset targetAnchorPoint = _targetAnchorPoint(
      targetRect: targetRect,
      step: step,
      textDirection: textDirection,
      isHorizontalSide: false,
    );
    final double width = expandWidth
        ? maxWidth
        : _resolveExtent(hintSize?.width ?? maxWidth, minWidth, maxWidth);
    final double height = expandHeight
        ? maxHeight
        : _resolveExtent(hintSize?.height ?? maxHeight, minHeight, maxHeight);
    // The gap is signed in the resolved placement direction. For a left hint,
    // subtracting it moves positive values leftward, away from the target.
    final double left = placement == SpotlightGuidePlacement.right
        ? targetRect.right + step.gap
        : targetRect.left - step.gap - width;
    final _AxisLayout arrowSideLayout = _resolveAxisLayout(
      anchor: targetAnchorPoint.dy,
      extent: height,
      minOrigin: margin.top,
      maxEnd: screenSize.height - margin.bottom,
      maxExtent: maxHeight,
      connectionHalfExtent: step.decoration.anchorConnectionHalfExtent,
      safeInset: step.decoration.anchorSafeInset,
    );
    final double resolvedLeft = _clampDouble(
      left,
      margin.left,
      screenSize.width - margin.right - width,
    );
    final Rect rect = Rect.fromLTWH(
      resolvedLeft,
      arrowSideLayout.origin,
      width,
      arrowSideLayout.extent,
    );

    return _HintLayout(
      rect: rect,
      targetAnchorPoint: targetAnchorPoint,
      margin: margin,
      placement: placement,
      indicatorOffset: arrowSideLayout.indicatorOffset,
      indicatorSafeInset: arrowSideLayout.safeInset,
      bubbleIndicatorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandHeight,
      ),
      indicatorDirection: indicatorDirection,
      measureConstraints: BoxConstraints(
        minWidth: expandWidth ? maxWidth : minWidth,
        maxWidth: maxWidth,
        minHeight: math.max(
          minHeight,
          _expandedArrowSideMeasureExtent(
            arrowSideLayout,
            expandSideAxis: expandHeight,
            hasMeasuredHint: hasMeasuredHint,
            safeInset: step.decoration.anchorSafeInset,
            maxExtent: maxHeight,
          ),
        ),
        maxHeight: maxHeight,
      ),
      expandWidth: expandWidth,
      expandHeight: expandHeight,
    );
  }

  static _AxisLayout _resolveAxisLayout({
    required double anchor,
    required double extent,
    required double minOrigin,
    required double maxEnd,
    required double maxExtent,
    required double connectionHalfExtent,
    required double safeInset,
  }) {
    final double maxResolvedExtent = math.min(
      maxExtent,
      math.max(0, maxEnd - minOrigin),
    );
    final double resolvedExtent = math.min(
      math.max(0, extent),
      maxResolvedExtent,
    );
    final double origin = _baseAxisOrigin(
      anchor: anchor,
      extent: resolvedExtent,
      minOrigin: minOrigin,
      maxEnd: maxEnd,
      connectionHalfExtent: connectionHalfExtent,
    );
    final _AxisLayout base = _AxisLayout(
      origin: origin,
      extent: resolvedExtent,
      indicatorOffset: anchor - origin,
      safeInset: safeInset,
    );
    return _resolveSafeAxisLayout(
      base,
      anchor: anchor,
      minOrigin: minOrigin,
      maxEnd: maxEnd,
      maxExtent: maxResolvedExtent,
      safeInset: safeInset,
    );
  }

  static double _expandedArrowSideExtent(
    _AxisLayout layout, {
    required bool expandSideAxis,
  }) {
    return layout.expanded || expandSideAxis ? layout.extent : 0;
  }

  static double _expandedArrowSideMeasureExtent(
    _AxisLayout layout, {
    required bool expandSideAxis,
    required bool hasMeasuredHint,
    required double safeInset,
    required double maxExtent,
  }) {
    if (expandSideAxis || (hasMeasuredHint && layout.expanded)) {
      return layout.extent;
    }
    if (hasMeasuredHint && safeInset > 0) {
      return math.min(maxExtent, layout.safeInset * 2);
    }
    return 0;
  }

  static double _baseAxisOrigin({
    required double anchor,
    required double extent,
    required double minOrigin,
    required double maxEnd,
    required double connectionHalfExtent,
  }) {
    final double preferredOrigin = anchor - extent / 2;
    final double lowerBound = math.max(
      minOrigin,
      anchor + connectionHalfExtent - extent,
    );
    final double upperBound = math.min(
      maxEnd - extent,
      anchor - connectionHalfExtent,
    );
    if (upperBound >= lowerBound) {
      return _clampDouble(preferredOrigin, lowerBound, upperBound);
    }
    return _clampDouble(preferredOrigin, minOrigin, maxEnd - extent);
  }

  static _AxisLayout _resolveSafeAxisLayout(
    _AxisLayout base, {
    required double anchor,
    required double minOrigin,
    required double maxEnd,
    required double maxExtent,
    required double safeInset,
  }) {
    if (base.extent <= 0) {
      return base;
    }
    if (safeInset <= 0 || _isAnchorSafe(base, safeInset)) {
      return base;
    }

    final _AxisLayout? shifted = _shiftSafeAxisLayout(
      base,
      anchor: anchor,
      minOrigin: minOrigin,
      maxEnd: maxEnd,
      safeInset: safeInset,
    );
    if (shifted != null) {
      return shifted;
    }

    return _expandSafeAxisLayout(
          base,
          anchor: anchor,
          minOrigin: minOrigin,
          maxEnd: maxEnd,
          maxExtent: maxExtent,
          safeInset: safeInset,
        ) ??
        base;
  }

  static _AxisLayout? _shiftSafeAxisLayout(
    _AxisLayout base, {
    required double anchor,
    required double minOrigin,
    required double maxEnd,
    required double safeInset,
  }) {
    final double minSafeOrigin = anchor + safeInset - base.extent;
    final double maxSafeOrigin = anchor - safeInset;
    final double lowerBound = math.max(minOrigin, minSafeOrigin);
    final double upperBound = math.min(maxEnd - base.extent, maxSafeOrigin);
    if (upperBound < lowerBound) {
      return null;
    }
    final double origin = _clampDouble(base.origin, lowerBound, upperBound);
    final _AxisLayout shifted = _AxisLayout(
      origin: origin,
      extent: base.extent,
      indicatorOffset: anchor - origin,
      safeInset: base.safeInset,
    );
    return _isAnchorSafe(shifted, safeInset) ? shifted : null;
  }

  static _AxisLayout? _expandSafeAxisLayout(
    _AxisLayout base, {
    required double anchor,
    required double minOrigin,
    required double maxEnd,
    required double maxExtent,
    required double safeInset,
  }) {
    if (anchor - minOrigin < safeInset || maxEnd - anchor < safeInset) {
      return null;
    }

    final double maxResolvedExtent = math.min(
      maxExtent,
      math.max(0, maxEnd - minOrigin),
    );
    final double extent = math.max(base.extent, safeInset * 2);
    if (extent > maxResolvedExtent) {
      return null;
    }

    final double lowerBound = math.max(minOrigin, anchor + safeInset - extent);
    final double upperBound = math.min(maxEnd - extent, anchor - safeInset);
    if (upperBound < lowerBound) {
      return null;
    }
    final double origin = _clampDouble(base.origin, lowerBound, upperBound);
    final _AxisLayout expanded = _AxisLayout(
      origin: origin,
      extent: extent,
      indicatorOffset: anchor - origin,
      safeInset: base.safeInset,
      expanded: extent > base.extent,
    );
    return _isAnchorSafe(expanded, safeInset) ? expanded : null;
  }

  static bool _isAnchorSafe(_AxisLayout layout, double safeInset) {
    return layout.indicatorOffset >= safeInset &&
        layout.extent - layout.indicatorOffset >= safeInset;
  }

  static double _resolvePositionOffset(
    SpotlightGuideAnchorPosition position, {
    required TextDirection textDirection,
    required bool isHorizontalAxis,
    required double extent,
  }) {
    final bool reverse = isHorizontalAxis && textDirection == TextDirection.rtl;
    final double offset = switch (position.anchor) {
      SpotlightGuideAnchor.center =>
        extent / 2 + (reverse ? -position.offset : position.offset),
      SpotlightGuideAnchor.start =>
        reverse ? extent - position.offset : position.offset,
      SpotlightGuideAnchor.end =>
        reverse ? position.offset : extent - position.offset,
    };
    return offset;
  }

  static double _resolveEffectiveIndicatorOffset(
    double offset, {
    required double extent,
    required double connectionHalfExtent,
    double safeInset = 0,
  }) {
    if (!offset.isFinite || !extent.isFinite || extent <= 0) {
      return 0;
    }
    final double minOffset = math.min(
      math.max(connectionHalfExtent, safeInset),
      extent / 2,
    );
    final double maxOffset = math.max(minOffset, extent - minOffset);
    return offset.clamp(minOffset, maxOffset).toDouble();
  }

  static Offset _targetAnchorPoint({
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required TextDirection textDirection,
    required bool isHorizontalSide,
  }) {
    if (isHorizontalSide) {
      return Offset(
        targetRect.left +
            _resolvePositionOffset(
              step.targetAnchorPosition,
              textDirection: textDirection,
              isHorizontalAxis: true,
              extent: targetRect.width,
            ),
        targetRect.center.dy,
      );
    }
    return Offset(
      targetRect.center.dx,
      targetRect.top +
          _resolvePositionOffset(
            step.targetAnchorPosition,
            textDirection: textDirection,
            isHorizontalAxis: false,
            extent: targetRect.height,
          ),
    );
  }

  static double _clampDouble(double value, double min, double max) {
    if (max < min) {
      return min;
    }
    return value.clamp(min, max).toDouble();
  }

  static double _resolveMaxExtent(double? configured, double available) {
    final double safeAvailable = math.max(0, available);
    if (configured == null || configured.isInfinite) {
      return safeAvailable;
    }
    return math.min(configured, safeAvailable);
  }

  static double _resolveMinExtent(double? configured, double maxExtent) {
    if (configured == null) {
      return 0;
    }
    final double safeConfigured = configured.isInfinite
        ? maxExtent
        : math.max(0, configured);
    return math.min(safeConfigured, maxExtent);
  }

  static double _resolveExtent(
    double extent,
    double minExtent,
    double maxExtent,
  ) {
    return _clampDouble(extent, minExtent, maxExtent);
  }
}

/// Available space candidate used by auto placement selection.
class _PlacementSpace {
  const _PlacementSpace({
    required this.placement,
    required this.width,
    required this.height,
  });

  final SpotlightGuidePlacement placement;
  final double width;
  final double height;

  double get area => math.max(0, width) * math.max(0, height);

  double get depth => math.max(0, math.min(width, height));
}

/// Side-axis layout used to place an arrow on one bubble edge.
class _AxisLayout {
  const _AxisLayout({
    required this.origin,
    required this.extent,
    required this.indicatorOffset,
    required this.safeInset,
    this.expanded = false,
  });

  final double origin;
  final double extent;
  final double indicatorOffset;
  final double safeInset;
  final bool expanded;

  double get arrowGlobal => origin + indicatorOffset;
}
