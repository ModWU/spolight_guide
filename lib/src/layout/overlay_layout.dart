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

/// Lays out active hints over the dim barrier.
class _SpotlightGuideOverlayLayoutState
    extends State<_SpotlightGuideOverlayLayout> {
  final _SpotlightGuideOverlayReadiness _readiness =
      _SpotlightGuideOverlayReadiness();

  @override
  void dispose() {
    _readiness.dispose();
    super.dispose();
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
      final _HintLayout layout = _HintLayout.compute(
        screenSize: widget.overlaySize,
        targetRect: overlayItem.targetRect,
        step: overlayItem.item,
        textDirection: textDirection,
        hintSize: null,
      );
      final _SpotlightGuideHintLayoutInputs inputs =
          _SpotlightGuideHintLayoutInputs(
            controller: widget.controller,
            index: widget.index,
            total: widget.total,
            itemTotal: widget.step.items.length,
            overlaySize: widget.overlaySize,
            overlayItem: overlayItem,
            stepTargetRects: stepTargetRects,
          );
      final SpotlightGuideStepContext contextInfo = inputs.contextFor(
        layout: layout,
        contentSize: layout.rect.size,
      );
      renderedItems.add(
        _SpotlightGuideRenderedItem(
          overlayItem: overlayItem,
          layout: layout,
          inputs: inputs,
          contextInfo: contextInfo,
        ),
      );
    }
    _readiness.configure(
      renderedItems.map(
        (_SpotlightGuideRenderedItem item) => item.overlayItem.itemIndex,
      ),
    );

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
            Positioned.fill(child: _buildPositionedHint(context, renderedItem)),
        ],
      ),
    );
  }

  Widget _buildPositionedHint(
    BuildContext context,
    _SpotlightGuideRenderedItem renderedItem,
  ) {
    return _SpotlightGuideHintSlot(
      inputs: renderedItem.inputs,
      guide: renderedItem.contextInfo,
      textDirection: Directionality.of(context),
      readiness: _readiness,
      readinessKey: renderedItem.overlayItem.itemIndex,
      child: renderedItem.overlayItem.item.hintBuilder(
        context,
        renderedItem.contextInfo,
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
            _readiness,
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
          readiness: _readiness,
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
        readiness: _readiness,
        child: Stack(fit: StackFit.expand, children: barrierLayers),
      ),
    );
  }
}

class _SpotlightGuideOverlayReadiness extends ChangeNotifier {
  final Set<int> _pendingItems = <int>{};

  bool get isReady => _pendingItems.isEmpty;

  /// Starts each build with every rendered hint pending.
  ///
  /// Hint slots mark themselves ready during the same layout pass. Barrier
  /// painters and clippers listen to this object through Flutter's repaint and
  /// reclip hooks, so the spotlight holes and hints become visible together.
  void configure(Iterable<int> itemKeys) {
    _pendingItems
      ..clear()
      ..addAll(itemKeys);
  }

  void setItemReady(int itemKey, bool ready) {
    final bool changed = ready
        ? _pendingItems.remove(itemKey)
        : _pendingItems.add(itemKey);
    if (changed) {
      notifyListeners();
    }
  }
}

abstract interface class _SpotlightGuideHintLayoutParticipant {
  bool get isPaintReady;

  double? get targetLayoutGap;

  Offset get layoutOffsetCorrection;

  void useLayoutGuide(SpotlightGuideStepContext value);
}

/// Combines one overlay item with its computed layout and public context.
class _SpotlightGuideRenderedItem {
  const _SpotlightGuideRenderedItem({
    required this.overlayItem,
    required this.layout,
    required this.inputs,
    required this.contextInfo,
  });

  final _SpotlightGuideOverlayItem overlayItem;
  final _HintLayout layout;
  final _SpotlightGuideHintLayoutInputs inputs;
  final SpotlightGuideStepContext contextInfo;
}

class _SpotlightGuideHintLayoutInputs {
  const _SpotlightGuideHintLayoutInputs({
    required this.controller,
    required this.index,
    required this.total,
    required this.itemTotal,
    required this.overlaySize,
    required this.overlayItem,
    required this.stepTargetRects,
  });

  final SpotlightGuidePortalController controller;
  final int index;
  final int total;
  final int itemTotal;
  final Size overlaySize;
  final _SpotlightGuideOverlayItem overlayItem;
  final List<Rect> stepTargetRects;

  _HintLayout layoutFor({
    required TextDirection textDirection,
    required Size? hintSize,
    double? layoutGap,
  }) {
    return _HintLayout.compute(
      screenSize: overlaySize,
      targetRect: overlayItem.targetRect,
      step: overlayItem.item,
      textDirection: textDirection,
      hintSize: hintSize,
      layoutGap: layoutGap,
    );
  }

  SpotlightGuideStepContext contextFor({
    required _HintLayout layout,
    required Size contentSize,
  }) {
    final SpotlightGuideAnchoredDecoration decoration =
        overlayItem.item.decoration;
    return SpotlightGuideStepContext(
      index: index,
      total: total,
      itemIndex: overlayItem.itemIndex,
      // The true number of items in the step, which may exceed the rendered
      // subset while a lazy item's target has not resolved yet.
      itemTotal: itemTotal,
      targetRect: overlayItem.targetRect,
      targetRects: overlayItem.targetRects,
      stepTargetRects: stepTargetRects,
      targetAnchorPoint: layout.targetAnchorPoint,
      targetAnchorPosition: overlayItem.item.targetAnchorPosition,
      overlaySize: overlaySize,
      hintRect: layout.rect,
      hintConstraints: layout.hintConstraints,
      margin: layout.margin,
      placement: layout.placement,
      indicatorDirection: layout.indicatorDirection,
      indicatorOffset: layout.indicatorOffset,
      indicatorSafeInset: layout.indicatorSafeInset,
      bubbleIndicatorSideExtent: layout.bubbleIndicatorSideExtent,
      contentSize: contentSize,
      gap: overlayItem.item.gap,
      decoration: decoration,
      pointer: overlayItem.item.pointer,
      indicatorSize: decoration.anchorSize,
      anchorConnectionHalfExtent: decoration.anchorConnectionHalfExtent,
      controller: controller,
    );
  }
}

class _SpotlightGuideHintSlot extends SingleChildRenderObjectWidget {
  const _SpotlightGuideHintSlot({
    required this.inputs,
    required this.guide,
    required this.textDirection,
    required this.readiness,
    required this.readinessKey,
    required super.child,
  });

  final _SpotlightGuideHintLayoutInputs inputs;
  final SpotlightGuideStepContext guide;
  final TextDirection textDirection;
  final _SpotlightGuideOverlayReadiness readiness;
  final int readinessKey;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightGuideHintSlot(
      inputs: inputs,
      guide: guide,
      textDirection: textDirection,
      readiness: readiness,
      readinessKey: readinessKey,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightGuideHintSlot renderObject,
  ) {
    renderObject
      ..inputs = inputs
      ..guide = guide
      ..textDirection = textDirection
      ..readiness = readiness
      ..readinessKey = readinessKey;
  }
}

class _RenderSpotlightGuideHintSlot extends RenderProxyBox {
  _RenderSpotlightGuideHintSlot({
    required _SpotlightGuideHintLayoutInputs inputs,
    required SpotlightGuideStepContext guide,
    required TextDirection textDirection,
    required _SpotlightGuideOverlayReadiness readiness,
    required int readinessKey,
  }) : _inputs = inputs,
       _guide = guide,
       _textDirection = textDirection,
       _readiness = readiness,
       _readinessKey = readinessKey;

  static const int _maxLayoutPasses = 24;
  static const double _layoutTolerance = 0.01;

  _SpotlightGuideHintLayoutInputs _inputs;

  set inputs(_SpotlightGuideHintLayoutInputs value) {
    if (_inputs == value) {
      return;
    }
    _inputs = value;
    markNeedsLayout();
  }

  SpotlightGuideStepContext _guide;

  set guide(SpotlightGuideStepContext value) {
    if (_guide == value) {
      return;
    }
    _guide = value;
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

  _SpotlightGuideOverlayReadiness _readiness;

  set readiness(_SpotlightGuideOverlayReadiness value) {
    if (_readiness == value) {
      return;
    }
    if (attached) {
      _readiness.removeListener(_handleReadinessChanged);
    }
    _readiness = value;
    if (attached) {
      _readiness.addListener(_handleReadinessChanged);
    }
    markNeedsPaint();
  }

  int _readinessKey;

  set readinessKey(int value) {
    if (_readinessKey == value) {
      return;
    }
    _readinessKey = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _readiness.addListener(_handleReadinessChanged);
  }

  @override
  void detach() {
    _readiness.removeListener(_handleReadinessChanged);
    super.detach();
  }

  void _handleReadinessChanged() {
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(
      Size(_inputs.overlaySize.width, _inputs.overlaySize.height),
    );
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }

    Size? measuredSize;
    final double? layoutGap = _internalTargetGap(child);
    _HintLayout layout = _inputs.layoutFor(
      textDirection: _textDirection,
      hintSize: measuredSize,
      layoutGap: layoutGap,
    );

    for (int pass = 0; pass < _maxLayoutPasses; pass += 1) {
      final SpotlightGuideStepContext guide = _inputs.contextFor(
        layout: layout,
        contentSize: measuredSize ?? layout.rect.size,
      );
      _guide._absorbLayout(guide);
      _updateChildGuide(child, guide);
      child.layout(layout.measureConstraints, parentUsesSize: true);
      final Size nextSize = child.size;
      final _HintLayout nextLayout = _inputs.layoutFor(
        textDirection: _textDirection,
        hintSize: nextSize,
        layoutGap: layoutGap,
      );
      final bool stableSize = _sizesNearlyEqual(measuredSize, nextSize);
      final bool stableLayout = _layoutsNearlyEqual(layout, nextLayout);
      measuredSize = nextSize;
      layout = nextLayout;
      if (stableSize && stableLayout) {
        break;
      }
    }

    final SpotlightGuideStepContext finalGuide = _inputs.contextFor(
      layout: layout,
      contentSize: measuredSize ?? layout.rect.size,
    );
    _guide._absorbLayout(finalGuide);
    _readiness.setItemReady(_readinessKey, _isSubtreePaintReady(child));

    final BoxParentData childParentData = child.parentData! as BoxParentData;
    childParentData.offset =
        layout.rect.topLeft + _layoutOffsetCorrection(child);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    if (!_readiness.isReady) {
      return;
    }
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    context.paintChild(child, offset + childParentData.offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    if (child == null) {
      return false;
    }
    if (!_readiness.isReady) {
      return false;
    }
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    transform.translateByDouble(
      childParentData.offset.dx,
      childParentData.offset.dy,
      0,
      1,
    );
  }

  bool _isSubtreePaintReady(RenderObject renderObject) {
    final _SpotlightGuideHintLayoutParticipant? participant =
        _hintLayoutParticipantOf(renderObject);
    if (participant != null && !participant.isPaintReady) {
      return false;
    }
    bool ready = true;
    renderObject.visitChildren((RenderObject child) {
      if (!ready) {
        return;
      }
      ready = _isSubtreePaintReady(child);
    });
    return ready;
  }

  bool _sizesNearlyEqual(Size? a, Size b) {
    if (a == null) {
      return false;
    }
    return (a.width - b.width).abs() <= _layoutTolerance &&
        (a.height - b.height).abs() <= _layoutTolerance;
  }

  bool _layoutsNearlyEqual(_HintLayout a, _HintLayout b) {
    return _rectsNearlyEqual(a.rect, b.rect) &&
        (a.indicatorOffset - b.indicatorOffset).abs() <= _layoutTolerance &&
        a.placement == b.placement &&
        a.indicatorDirection == b.indicatorDirection &&
        a.hintConstraints == b.hintConstraints &&
        a.measureConstraints == b.measureConstraints;
  }

  bool _rectsNearlyEqual(Rect a, Rect b) {
    return (a.left - b.left).abs() <= _layoutTolerance &&
        (a.top - b.top).abs() <= _layoutTolerance &&
        (a.width - b.width).abs() <= _layoutTolerance &&
        (a.height - b.height).abs() <= _layoutTolerance;
  }

  void _updateChildGuide(RenderBox child, SpotlightGuideStepContext guide) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      _applyLayoutGuide(child, guide);
    });
  }

  void _applyLayoutGuide(
    RenderObject renderObject,
    SpotlightGuideStepContext guide,
  ) {
    _hintLayoutParticipantOf(renderObject)?.useLayoutGuide(guide);
    renderObject.visitChildren((RenderObject child) {
      _applyLayoutGuide(child, guide);
    });
  }

  Offset _layoutOffsetCorrection(RenderObject renderObject) {
    final _SpotlightGuideHintLayoutParticipant? participant =
        _hintLayoutParticipantOf(renderObject);
    if (participant != null) {
      final Offset correction = participant.layoutOffsetCorrection;
      if (correction != Offset.zero) {
        return correction;
      }
    }
    Offset correction = Offset.zero;
    renderObject.visitChildren((RenderObject child) {
      if (correction == Offset.zero) {
        correction = _layoutOffsetCorrection(child);
      }
    });
    return correction;
  }

  double? _internalTargetGap(RenderObject renderObject) {
    final _SpotlightGuideHintLayoutParticipant? participant =
        _hintLayoutParticipantOf(renderObject);
    if (participant != null) {
      final double? targetGap = participant.targetLayoutGap;
      if (targetGap != null) {
        return targetGap;
      }
    }
    double? targetGap;
    renderObject.visitChildren((RenderObject child) {
      targetGap ??= _internalTargetGap(child);
    });
    return targetGap;
  }

  _SpotlightGuideHintLayoutParticipant? _hintLayoutParticipantOf(
    RenderObject renderObject,
  ) {
    if (renderObject is _SpotlightGuideHintLayoutParticipant) {
      return renderObject as _SpotlightGuideHintLayoutParticipant;
    }
    return null;
  }
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
    required this.hintConstraints,
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
        indicatorDirection: SpotlightGuideIndicatorDirection.down,
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
        indicatorDirection: SpotlightGuideIndicatorDirection.up,
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
        indicatorDirection: SpotlightGuideIndicatorDirection.right,
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
        indicatorDirection: SpotlightGuideIndicatorDirection.left,
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
    required SpotlightGuideIndicatorDirection indicatorDirection,
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
      indicatorOffset: arrowSideLayout.indicatorOffset,
      indicatorSafeInset: arrowSideLayout.safeInset,
      bubbleIndicatorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandWidth,
      ),
      indicatorDirection: indicatorDirection,
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
    required SpotlightGuideIndicatorDirection indicatorDirection,
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
      indicatorOffset: arrowSideLayout.indicatorOffset,
      indicatorSafeInset: arrowSideLayout.safeInset,
      bubbleIndicatorSideExtent: _expandedArrowSideExtent(
        arrowSideLayout,
        expandSideAxis: expandHeight,
      ),
      indicatorDirection: indicatorDirection,
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
    final double positionOffset = _finiteOrZero(position.offset);
    final double offset = switch (position.anchor) {
      SpotlightGuideAnchor.center =>
        extent / 2 + (reverse ? -positionOffset : positionOffset),
      SpotlightGuideAnchor.start =>
        reverse ? extent - positionOffset : positionOffset,
      SpotlightGuideAnchor.end =>
        reverse ? positionOffset : extent - positionOffset,
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
