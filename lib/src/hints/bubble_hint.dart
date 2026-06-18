part of '../../spotlight_guide.dart';

/// A common hint container that combines [SpotlightGuideBubble] with an
/// optional visual pointer.
///
/// Without a pointer, the step item's target anchor resolves the anchor
/// position on the target. When [SpotlightGuideStepItem.pointer] participates
/// in the default pointer chain,
/// [SpotlightGuidePointer.pointerTargetPosition] chooses the target point where
/// the pointer is placed, and [SpotlightGuidePointer.anchorPointerPosition]
/// chooses the pointer point that the bubble anchor connects to.
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
      _guide.bubbleAnchorOffset,
      pointerSize: pointerSize,
    );
    double bubbleAnchorOffset = _effectiveBubbleAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    bubbleLayout = _layoutBubble(bubbleAnchorOffset, pointerSize: pointerSize);
    final double resolvedBubbleAnchorOffset = _effectiveBubbleAnchorOffset(
      pointerSize: pointerSize,
      bubbleSize: bubbleLayout.size,
    );
    if ((resolvedBubbleAnchorOffset - bubbleAnchorOffset).abs() > 0.01) {
      bubbleAnchorOffset = resolvedBubbleAnchorOffset;
      bubbleLayout = _layoutBubble(
        bubbleAnchorOffset,
        pointerSize: pointerSize,
      );
    }

    final Offset bubbleOffset = _bubbleOffset(
      pointerSize: pointerSize,
      bubbleAnchorOffset: bubbleAnchorOffset,
      bubbleSize: bubbleLayout.size,
    );
    final Offset translation = _translationOffset(
      pointerSize: pointerSize,
      bubbleAnchorOffset: bubbleAnchorOffset,
      bubbleOffset: bubbleOffset,
      bubbleSize: bubbleLayout.size,
    );

    Offset bubblePaintOffset = translation + bubbleOffset;
    Rect layoutBounds = bubblePaintOffset & bubbleLayout.size;
    Rect paintBounds = layoutBounds;
    final RenderBox? pointer = _pointerChild;
    Offset pointerPaintOffset = Offset.zero;
    if (pointer != null && pointerSize != null) {
      final Offset pointerLayoutOffset = _pointerAffectsBubble
          ? translation +
                Offset(
                  _pointerLeft(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleLayout.size,
                  ),
                  _pointerTop(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleLayout.size,
                  ),
                )
          : _decorativePointerOffset(pointerSize);
      pointerPaintOffset = pointerLayoutOffset;
      if (_pointerAffectsBubble) {
        layoutBounds = layoutBounds.expandToInclude(
          pointerLayoutOffset & pointerSize,
        );
      }
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
    required double bubbleAnchorOffset,
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
          pointerSize.height + _anchorPointerGap,
        ),
        SpotlightGuideBubbleSide.right => Offset(
          pointerSize.width + _anchorPointerGap,
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
              pointerSize.height + _anchorPointerGap,
            SpotlightGuideDirection.left =>
              pointerSize.width + _anchorPointerGap,
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
      pointerSize.width + _anchorPointerGap,
    );
    final double verticalAlongExtent = math.max(
      0,
      pointerSize.height + _anchorPointerGap,
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
        math.max(0, pointerSize.height + _anchorPointerGap),
      ),
      SpotlightGuideBubbleSide.left || SpotlightGuideBubbleSide.right => Size(
        math.max(0, pointerSize.width + _anchorPointerGap),
        0,
      ),
      SpotlightGuideBubbleSide.start ||
      SpotlightGuideBubbleSide.end => throw StateError(
        'semantic placements are resolved before bubble constraints',
      ),
    };
  }

  double _effectiveBubbleAnchorOffset({
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
      return _guide.bubbleAnchorOffset;
    }
    final double preferredOffset = _pointerAffectsBubble
        ? extent / 2
        : _guide.bubbleAnchorOffset;
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
    required double bubbleAnchorOffset,
    required Offset bubbleOffset,
    required Size bubbleSize,
  }) {
    final Offset preferred = switch (guide.anchorDirection) {
      SpotlightGuideDirection.up || SpotlightGuideDirection.down => Offset(
        (_pointerAffectsBubble
                ? guide.pointerTargetPoint.dx
                : guide.anchorTargetPoint.dx) -
            guide.hintRect.left -
            (_pointerAffectsBubble
                ? _pointerCenterX(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
                : bubbleAnchorOffset),
        _pointerAffectsBubble && pointerSize != null
            ? _desiredPointerTop(pointerSize) -
                  guide.hintRect.top -
                  _pointerTop(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
      ),
      SpotlightGuideDirection.left || SpotlightGuideDirection.right => Offset(
        _pointerAffectsBubble && pointerSize != null
            ? _desiredPointerLeft(pointerSize) -
                  guide.hintRect.left -
                  _pointerLeft(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
            : 0,
        (_pointerAffectsBubble
                ? guide.pointerTargetPoint.dy
                : guide.anchorTargetPoint.dy) -
            guide.hintRect.top -
            (_pointerAffectsBubble
                ? _pointerCenterY(
                    pointerSize,
                    bubbleAnchorOffset,
                    bubbleOffset,
                    bubbleSize,
                  )
                : bubbleAnchorOffset),
      ),
    };
    return _clampTranslationToHintRect(
      preferred,
      _contentBounds(pointerSize, bubbleAnchorOffset, bubbleOffset, bubbleSize),
    );
  }

  double _pointerCenterX(
    Size? size,
    double bubbleAnchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return bubbleAnchorOffset;
    }
    return _pointerLeft(size, bubbleAnchorOffset, bubbleOffset, bubbleSize) +
        size.width / 2;
  }

  double _pointerCenterY(
    Size? size,
    double bubbleAnchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    if (_pointer == null || size == null) {
      return bubbleAnchorOffset;
    }
    return _pointerTop(size, bubbleAnchorOffset, bubbleOffset, bubbleSize) +
        size.height / 2;
  }

  Rect _contentBounds(
    Size? pointerSize,
    double bubbleAnchorOffset,
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
    if (!_pointerAffectsBubble) {
      return bounds;
    }
    final Rect pointerBounds = Rect.fromLTWH(
      _pointerLeft(pointerSize, bubbleAnchorOffset, bubbleOffset, bubbleSize),
      _pointerTop(pointerSize, bubbleAnchorOffset, bubbleOffset, bubbleSize),
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
    double bubbleAnchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement = _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top || SpotlightGuideBubbleSide.bottom =>
          bubbleOffset.dx +
              bubbleAnchorOffset -
              _anchorPointerOffset(isHorizontalAxis: true, extent: size.width),
        SpotlightGuideBubbleSide.left =>
          bubbleOffset.dx + bubbleSize.width + _anchorPointerGap,
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
        bubbleAnchorOffset -
            _anchorPointerOffset(isHorizontalAxis: true, extent: size.width),
      SpotlightGuideDirection.left => 0,
      SpotlightGuideDirection.right =>
        bubbleOffset.dx + bubbleSize.width + _anchorPointerGap,
    };
  }

  double _pointerTop(
    Size size,
    double bubbleAnchorOffset,
    Offset bubbleOffset,
    Size bubbleSize,
  ) {
    final SpotlightGuideBubbleSide placement = _layoutBubbleSide;
    if (placement != SpotlightGuideBubbleSide.along) {
      return switch (placement) {
        SpotlightGuideBubbleSide.top =>
          bubbleOffset.dy + bubbleSize.height + _anchorPointerGap,
        SpotlightGuideBubbleSide.bottom => 0,
        SpotlightGuideBubbleSide.left || SpotlightGuideBubbleSide.right =>
          bubbleOffset.dy +
              bubbleAnchorOffset -
              _anchorPointerOffset(
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
        bubbleOffset.dy + bubbleSize.height + _anchorPointerGap,
      SpotlightGuideDirection.left || SpotlightGuideDirection.right =>
        bubbleAnchorOffset -
            _anchorPointerOffset(isHorizontalAxis: false, extent: size.height),
    };
  }

  SpotlightGuideStepContext get guide => _guide;

  bool get _pointerAffectsBubble {
    return _pointer?.anchorMode == SpotlightGuidePointerAnchorMode.pointer;
  }

  @override
  Offset get layoutOffsetCorrection => _layoutOffsetCorrection;

  @override
  bool get isPaintReady => _paintReady;

  double get _anchorPointerGap {
    return _finiteOrZero(_guide.gap);
  }

  double _desiredPointerLeft(Size size) {
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.left => guide.pointerTargetPoint.dx,
      SpotlightGuideDirection.right => guide.pointerTargetPoint.dx - size.width,
      SpotlightGuideDirection.up || SpotlightGuideDirection.down =>
        guide.pointerTargetPoint.dx - size.width / 2,
    };
  }

  double _desiredPointerTop(Size size) {
    return switch (_guide.anchorDirection) {
      SpotlightGuideDirection.up => guide.pointerTargetPoint.dy,
      SpotlightGuideDirection.down => guide.pointerTargetPoint.dy - size.height,
      SpotlightGuideDirection.left || SpotlightGuideDirection.right =>
        guide.pointerTargetPoint.dy - size.height / 2,
    };
  }

  Offset _decorativePointerOffset(Size size) {
    return Offset(
      _desiredPointerLeft(size) - guide.hintRect.left,
      _desiredPointerTop(size) - guide.hintRect.top,
    );
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

    final Offset anchorPoint = _anchorPointerGlobalPoint(pointerSize);
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

  Offset _anchorPointerGlobalPoint(Size size) {
    final double pointerBubbleX = _anchorPointerOffset(
      isHorizontalAxis: true,
      extent: size.width,
    );
    final double pointerBubbleY = _anchorPointerOffset(
      isHorizontalAxis: false,
      extent: size.height,
    );
    return Offset(
      _desiredPointerLeft(size) + pointerBubbleX,
      _desiredPointerTop(size) + pointerBubbleY,
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

  double _minimumBubbleAnchorSideExtent() {
    final bool sameAxis = _anchorDirection == _guide.anchorDirection;
    final double layoutExtent = !_pointerAffectsBubble && sameAxis
        ? _guide.bubbleAnchorSideExtent
        : 0;
    final double safeExtent =
        math.max(_guide.anchorConnectionHalfExtent, _guide.anchorSafeInset) * 2;
    return math.max(layoutExtent, safeExtent);
  }

  double _anchorPointerOffset({
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      _pointer!.anchorPointerPosition,
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
    double bubbleAnchorOffset, {
    required Size? pointerSize,
  }) {
    final RenderBox bubble = _bubbleChild!;
    final SpotlightGuideAnchoredDecoration resolvedDecoration = _decoration
        .resolveAnchor(
          SpotlightGuideBubbleAnchorGeometry(
            direction: _anchorDirection,
            offset: bubbleAnchorOffset,
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
