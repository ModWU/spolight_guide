part of '../../spotlight_guide.dart';

/// Paint order used for [SpotlightGuideBubbleHint.pointer].
enum SpotlightGuidePointerLayer {
  /// Paint the pointer below the bubble so pointer lines do not cover content.
  belowBubble,

  /// Paint the pointer above the bubble.
  aboveBubble,
}

/// A common hint container that combines [SpotlightGuideBubble] with an
/// optional pointer/hand image.
///
/// The step item's target anchor resolves the indicator position. When [pointer]
/// is provided, [pointerAnchorPosition] chooses which point inside the pointer
/// aligns to that indicator. Without a pointer, the indicator aligns to the target
/// anchor directly.
class SpotlightGuideBubbleHint extends StatefulWidget {
  const SpotlightGuideBubbleHint({
    super.key,
    required this.guide,
    required this.child,
    this.decoration,
    this.pointer,
    this.pointerSize,
    this.pointerAnchorPosition = const SpotlightGuideAnchorPosition.center(),
    this.pointerLayer = SpotlightGuidePointerLayer.belowBubble,
    this.targetGap,
    this.bubbleBodyOffset = 0,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(pointer == null || pointerSize != null);

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

  /// Optional pointer/hand image painted outside the bubble layout.
  final Widget? pointer;

  /// Required when [pointer] is provided, used to align its anchor to the
  /// bubble indicator.
  final Size? pointerSize;

  /// Controls which point inside [pointer] is aligned with the bubble indicator.
  /// This has no effect when [pointer] is omitted.
  ///
  /// For top/bottom bubbles this is resolved on the pointer's horizontal axis.
  /// For left/right bubbles this is resolved on the pointer's vertical axis.
  /// Horizontal start/end and positive center offsets follow [Directionality].
  final SpotlightGuideAnchorPosition pointerAnchorPosition;

  /// Whether [pointer] paints above or below the bubble.
  final SpotlightGuidePointerLayer pointerLayer;

  /// Distance from the target/pointer to the bubble body on the indicator axis.
  ///
  /// When omitted, [SpotlightGuideStepContext.gap] is used. This value only
  /// matters when [pointer] is provided because plain bubbles already use the
  /// step gap in the outer layout.
  final double? targetGap;

  /// Distance from the hint's leading edge to the bubble body edge on the
  /// indicator axis. For an upward indicator this means: `0 -> bubble at top`,
  /// `100 -> bubble body starts 100px below the hint top`.
  final double bubbleBodyOffset;

  /// Clip behavior applied to the bubble body content.
  final Clip clipBehavior;

  @override
  State<SpotlightGuideBubbleHint> createState() =>
      _SpotlightGuideBubbleHintState();
}

/// Measures the bubble and aligns optional pointer, indicator and target.
class _SpotlightGuideBubbleHintState extends State<SpotlightGuideBubbleHint> {
  Size? _bubbleSize;

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    final Offset bubbleOffset = _bubbleOffset;
    final Size? resolvedPointerSize = widget.pointerSize;
    final double indicatorOffset = _effectiveIndicatorOffset;
    final Offset translation = _translationOffset(
      textDirection,
      resolvedPointerSize,
      indicatorOffset,
    );
    final SpotlightGuideAnchoredDecoration decoration = _baseDecoration
        .resolveAnchor(
          SpotlightGuideAnchorGeometry(
            direction: widget.guide.indicatorDirection,
            offset: indicatorOffset,
          ),
        );

    Widget bubble = ConstrainedBox(
      constraints: _bubbleConstraints,
      child: SpotlightGuideBubble(
        decoration: decoration,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
    );
    bubble = _MeasuredSize(onChanged: _handleBubbleSizeChanged, child: bubble);
    if (bubbleOffset != Offset.zero) {
      bubble = Padding(
        padding: EdgeInsets.only(left: bubbleOffset.dx, top: bubbleOffset.dy),
        child: bubble,
      );
    }

    final Widget? pointer = _buildPointer(
      textDirection,
      resolvedPointerSize,
      indicatorOffset,
    );
    final List<Widget> children = <Widget>[
      if (pointer != null &&
          widget.pointerLayer == SpotlightGuidePointerLayer.belowBubble)
        pointer,
      bubble,
      if (pointer != null &&
          widget.pointerLayer == SpotlightGuidePointerLayer.aboveBubble)
        pointer,
    ];

    final Widget content = Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
    if (translation == Offset.zero) {
      return content;
    }
    return Transform.translate(offset: translation, child: content);
  }

  Widget? _buildPointer(
    TextDirection textDirection,
    Size? size,
    double indicatorOffset,
  ) {
    if (widget.pointer == null || size == null) {
      return null;
    }
    return Positioned(
      left: _pointerLeft(textDirection, size, indicatorOffset),
      top: _pointerTop(textDirection, size, indicatorOffset),
      width: size.width,
      height: _constrainedPointerHeight(size),
      child: IgnorePointer(child: widget.pointer!),
    );
  }

  Offset get _bubbleOffset {
    final double indicatorHeight = widget.guide.indicatorSize.height;
    final double leading = math.max(
      0,
      widget.bubbleBodyOffset - indicatorHeight + _targetGap,
    );
    return switch (widget.guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up => Offset(0, leading),
      SpotlightGuideIndicatorDirection.left => Offset(leading, 0),
      SpotlightGuideIndicatorDirection.down ||
      SpotlightGuideIndicatorDirection.right => Offset.zero,
    };
  }

  BoxConstraints get _bubbleConstraints {
    final double extent = widget.guide.bubbleIndicatorSideExtent;
    if (!extent.isFinite || extent <= 0) {
      return const BoxConstraints();
    }
    return switch (widget.guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down => BoxConstraints(minWidth: extent),
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right => BoxConstraints(
        minHeight: extent,
      ),
    };
  }

  double get _effectiveIndicatorOffset {
    final bool isHorizontalSide =
        widget.guide.indicatorDirection ==
            SpotlightGuideIndicatorDirection.up ||
        widget.guide.indicatorDirection ==
            SpotlightGuideIndicatorDirection.down;
    final double measuredExtent = isHorizontalSide
        ? (_bubbleSize?.width ?? _initialBubbleWidth)
        : (_bubbleSize?.height ?? _initialBubbleHeight);
    final double extent = math.max(
      measuredExtent,
      widget.guide.bubbleIndicatorSideExtent,
    );
    if (!extent.isFinite || extent <= 0) {
      return widget.guide.indicatorOffset;
    }
    return _HintLayout._resolveEffectiveIndicatorOffset(
      widget.guide.indicatorOffset,
      extent: extent,
      connectionHalfExtent: widget.guide.anchorConnectionHalfExtent,
      safeInset: widget.guide.indicatorSafeInset,
    );
  }

  Offset _translationOffset(
    TextDirection textDirection,
    Size? size,
    double indicatorOffset,
  ) {
    return switch (guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down => Offset(
        guide.targetAnchorPoint.dx - guide.hintRect.left - indicatorOffset,
        widget.pointer == null || size == null
            ? 0
            : guide.targetRect.top -
                  guide.hintRect.top -
                  _pointerTop(textDirection, size, indicatorOffset),
      ),
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right => Offset(
        widget.pointer == null || size == null
            ? 0
            : guide.targetRect.left -
                  guide.hintRect.left -
                  _pointerLeft(textDirection, size, indicatorOffset),
        guide.targetAnchorPoint.dy - guide.hintRect.top - indicatorOffset,
      ),
    };
  }

  double? _constrainedPointerHeight(Size size) {
    return switch (widget.guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down => null,
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right => size.height,
    };
  }

  double _pointerLeft(
    TextDirection textDirection,
    Size size,
    double indicatorOffset,
  ) {
    return switch (widget.guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up ||
      SpotlightGuideIndicatorDirection.down =>
        indicatorOffset -
            _pointerIndicatorOffset(
              textDirection: textDirection,
              isHorizontalAxis: true,
              extent: size.width,
            ),
      SpotlightGuideIndicatorDirection.left => 0,
      SpotlightGuideIndicatorDirection.right =>
        _bubbleOffset.dx + _effectiveBubbleWidth + _targetGap,
    };
  }

  double _pointerTop(
    TextDirection textDirection,
    Size size,
    double indicatorOffset,
  ) {
    return switch (widget.guide.indicatorDirection) {
      SpotlightGuideIndicatorDirection.up => 0,
      SpotlightGuideIndicatorDirection.down =>
        _bubbleOffset.dy + _effectiveBubbleHeight + _targetGap,
      SpotlightGuideIndicatorDirection.left ||
      SpotlightGuideIndicatorDirection.right =>
        indicatorOffset -
            _pointerIndicatorOffset(
              textDirection: textDirection,
              isHorizontalAxis: false,
              extent: size.height,
            ),
    };
  }

  SpotlightGuideStepContext get guide => widget.guide;

  SpotlightGuideAnchoredDecoration get _baseDecoration {
    return widget.decoration ?? widget.guide.decoration;
  }

  bool get _hasHorizontalIndicatorSide {
    return widget.guide.indicatorDirection ==
            SpotlightGuideIndicatorDirection.up ||
        widget.guide.indicatorDirection ==
            SpotlightGuideIndicatorDirection.down;
  }

  double get _targetGap {
    if (widget.pointer == null) {
      return 0;
    }
    return math.max(0, widget.targetGap ?? widget.guide.gap);
  }

  double get _effectiveBubbleWidth {
    final double measuredWidth = _bubbleSize?.width ?? _initialBubbleWidth;
    final double layoutWidth = _hasHorizontalIndicatorSide
        ? widget.guide.bubbleIndicatorSideExtent
        : widget.guide.contentSize.width;
    return math.max(measuredWidth, layoutWidth);
  }

  double get _effectiveBubbleHeight {
    final double measuredHeight = _bubbleSize?.height ?? _initialBubbleHeight;
    final double layoutHeight = _hasHorizontalIndicatorSide
        ? widget.guide.contentSize.height
        : widget.guide.bubbleIndicatorSideExtent;
    return math.max(measuredHeight, layoutHeight);
  }

  double get _initialBubbleWidth {
    return math.max(0, widget.guide.contentSize.width - _bubbleOffset.dx);
  }

  double get _initialBubbleHeight {
    return math.max(0, widget.guide.contentSize.height - _bubbleOffset.dy);
  }

  void _handleBubbleSizeChanged(Size size) {
    if (_bubbleSize == size || !mounted) {
      return;
    }
    setState(() {
      _bubbleSize = size;
    });
  }

  double _pointerIndicatorOffset({
    required TextDirection textDirection,
    required bool isHorizontalAxis,
    required double extent,
  }) {
    return _HintLayout._resolvePositionOffset(
      widget.pointerAnchorPosition,
      textDirection: textDirection,
      isHorizontalAxis: isHorizontalAxis,
      extent: extent,
    );
  }
}
