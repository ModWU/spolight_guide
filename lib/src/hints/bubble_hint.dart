part of '../../spotlight_guide.dart';

/// A common hint container that combines [SpotlightGuideBubble] with an
/// optional visual pointer.
///
/// Without a pointer, the step item's target anchor resolves the anchor
/// position on the target. When [SpotlightGuideStepItem.pointer] participates
/// in the default pointer chain,
/// [SpotlightGuidePointer.pointerAnchorPosition] chooses which point inside
/// the pointer aligns to the target, and
/// [SpotlightGuideStepItem.targetAnchorPosition] chooses which point inside the
/// pointer the bubble anchor aligns to.
class SpotlightGuideBubbleHint extends StatelessWidget {
  const SpotlightGuideBubbleHint({
    super.key,
    required this.guide,
    required this.child,
    this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Resolved layout data for the current step item.
  final SpotlightGuideStepContext guide;

  /// Content displayed inside the bubble body.
  final Widget child;

  /// Optional decoration override.
  ///
  /// When null, [SpotlightGuideStepContext.decoration] is used. Prefer setting
  /// decoration on [SpotlightGuideStepItem] so layout and painting share the
  /// same anchor size.
  final SpotlightGuideAnchoredDecoration? decoration;

  /// Clip behavior applied to the bubble body content.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final SpotlightGuidePointer? pointer = guide.pointer;
    final TextDirection textDirection = Directionality.of(context);
    final Widget? pointerChild = pointer?._buildChild(
      context,
      _pointerContextFor(
        guide: guide,
        pointer: pointer,
        textDirection: textDirection,
      ),
    );
    return _BubbleHintLayout(
      guide: guide,
      decoration: decoration ?? guide.decoration,
      pointer: pointer,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      children: <Widget>[
        SpotlightGuideBubble(
          decoration: decoration ?? guide.decoration,
          clipBehavior: clipBehavior,
          child: IntrinsicHeight(child: child),
        ),
        if (pointerChild != null) IgnorePointer(child: pointerChild),
      ],
    );
  }
}

class _BubbleHintLayout extends MultiChildRenderObjectWidget {
  const _BubbleHintLayout({
    required this.guide,
    required this.decoration,
    required this.pointer,
    required this.textDirection,
    required this.clipBehavior,
    required super.children,
  });

  final SpotlightGuideStepContext guide;
  final SpotlightGuideAnchoredDecoration decoration;
  final SpotlightGuidePointer? pointer;
  final TextDirection textDirection;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBubbleHint(
      guide: guide,
      decoration: decoration,
      pointer: pointer,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderBubbleHint renderObject,
  ) {
    renderObject
      ..guide = guide
      ..decoration = decoration
      ..pointer = pointer
      ..textDirection = textDirection
      ..clipBehavior = clipBehavior;
  }
}

class _BubbleHintParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBubbleHint extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BubbleHintParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BubbleHintParentData>
    implements _HintLayoutParticipant {
  _RenderBubbleHint({
    required SpotlightGuideStepContext guide,
    required SpotlightGuideAnchoredDecoration decoration,
    required SpotlightGuidePointer? pointer,
    required TextDirection textDirection,
    required Clip clipBehavior,
  }) : _guide = guide,
       _decoration = decoration,
       _pointer = pointer,
       _textDirection = textDirection,
       _clipBehavior = clipBehavior;

  SpotlightGuideStepContext _guide;

  set guide(SpotlightGuideStepContext value) {
    if (_guide == value) {
      return;
    }
    _guide = value;
    markNeedsLayout();
  }

  /// Applies geometry resolved by the overlay slot during the current layout.
  ///
  /// This keeps the built-in bubble renderer on the same final geometry as the
  /// public guide object without waiting for a post-frame rebuild.
  @override
  void useLayoutGuide(SpotlightGuideStepContext value) {
    _guide._absorbLayout(value);
    markNeedsLayout();
  }

  SpotlightGuideAnchoredDecoration _decoration;

  set decoration(SpotlightGuideAnchoredDecoration value) {
    if (_decoration == value) {
      return;
    }
    _decoration = value;
    markNeedsLayout();
  }

  SpotlightGuidePointer? _pointer;

  set pointer(SpotlightGuidePointer? value) {
    if (_pointer == value) {
      return;
    }
    _pointer = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  Clip _clipBehavior;

  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
  }

  Offset _bubblePaintOffset = Offset.zero;
  Offset _pointerPaintOffset = Offset.zero;
  Offset _layoutOffsetCorrection = Offset.zero;
  Rect _paintBounds = Rect.zero;
  bool _paintReady = true;

  RenderBox? get _bubbleChild => firstChild;

  RenderBox? get _pointerChild {
    final RenderBox? bubble = _bubbleChild;
    if (bubble == null) {
      return null;
    }
    return childAfter(bubble);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BubbleHintParentData) {
      child.parentData = _BubbleHintParentData();
    }
  }

  @override
  void performLayout() {
    final RenderBox? bubble = _bubbleChild;
    if (bubble == null) {
      size = constraints.smallest;
      return;
    }

    final Size? pointerSize = _layoutPointer();
    _paintReady = _resolvePaintReadiness(pointerSize);
    _BubbleHintBubbleLayout bubbleLayout = _layoutBubble(
      _guide.anchorOffset,
      pointerSize: pointerSize,
    );
    double anchorOffset = _effectiveAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    bubbleLayout = _layoutBubble(anchorOffset, pointerSize: pointerSize);
    final double resolvedAnchorOffset = _effectiveAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    if ((resolvedAnchorOffset - anchorOffset).abs() > 0.01) {
      anchorOffset = resolvedAnchorOffset;
      bubbleLayout = _layoutBubble(anchorOffset, pointerSize: pointerSize);
    }

    final Offset bubbleOffset = _bubbleOffset(
      pointerSize: pointerSize,
      anchorOffset: anchorOffset,
      bubbleSize: bubbleLayout.size,
    );
    final Offset translation = _translationOffset(
      pointerSize: pointerSize,
      anchorOffset: anchorOffset,
      bubbleOffset: bubbleOffset,
      bubbleSize: bubbleLayout.size,
    );

    Offset bubblePaintOffset = translation + bubbleOffset;
    Rect layoutBounds = bubblePaintOffset & bubbleLayout.size;
    Rect paintBounds = layoutBounds;
    final RenderBox? pointer = _pointerChild;
    Offset pointerPaintOffset = Offset.zero;
    if (pointer != null && pointerSize != null) {
      final Offset pointerLayoutOffset =
          translation +
          Offset(
            _pointerLeft(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
            _pointerTop(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleLayout.size,
            ),
          );
      pointerPaintOffset =
          pointerLayoutOffset +
          (_pointer?.visualOffset.resolve(_textDirection) ?? Offset.zero);
      layoutBounds = layoutBounds.expandToInclude(
        pointerLayoutOffset & pointerSize,
      );
      paintBounds = paintBounds.expandToInclude(
        pointerPaintOffset & pointerSize,
      );
    }

    final Offset contentShift = Offset(
      layoutBounds.left < 0 ? -layoutBounds.left : 0,
      layoutBounds.top < 0 ? -layoutBounds.top : 0,
    );
    _layoutOffsetCorrection = -contentShift;
    bubblePaintOffset += contentShift;
    if (pointer != null && pointerSize != null) {
      pointerPaintOffset += contentShift;
    }
    layoutBounds = layoutBounds.shift(contentShift);
    paintBounds = paintBounds.shift(contentShift);

    _bubblePaintOffset = bubblePaintOffset;
    final _BubbleHintParentData bubbleParentData =
        bubble.parentData! as _BubbleHintParentData;
    bubbleParentData.offset = _bubblePaintOffset;

    _pointerPaintOffset = pointerPaintOffset;
    if (pointer != null && pointerSize != null) {
      final _BubbleHintParentData pointerParentData =
          pointer.parentData! as _BubbleHintParentData;
      pointerParentData.offset = _pointerPaintOffset;
    }

    final Size requiredSize = Size(
      math.max(0, layoutBounds.right),
      math.max(0, layoutBounds.bottom),
    );
    size = constraints.constrain(requiredSize);
    _paintBounds = Rect.fromLTWH(
      math.min(0, paintBounds.left),
      math.min(0, paintBounds.top),
      math.max(size.width, paintBounds.right) - math.min(0, paintBounds.left),
      math.max(size.height, paintBounds.bottom) - math.min(0, paintBounds.top),
    );
  }

  Offset _bubbleOffset({
    required Size? pointerSize,
    required double anchorOffset,
    required Size bubbleSize,
  }) {
    if (!_pointerAffectsBubble || pointerSize == null) {
      return Offset.zero;
    }
    final SpotlightGuidePointer pointer = _pointer!;
    final SpotlightGuideBubbleSide placement = _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.bottom => Offset(
          0,
          pointerSize.height + _pointerAnchorGap,
        ),
        SpotlightGuideBubbleSide.right => Offset(
          pointerSize.width + _pointerAnchorGap,
          0,
        ),
        SpotlightGuideBubbleSide.top ||
        SpotlightGuideBubbleSide.left => Offset.zero,
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before bubble offset',
        ),
      };
    }
    final double leading = math.max(
      0,
      pointer.bubbleOffset ??
          switch (_guide.anchorDirection) {
            SpotlightGuideDirection.up =>
              pointerSize.height + _pointerAnchorGap,
            SpotlightGuideDirection.left =>
              pointerSize.width + _pointerAnchorGap,
            SpotlightGuideDirection.down || SpotlightGuideDirection.right => 0,
          },
    );
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => Offset(0, leading),
      SpotlightGuideDirection.left => Offset(leading, 0),
      SpotlightGuideDirection.down ||
      SpotlightGuideDirection.right => Offset.zero,
    };
  }

  BoxConstraints _bubbleConstraints(Size? pointerSize) {
    final Size reserved = _reservedBubbleExtent(pointerSize);
    final BoxConstraints hintConstraints = _guide.hintConstraints;
    double minWidth = math.max(constraints.minWidth, hintConstraints.minWidth);
    double maxWidth = math.min(constraints.maxWidth, hintConstraints.maxWidth);
    double minHeight = math.max(
      constraints.minHeight,
      hintConstraints.minHeight,
    );
    double maxHeight = math.min(
      constraints.maxHeight,
      hintConstraints.maxHeight,
    );
    if (maxWidth.isFinite) {
      maxWidth = math.max(0, maxWidth - reserved.width);
      minWidth = math.min(minWidth, maxWidth);
    }
    if (maxHeight.isFinite) {
      maxHeight = math.max(0, maxHeight - reserved.height);
      minHeight = math.min(minHeight, maxHeight);
    }

    final double extent = _minimumBubbleAnchorSideExtent();
    if (extent.isFinite && extent > 0) {
      switch (_anchorDirection) {
        case SpotlightGuideDirection.up || SpotlightGuideDirection.down:
          minWidth = math.max(minWidth, extent);
          if (maxWidth.isFinite) {
            minWidth = math.min(minWidth, maxWidth);
          }
        case SpotlightGuideDirection.left || SpotlightGuideDirection.right:
          minHeight = math.max(minHeight, extent);
          if (maxHeight.isFinite) {
            minHeight = math.min(minHeight, maxHeight);
          }
      }
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  Size _reservedBubbleExtent(Size? pointerSize) {
    if (!_pointerAffectsBubble || pointerSize == null) {
      return Size.zero;
    }
    final double horizontalAlongExtent = math.max(
      0,
      pointerSize.width + _pointerAnchorGap,
    );
    final double verticalAlongExtent = math.max(
      0,
      pointerSize.height + _pointerAnchorGap,
    );
    return switch (_layoutBubbleSide) {
      SpotlightGuideBubbleSide.along => switch (_guide.anchorDirection) {
        SpotlightGuideDirection.up ||
        SpotlightGuideDirection.down => Size(0, verticalAlongExtent),
        SpotlightGuideDirection.left ||
        SpotlightGuideDirection.right => Size(horizontalAlongExtent, 0),
      },
      SpotlightGuideBubbleSide.top || SpotlightGuideBubbleSide.bottom => Size(
        0,
        math.max(0, pointerSize.height + _pointerAnchorGap),
      ),
      SpotlightGuideBubbleSide.left || SpotlightGuideBubbleSide.right => Size(
        math.max(0, pointerSize.width + _pointerAnchorGap),
        0,
      ),
      SpotlightGuideBubbleSide.start ||
      SpotlightGuideBubbleSide.end => throw StateError(
        'semantic placements are resolved before bubble constraints',
      ),
    };
  }

  double _effectiveAnchorOffset({
    required Size? pointerSize,
    required Size bubbleSize,
  }) {
    final SpotlightGuideDirection anchorDirection = _anchorDirection;
    final bool isHorizontalSide =
        anchorDirection == SpotlightGuideDirection.up ||
        anchorDirection == SpotlightGuideDirection.down;
    final double measuredExtent = isHorizontalSide
        ? bubbleSize.width
        : bubbleSize.height;
    final double extent = math.max(
      measuredExtent,
      _minimumBubbleAnchorSideExtent(),
    );
    if (!extent.isFinite || extent <= 0) {
      return _guide.anchorOffset;
    }
    final double preferredOffset =
        _layoutBubbleSide == SpotlightGuideBubbleSide.along
        ? _guide.anchorOffset
        : extent / 2;
    final double safeOffset = _HintLayout._resolveEffectiveAnchorOffset(
      preferredOffset,
      extent: extent,
      connectionHalfExtent: _guide.anchorConnectionHalfExtent,
      safeInset: _guide.anchorSafeInset,
    );
    return _resolveMarginSafeAnchorOffset(
      safeOffset,
      pointerSize: pointerSize,
      isHorizontalSide: isHorizontalSide,
      extent: extent,
    );
  }

  Offset _translationOffset({
    required Size? pointerSize,
    required double anchorOffset,
    required Offset bubbleOffset,
    required Size bubbleSize,
  }) {
    final Offset preferred = switch (guide.anchorDirection) {
      SpotlightGuideDirection.up || SpotlightGuideDirection.down => Offset(
        _targetContactAxis(isHorizontalAxis: true) -
            guide.hintRect.left -
            _pointerAnchorX(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleSize,
            ),
        _pointer == null || pointerSize == null
            ? 0
            : _pointerAffectsBubble
            ? _pointerTargetTop(pointerSize) -
                  guide.hintRect.top -
                  _pointerTop(
                    pointerSize,
                    anchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
      ),
      SpotlightGuideDirection.left || SpotlightGuideDirection.right => Offset(
        _pointer == null || pointerSize == null
            ? 0
            : _pointerAffectsBubble
            ? _pointerTargetLeft(pointerSize) -
                  guide.hintRect.left -
                  _pointerLeft(
                    pointerSize,
                    anchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
        _targetContactAxis(isHorizontalAxis: false) -
            guide.hintRect.top -
            _pointerAnchorY(
              pointerSize,
              anchorOffset,
              bubbleOffset,
              bubbleSize,
            ),
      ),
    };
    return _clampTranslationToHintRect(
      preferred,
      _contentBounds(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
    );
  }

  Rect _contentBounds(
    Size? pointerSize,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    Rect bounds = Rect.fromLTWH(
      bubbleOffset.dx,
      bubbleOffset.dy,
      bubbleSize.width,
      bubbleSize.height,
    );
    if (_pointer == null || pointerSize == null) {
      return bounds;
    }
    final Rect pointerBounds = Rect.fromLTWH(
      _pointerLeft(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
      _pointerTop(pointerSize, anchorOffset, bubbleOffset, bubbleSize),
      pointerSize.width,
      pointerSize.height,
    );
    bounds = bounds.expandToInclude(pointerBounds);
    return bounds;
  }

  Offset _clampTranslationToHintRect(Offset preferred, Rect contentBounds) {
    if (_pointerAffectsBubble) {
      // Pointer safety is handled by shifting the bubble anchor offset. Clamping
      // the whole stack here would move the pointer away from its target.
      return preferred;
    }

    double minDx = -contentBounds.left;
    double maxDx = guide.hintRect.width - contentBounds.right;
    double minDy = -contentBounds.top;
    double maxDy = guide.hintRect.height - contentBounds.bottom;
    final double dx = _HintLayout._clampDouble(preferred.dx, minDx, maxDx);
    final double dy = _HintLayout._clampDouble(preferred.dy, minDy, maxDy);
    return Offset(dx, dy);
  }

  double _pointerLeft(
    Size size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement = _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top || SpotlightGuideBubbleSide.bottom =>
          bubbleOffset.dx +
              anchorOffset -
              _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
        SpotlightGuideBubbleSide.left =>
          bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
        SpotlightGuideBubbleSide.right => 0,
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before pointer left',
        ),
      };
    }
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up || SpotlightGuideDirection.down =>
        anchorOffset -
            _pointerBubbleOffset(isHorizontalAxis: true, extent: size.width),
      SpotlightGuideDirection.left => 0,
      SpotlightGuideDirection.right =>
        bubbleOffset.dx + bubbleSize.width + _pointerAnchorGap,
    };
  }

  double _pointerTop(
    Size size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement = _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top =>
          bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
        SpotlightGuideBubbleSide.bottom => 0,
        SpotlightGuideBubbleSide.left || SpotlightGuideBubbleSide.right =>
          bubbleOffset.dy +
              anchorOffset -
              _pointerBubbleOffset(
                isHorizontalAxis: false,
                extent: size.height,
              ),
        SpotlightGuideBubbleSide.start ||
        SpotlightGuideBubbleSide.end ||
        SpotlightGuideBubbleSide.along => throw StateError(
          'semantic and along placements are resolved before pointer top',
        ),
      };
    }
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => 0,
      SpotlightGuideDirection.down =>
        bubbleOffset.dy + bubbleSize.height + _pointerAnchorGap,
      SpotlightGuideDirection.left || SpotlightGuideDirection.right =>
        anchorOffset -
            _pointerBubbleOffset(isHorizontalAxis: false, extent: size.height),
    };
  }

  SpotlightGuideStepContext get guide => _guide;

  bool get _pointerAffectsBubble {
    return _pointer?.anchorMode == SpotlightGuidePointerAnchorMode.pointer;
  }

  @override
  double? get targetLayoutGap {
    return _pointerAffectsBubble ? _pointerTargetGap : null;
  }

  @override
  Offset get layoutOffsetCorrection => _layoutOffsetCorrection;

  @override
  bool get isPaintReady => _paintReady;

  double get _pointerAnchorGap {
    return _finiteOrZero(_guide.gap);
  }

  double _pointerTargetLeft(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.left => guide.targetRect.right + targetGap,
      SpotlightGuideDirection.right =>
        guide.targetRect.left - size.width - targetGap,
      SpotlightGuideDirection.up ||
      SpotlightGuideDirection.down => guide.targetRect.left,
    };
  }

  double _pointerTargetTop(Size size) {
    final double targetGap = _pointerTargetGap;
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => guide.targetRect.bottom + targetGap,
      SpotlightGuideDirection.down =>
        guide.targetRect.top - size.height - targetGap,
      SpotlightGuideDirection.left ||
      SpotlightGuideDirection.right => guide.targetRect.top,
    };
  }

  double get _pointerTargetGap {
    return _finiteOrZero(_pointer?.targetGap ?? 0);
  }

  double _targetContactAxis({required bool isHorizontalAxis}) {
    if (!_pointerAffectsBubble) {
      return isHorizontalAxis
          ? guide.targetAnchorPoint.dx
          : guide.targetAnchorPoint.dy;
    }
    return isHorizontalAxis
        ? guide.targetRect.center.dx
        : guide.targetRect.center.dy;
  }

  double _resolveMarginSafeAnchorOffset(
    double offset, {
    required Size? pointerSize,
    required bool isHorizontalSide,
    required double extent,
  }) {
    if (!_pointerAffectsBubble ||
        pointerSize == null ||
        !offset.isFinite ||
        !extent.isFinite ||
        extent <= 0) {
      return offset;
    }

    final Offset anchorPoint = _pointerTargetAnchorPoint(pointerSize);
    final double anchor = isHorizontalSide ? anchorPoint.dx : anchorPoint.dy;
    final EdgeInsets margin = guide.margin;
    final double minOrigin = isHorizontalSide ? margin.left : margin.top;
    final double maxEnd = isHorizontalSide
        ? guide.overlaySize.width - margin.right
        : guide.overlaySize.height - margin.bottom;
    if (!anchor.isFinite || maxEnd <= minOrigin) {
      return offset;
    }

    final double safeInset = math.min(
      math.max(guide.anchorConnectionHalfExtent, guide.anchorSafeInset),
      extent / 2,
    );
    final double safeMin = safeInset;
    final double safeMax = math.max(safeMin, extent - safeInset);
    final double marginMin = anchor + extent - maxEnd;
    final double marginMax = anchor - minOrigin;
    final double minOffset = math.max(safeMin, marginMin);
    final double maxOffset = math.min(safeMax, marginMax);

    if (maxOffset >= minOffset) {
      return _HintLayout._clampDouble(offset, minOffset, maxOffset);
    }

    // If the requested content cannot satisfy both the screen margin and anchor
    // safety, keep the hint inside the margin first. The measured constraints
    // usually shrink the bubble on the next frame; this fallback avoids leaving
    // visible content outside the overlay edge while that happens.
    if (marginMax >= marginMin) {
      return _HintLayout._clampDouble(offset, marginMin, marginMax);
    }

    return _HintLayout._clampDouble(offset, safeMin, safeMax);
  }

  Offset _pointerTargetAnchorPoint(Size size) {
    final double pointerTargetX = _pointerTargetOffset(
      isHorizontalAxis: true,
      extent: size.width,
    );
    final double pointerTargetY = _pointerTargetOffset(
      isHorizontalAxis: false,
      extent: size.height,
    );
    final double pointerBubbleX = _pointerBubbleOffset(
      isHorizontalAxis: true,
      extent: size.width,
    );
    final double pointerBubbleY = _pointerBubbleOffset(
      isHorizontalAxis: false,
      extent: size.height,
    );
    final double targetGap = _pointerTargetGap;
    return Offset(
      switch (guide.anchorDirection) {
        SpotlightGuideDirection.up || SpotlightGuideDirection.down =>
          guide.targetRect.center.dx - pointerTargetX + pointerBubbleX,
        SpotlightGuideDirection.left =>
          guide.targetRect.right + targetGap + pointerBubbleX,
        SpotlightGuideDirection.right =>
          guide.targetRect.left - targetGap - size.width + pointerBubbleX,
      },
      switch (guide.anchorDirection) {
        SpotlightGuideDirection.up =>
          guide.targetRect.bottom + targetGap + pointerBubbleY,
        SpotlightGuideDirection.down =>
          guide.targetRect.top - targetGap - size.height + pointerBubbleY,
        SpotlightGuideDirection.left || SpotlightGuideDirection.right =>
          guide.targetRect.center.dy - pointerTargetY + pointerBubbleY,
      },
    );
  }

  SpotlightGuideBubbleSide get _layoutBubbleSide {
    final SpotlightGuidePointer? pointer = _pointer;
    if (pointer == null) {
      return SpotlightGuideBubbleSide.along;
    }
    return _resolvePointerLayoutBubbleSide(
      pointer: pointer,
      textDirection: _textDirection,
      targetDirection: _guide.anchorDirection,
    );
  }

  SpotlightGuideDirection get _anchorDirection {
    return switch (_layoutBubbleSide) {
      SpotlightGuideBubbleSide.along => _guide.anchorDirection,
      SpotlightGuideBubbleSide.top => SpotlightGuideDirection.down,
      SpotlightGuideBubbleSide.bottom => SpotlightGuideDirection.up,
      SpotlightGuideBubbleSide.left => SpotlightGuideDirection.right,
      SpotlightGuideBubbleSide.right => SpotlightGuideDirection.left,
      SpotlightGuideBubbleSide.start ||
      SpotlightGuideBubbleSide.end => throw StateError(
        'semantic placements are resolved before anchor direction',
      ),
    };
  }

  double _pointerAnchorX(
    Size? size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return anchorOffset;
    }
    return _pointerLeft(size, anchorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: true, extent: size.width);
  }

  double _pointerAnchorY(
    Size? size,
    double anchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return anchorOffset;
    }
    return _pointerTop(size, anchorOffset, bubbleOffset, bubbleSize) +
        _pointerTargetOffset(isHorizontalAxis: false, extent: size.height);
  }

  double _minimumBubbleAnchorSideExtent() {
    final bool sameAxis = _anchorDirection == _guide.anchorDirection;
    final double layoutExtent = sameAxis ? _guide.bubbleAnchorSideExtent : 0;
    final double safeExtent =
        math.max(_guide.anchorConnectionHalfExtent, _guide.anchorSafeInset) * 2;
    return math.max(layoutExtent, safeExtent);
  }

  double _pointerTargetOffset({
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      _pointer!.pointerAnchorPosition,
      textDirection: _textDirection,
      isHorizontalAxis: isHorizontalAxis,
      extent: extent,
    );
  }

  double _pointerBubbleOffset({
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      _guide.targetAnchorPosition,
      textDirection: _textDirection,
      isHorizontalAxis: isHorizontalAxis,
      extent: extent,
    );
  }

  Size? _layoutPointer() {
    final RenderBox? pointer = _pointerChild;
    if (pointer == null || _pointer == null) {
      return null;
    }
    final Size? fixedSize = _pointer!.size;
    final BoxConstraints pointerConstraints = fixedSize == null
        ? BoxConstraints.loose(_finiteConstraintSize())
        : BoxConstraints.tight(_finiteSizeOrZero(fixedSize));
    pointer.layout(pointerConstraints, parentUsesSize: true);
    return pointer.size;
  }

  bool _resolvePaintReadiness(Size? pointerSize) {
    if (_pointerChild == null || _pointer == null || _pointer!.size != null) {
      return true;
    }
    if (pointerSize == null) {
      return true;
    }
    // Width-only images can report a transient zero height before decoding.
    return pointerSize.width.isFinite &&
        pointerSize.height.isFinite &&
        pointerSize.width > 0 &&
        pointerSize.height > 0;
  }

  _BubbleHintBubbleLayout _layoutBubble(
    double anchorOffset, {
    required Size? pointerSize,
  }) {
    final RenderBox bubble = _bubbleChild!;
    final SpotlightGuideAnchoredDecoration resolvedDecoration = _decoration
        .resolveAnchor(
          SpotlightGuideBubbleAnchorGeometry(
            direction: _anchorDirection,
            offset: anchorOffset,
          ),
        );
    if (bubble is _RenderSpotlightGuideBubble) {
      bubble.useLayoutDecoration(resolvedDecoration);
    }
    bubble.layout(_bubbleConstraints(pointerSize), parentUsesSize: true);
    return _BubbleHintBubbleLayout(
      size: bubble.size,
      decoration: resolvedDecoration,
    );
  }

  Size _finiteConstraintSize() {
    double width = constraints.maxWidth;
    double height = constraints.maxHeight;
    if (!width.isFinite) {
      width = _guide.overlaySize.width;
    }
    if (!height.isFinite) {
      height = _guide.overlaySize.height;
    }
    return Size(math.max(0, width), math.max(0, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? bubble = _bubbleChild;
    final RenderBox? pointer = _pointerChild;
    if (bubble == null) {
      return;
    }
    if (!_paintReady) {
      return;
    }
    final SpotlightGuidePointerPaintOrder paintOrder =
        _pointer?.paintOrder ?? SpotlightGuidePointerPaintOrder.belowBubble;
    if (pointer != null &&
        paintOrder == SpotlightGuidePointerPaintOrder.belowBubble) {
      context.paintChild(pointer, offset + _pointerPaintOffset);
    }
    context.paintChild(bubble, offset + _bubblePaintOffset);
    if (pointer != null &&
        paintOrder == SpotlightGuidePointerPaintOrder.aboveBubble) {
      context.paintChild(pointer, offset + _pointerPaintOffset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_paintReady) {
      return false;
    }
    if (!size.contains(position) && !_paintBounds.contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? bubble = _bubbleChild;
    final RenderBox? pointer = _pointerChild;
    final SpotlightGuidePointerPaintOrder paintOrder =
        _pointer?.paintOrder ?? SpotlightGuidePointerPaintOrder.belowBubble;
    if (pointer != null &&
        paintOrder == SpotlightGuidePointerPaintOrder.aboveBubble) {
      if (_hitTestChild(result, pointer, _pointerPaintOffset, position)) {
        return true;
      }
    }
    if (bubble != null &&
        _hitTestChild(result, bubble, _bubblePaintOffset, position)) {
      return true;
    }
    if (pointer != null &&
        paintOrder == SpotlightGuidePointerPaintOrder.belowBubble) {
      return _hitTestChild(result, pointer, _pointerPaintOffset, position);
    }
    return false;
  }

  bool _hitTestChild(
    BoxHitTestResult result,
    RenderBox child,
    Offset childOffset,
    Offset position,
  ) {
    return result.addWithPaintOffset(
      offset: childOffset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final _BubbleHintParentData childParentData =
        child.parentData! as _BubbleHintParentData;
    transform.translateByDouble(
      childParentData.offset.dx,
      childParentData.offset.dy,
      0,
      1,
    );
  }
}

class _BubbleHintBubbleLayout {
  const _BubbleHintBubbleLayout({required this.size, required this.decoration});

  final Size size;
  final SpotlightGuideAnchoredDecoration decoration;
}
