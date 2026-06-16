part of '../../spotlight_guide.dart';

/// A speech-bubble widget painted by a [SpotlightGuideAnchoredDecoration].
///
/// The decoration owns the visual shape, padding, border, shadow, anchor size
/// and anchor position. The widget only lays out and clips [child], which keeps
/// styling reusable between built-in hints and custom hint UI.
class SpotlightGuideBubble extends SingleChildRenderObjectWidget {
  const SpotlightGuideBubble({
    super.key,
    required super.child,
    required this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Decoration used to paint and pad this bubble.
  final SpotlightGuideAnchoredDecoration decoration;

  /// Clip behavior applied to the content body.
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightGuideBubble(
      decoration: decoration,
      clipBehavior: clipBehavior,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderSpotlightGuideBubble)
      ..decoration = decoration
      ..clipBehavior = clipBehavior
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

class _RenderSpotlightGuideBubble extends RenderProxyBox {
  _RenderSpotlightGuideBubble({
    required SpotlightGuideAnchoredDecoration decoration,
    required Clip clipBehavior,
    required TextDirection textDirection,
  }) : _decoration = decoration,
       _clipBehavior = clipBehavior,
       _textDirection = textDirection;

  SpotlightGuideAnchoredDecoration _decoration;
  SpotlightGuideAnchoredDecoration? _layoutDecoration;
  BoxPainter? _painter;

  SpotlightGuideAnchoredDecoration get effectiveDecoration {
    return _layoutDecoration ?? _decoration;
  }

  set decoration(SpotlightGuideAnchoredDecoration value) {
    if (_decoration == value) {
      return;
    }
    _decoration = value;
    _layoutDecoration = null;
    _disposePainter();
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

  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  /// Uses a guide-resolved decoration for this layout pass.
  ///
  /// [SpotlightGuideBubbleHint] calls this before laying out the bubble so the
  /// final anchor geometry can be painted in the same frame.
  void useLayoutDecoration(SpotlightGuideAnchoredDecoration decoration) {
    if (_layoutDecoration == decoration) {
      return;
    }
    _layoutDecoration = decoration;
    _disposePainter();
  }

  @override
  void detach() {
    _disposePainter();
    super.detach();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final EdgeInsets padding = effectiveDecoration.padding.resolve(
      _textDirection,
    );
    if (child == null) {
      size = constraints.constrain(Size(padding.horizontal, padding.vertical));
      return;
    }
    child!.layout(constraints.deflate(padding), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        child!.size.width + padding.horizontal,
        child!.size.height + padding.vertical,
      ),
    );
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = Offset(padding.left, padding.top);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final SpotlightGuideAnchoredDecoration decoration = effectiveDecoration;
    _painter ??= decoration.createBoxPainter(markNeedsPaint);
    _painter!.paint(
      context.canvas,
      offset,
      ImageConfiguration(size: size, textDirection: _textDirection),
    );
    if (child == null) {
      return;
    }

    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    final Offset childOffset = offset + childParentData.offset;
    final BorderRadiusGeometry? clipRadius = decoration.contentClipBorderRadius;
    if (clipRadius == null || _clipBehavior == Clip.none) {
      context.paintChild(child!, childOffset);
      return;
    }

    final Rect childBounds = Offset.zero & child!.size;
    final RRect clip = clipRadius.resolve(_textDirection).toRRect(childBounds);
    context.pushClipRRect(needsCompositing, childOffset, childBounds, clip, (
      PaintingContext innerContext,
      Offset innerOffset,
    ) {
      innerContext.paintChild(child!, innerOffset);
    }, clipBehavior: _clipBehavior);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) {
      return false;
    }
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child!.hitTest(result, position: transformed);
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

  void _disposePainter() {
    _painter?.dispose();
    _painter = null;
  }
}
