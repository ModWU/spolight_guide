part of '../../spotlight_guide.dart';

/// Pure layout result for one hint.
class _HintLayout {
  const _HintLayout({
    required this.rect,
    required this.targetAnchorPoint,
    required this.margin,
    required this.placement,
    required this.anchorOffset,
    required this.anchorSafeInset,
    required this.bubbleAnchorSideExtent,
    required this.anchorDirection,
    required this.hintConstraints,
    required this.measureConstraints,
    required this.expandWidth,
    required this.expandHeight,
  });

  final Rect rect;
  final Offset targetAnchorPoint;
  final EdgeInsets margin;
  final SpotlightGuidePlacement placement;
  final double anchorOffset;
  final double anchorSafeInset;
  final double bubbleAnchorSideExtent;
  final SpotlightGuideDirection anchorDirection;
  final BoxConstraints hintConstraints;
  final BoxConstraints measureConstraints;
  final bool expandWidth;
  final bool expandHeight;

  static _HintLayout compute({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required TextDirection textDirection,
    Size? hintSize,
    double? layoutGap,
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
      layoutGap: layoutGap,
    );

    return switch (placement) {
      SpotlightGuidePlacement.top => _vertical(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: placement,
        anchorDirection: SpotlightGuideDirection.down,
        textDirection: textDirection,
        hintSize: hintSize,
        layoutGap: layoutGap,
      ),
      SpotlightGuidePlacement.bottom ||
      SpotlightGuidePlacement.auto => _vertical(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: SpotlightGuidePlacement.bottom,
        anchorDirection: SpotlightGuideDirection.up,
        textDirection: textDirection,
        hintSize: hintSize,
        layoutGap: layoutGap,
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
        anchorDirection: SpotlightGuideDirection.right,
        textDirection: textDirection,
        hintSize: hintSize,
        layoutGap: layoutGap,
      ),
      SpotlightGuidePlacement.right => _horizontal(
        screenSize: screenSize,
        targetRect: targetRect,
        step: step,
        margin: margin,
        placement: placement,
        anchorDirection: SpotlightGuideDirection.left,
        textDirection: textDirection,
        hintSize: hintSize,
        layoutGap: layoutGap,
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
    required double? layoutGap,
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
            screenSize.height -
            margin.bottom -
            targetRect.bottom -
            _resolvedLayoutGap(step, layoutGap),
      ),
      _PlacementSpace(
        placement: SpotlightGuidePlacement.top,
        width: screenSize.width - margin.horizontal,
        height:
            targetRect.top - _resolvedLayoutGap(step, layoutGap) - margin.top,
      ),
    ];
    final List<_PlacementSpace> horizontalSpaces = [
      _PlacementSpace(
        placement: SpotlightGuidePlacement.right,
        width:
            screenSize.width -
            margin.right -
            targetRect.right -
            _resolvedLayoutGap(step, layoutGap),
        height: screenSize.height - margin.vertical,
      ),
      _PlacementSpace(
        placement: SpotlightGuidePlacement.left,
        width:
            targetRect.left - _resolvedLayoutGap(step, layoutGap) - margin.left,
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

  static double _resolvedLayoutGap(
    SpotlightGuideStepItem step,
    double? layoutGap,
  ) {
    return layoutGap == null
        ? _stepTargetLayoutGap(step)
        : _finiteOrZero(layoutGap);
  }

  static _HintLayout _vertical({
    required Size screenSize,
    required Rect targetRect,
    required SpotlightGuideStepItem step,
    required EdgeInsets margin,
    required SpotlightGuidePlacement placement,
    required SpotlightGuideDirection anchorDirection,
    required TextDirection textDirection,
    required Size? hintSize,
    required double? layoutGap,
  }) {
    final double gap = _resolvedLayoutGap(step, layoutGap);
    final double maxWidth = _resolveMaxExtent(
      step.maxWidth,
      screenSize.width - margin.horizontal,
    );
    final double maxHeight = _resolveMaxExtent(
      step.maxHeight,
      screenSize.height - margin.vertical,
    );
    final double safeMaxWidth = math.max(
      0,
      screenSize.width - margin.horizontal,
    );
    final double safeMaxHeight = math.max(
      0,
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
      isHorizontalSide: true,
    );
    final double width = expandWidth
        ? maxWidth
        : _resolveExtent(hintSize?.width ?? maxWidth, minWidth, maxWidth);
    final double height = expandHeight
        ? maxHeight
        : _resolveExtent(hintSize?.height ?? minHeight, minHeight, maxHeight);
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
        ? targetRect.bottom + gap
        : targetRect.top - gap - height;
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
    final double bodyMinWidth = math.max(
      minWidth,
      _expandedArrowSideMeasureExtent(
        arrowSideLayout,
        expandSideAxis: expandWidth,
        hasMeasuredHint: hasMeasuredHint,
        safeInset: step.decoration.anchorSafeInset,
        maxExtent: maxWidth,
      ),
    );
    final double bodyMinHeight = expandHeight ? maxHeight : minHeight;

    return _HintLayout(
      rect: rect,
      targetAnchorPoint: targetAnchorPoint,
      margin: margin,
      placement: placement,
      anchorOffset: arrowSideLayout.anchorOffset,
      anchorSafeInset: arrowSideLayout.safeInset,
      bubbleAnchorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandWidth,
      ),
      anchorDirection: anchorDirection,
      hintConstraints: BoxConstraints(
        minWidth: bodyMinWidth,
        maxWidth: maxWidth,
        minHeight: bodyMinHeight,
        maxHeight: maxHeight,
      ),
      measureConstraints: BoxConstraints(
        minWidth: bodyMinWidth,
        maxWidth: safeMaxWidth,
        minHeight: bodyMinHeight,
        maxHeight: safeMaxHeight,
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
    required SpotlightGuideDirection anchorDirection,
    required TextDirection textDirection,
    required Size? hintSize,
    required double? layoutGap,
  }) {
    final double gap = _resolvedLayoutGap(step, layoutGap);
    final double sideMaxWidth = placement == SpotlightGuidePlacement.right
        ? screenSize.width - margin.right - targetRect.right - gap
        : targetRect.left - gap - margin.left;
    final double maxWidth = _resolveMaxExtent(
      step.maxWidth,
      math.min(screenSize.width - margin.horizontal, sideMaxWidth),
    );
    final double maxHeight = _resolveMaxExtent(
      step.maxHeight,
      screenSize.height - margin.vertical,
    );
    final double safeMaxWidth = math.max(
      0,
      screenSize.width - margin.horizontal,
    );
    final double safeMaxHeight = math.max(
      0,
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
        : _resolveExtent(hintSize?.width ?? minWidth, minWidth, maxWidth);
    final double height = expandHeight
        ? maxHeight
        : _resolveExtent(hintSize?.height ?? maxHeight, minHeight, maxHeight);
    // The gap is signed in the resolved placement direction. For a left hint,
    // subtracting it moves positive values leftward, away from the target.
    final double left = placement == SpotlightGuidePlacement.right
        ? targetRect.right + gap
        : targetRect.left - gap - width;
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
    final double bodyMinWidth = expandWidth ? maxWidth : minWidth;
    final double bodyMinHeight = math.max(
      minHeight,
      _expandedArrowSideMeasureExtent(
        arrowSideLayout,
        expandSideAxis: expandHeight,
        hasMeasuredHint: hasMeasuredHint,
        safeInset: step.decoration.anchorSafeInset,
        maxExtent: maxHeight,
      ),
    );

    return _HintLayout(
      rect: rect,
      targetAnchorPoint: targetAnchorPoint,
      margin: margin,
      placement: placement,
      anchorOffset: arrowSideLayout.anchorOffset,
      anchorSafeInset: arrowSideLayout.safeInset,
      bubbleAnchorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandHeight,
      ),
      anchorDirection: anchorDirection,
      hintConstraints: BoxConstraints(
        minWidth: bodyMinWidth,
        maxWidth: maxWidth,
        minHeight: bodyMinHeight,
        maxHeight: maxHeight,
      ),
      measureConstraints: BoxConstraints(
        minWidth: bodyMinWidth,
        maxWidth: safeMaxWidth,
        minHeight: bodyMinHeight,
        maxHeight: safeMaxHeight,
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
      anchorOffset: anchor - origin,
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
      anchorOffset: anchor - origin,
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
      anchorOffset: anchor - origin,
      safeInset: base.safeInset,
      expanded: extent > base.extent,
    );
    return _isAnchorSafe(expanded, safeInset) ? expanded : null;
  }

  static bool _isAnchorSafe(_AxisLayout layout, double safeInset) {
    return layout.anchorOffset >= safeInset &&
        layout.extent - layout.anchorOffset >= safeInset;
  }

  static double _resolvePositionOffset(
    SpotlightGuideAnchorPosition position, {
    required TextDirection textDirection,
    required bool isHorizontalAxis,
    required double extent,
  }) {
    final bool reverse = isHorizontalAxis && textDirection == TextDirection.rtl;
    final double positionOffset = _finiteOrZero(position.offset);
    final double offset = switch (position.anchor) {
      SpotlightGuideAnchorAlignment.center =>
        extent / 2 + (reverse ? -positionOffset : positionOffset),
      SpotlightGuideAnchorAlignment.start =>
        reverse ? extent - positionOffset : positionOffset,
      SpotlightGuideAnchorAlignment.end =>
        reverse ? positionOffset : extent - positionOffset,
    };
    return offset;
  }

  static double _resolveEffectiveAnchorOffset(
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
    if (!configured.isFinite) {
      return safeAvailable;
    }
    return math.min(math.max(0, configured), safeAvailable);
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
    required this.anchorOffset,
    required this.safeInset,
    this.expanded = false,
  });

  final double origin;
  final double extent;
  final double anchorOffset;
  final double safeInset;
  final bool expanded;

  double get arrowGlobal => origin + anchorOffset;
}
