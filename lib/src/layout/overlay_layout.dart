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
      final SpotlightGuideStepContext guide = inputs.contextFor(
        layout: layout,
        contentSize: layout.rect.size,
      );
      renderedItems.add(
        _SpotlightGuideRenderedItem(
          overlayItem: overlayItem,
          layout: layout,
          inputs: inputs,
          guide: guide,
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
      guide: renderedItem.guide,
      textDirection: Directionality.of(context),
      readiness: _readiness,
      readinessKey: renderedItem.overlayItem.itemIndex,
      child: renderedItem.overlayItem.item.hintBuilder(
        context,
        renderedItem.guide,
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

abstract interface class _HintLayoutParticipant {
  bool get isPaintReady;

  Offset get layoutOffsetCorrection;

  void useLayoutGuide(SpotlightGuideStepContext value);
}

/// Combines one overlay item with its computed layout and public context.
class _SpotlightGuideRenderedItem {
  const _SpotlightGuideRenderedItem({
    required this.overlayItem,
    required this.layout,
    required this.inputs,
    required this.guide,
  });

  final _SpotlightGuideOverlayItem overlayItem;
  final _HintLayout layout;
  final _SpotlightGuideHintLayoutInputs inputs;
  final SpotlightGuideStepContext guide;
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
  }) {
    return _HintLayout.compute(
      screenSize: overlaySize,
      targetRect: overlayItem.targetRect,
      step: overlayItem.item,
      textDirection: textDirection,
      hintSize: hintSize,
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
      anchorTargetPoint: layout.anchorTargetPoint,
      pointerTargetPoint: layout.pointerTargetPoint,
      anchorTargetPosition: overlayItem.item.anchorTargetPosition,
      overlaySize: overlaySize,
      hintRect: layout.rect,
      hintConstraints: layout.hintConstraints,
      margin: layout.margin,
      placement: layout.placement,
      anchorDirection: layout.anchorDirection,
      bubbleAnchorOffset: layout.bubbleAnchorOffset,
      anchorSafeInset: layout.anchorSafeInset,
      bubbleAnchorSideExtent: layout.bubbleAnchorSideExtent,
      contentSize: contentSize,
      gap: overlayItem.item.gap,
      decoration: decoration,
      pointer: overlayItem.item.pointer,
      anchorSize: decoration.anchorSize,
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
    _HintLayout layout = _inputs.layoutFor(
      textDirection: _textDirection,
      hintSize: measuredSize,
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
    final _HintLayoutParticipant? participant = _hintLayoutParticipantOf(
      renderObject,
    );
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
        _offsetsNearlyEqual(a.anchorTargetPoint, b.anchorTargetPoint) &&
        _offsetsNearlyEqual(a.pointerTargetPoint, b.pointerTargetPoint) &&
        (a.bubbleAnchorOffset - b.bubbleAnchorOffset).abs() <=
            _layoutTolerance &&
        a.placement == b.placement &&
        a.anchorDirection == b.anchorDirection &&
        a.hintConstraints == b.hintConstraints &&
        a.measureConstraints == b.measureConstraints;
  }

  bool _rectsNearlyEqual(Rect a, Rect b) {
    return (a.left - b.left).abs() <= _layoutTolerance &&
        (a.top - b.top).abs() <= _layoutTolerance &&
        (a.width - b.width).abs() <= _layoutTolerance &&
        (a.height - b.height).abs() <= _layoutTolerance;
  }

  bool _offsetsNearlyEqual(Offset a, Offset b) {
    return (a.dx - b.dx).abs() <= _layoutTolerance &&
        (a.dy - b.dy).abs() <= _layoutTolerance;
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
    final _HintLayoutParticipant? participant = _hintLayoutParticipantOf(
      renderObject,
    );
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

  _HintLayoutParticipant? _hintLayoutParticipantOf(RenderObject renderObject) {
    if (renderObject is _HintLayoutParticipant) {
      return renderObject as _HintLayoutParticipant;
    }
    return null;
  }
}
