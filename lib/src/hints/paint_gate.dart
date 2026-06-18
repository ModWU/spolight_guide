part of '../../spotlight_guide.dart';

/// Delays guide overlay painting until custom hint content is ready.
///
/// Place this inside a custom [SpotlightGuideStepItem.hintBuilder] when a hint
/// contains async visual content such as an image or animation and the target
/// hole should not appear before that visual is ready. The widget keeps laying
/// out its child so size changes can settle through the normal Flutter render
/// pipeline, but it reports not-ready to the guide overlay and skips painting
/// while [ready] is false.
///
/// Use [requireNonEmptySize] when the child can briefly report a zero width or
/// height before its natural size is known. This is useful for an `Image` that
/// intentionally only receives a width because the height should follow the
/// decoded aspect ratio.
class SpotlightGuidePaintGate extends SingleChildRenderObjectWidget {
  const SpotlightGuidePaintGate({
    super.key,
    this.ready = true,
    this.requireNonEmptySize = false,
    super.child,
  });

  /// Whether the child is logically ready to be painted.
  final bool ready;

  /// Whether the child must also have a non-empty laid-out size.
  final bool requireNonEmptySize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightGuidePaintGate(
      ready: ready,
      requireNonEmptySize: requireNonEmptySize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderSpotlightGuidePaintGate)
      ..ready = ready
      ..requireNonEmptySize = requireNonEmptySize;
  }
}

class _RenderSpotlightGuidePaintGate extends RenderProxyBox
    implements _HintLayoutParticipant {
  _RenderSpotlightGuidePaintGate({
    required bool ready,
    required bool requireNonEmptySize,
  }) : _ready = ready,
       _requireNonEmptySize = requireNonEmptySize;

  bool _ready;
  bool _hasNonEmptyLayout = false;

  set ready(bool value) {
    if (_ready == value) {
      return;
    }
    _ready = value;
    markNeedsLayout();
  }

  bool _requireNonEmptySize;

  set requireNonEmptySize(bool value) {
    if (_requireNonEmptySize == value) {
      return;
    }
    _requireNonEmptySize = value;
    markNeedsLayout();
  }

  @override
  bool get isPaintReady {
    if (!_ready) {
      return false;
    }
    if (!_requireNonEmptySize) {
      return true;
    }
    return _hasNonEmptyLayout;
  }

  @override
  Offset get layoutOffsetCorrection => Offset.zero;

  @override
  void useLayoutGuide(SpotlightGuideStepContext value) {}

  @override
  void performLayout() {
    super.performLayout();
    _hasNonEmptyLayout = !size.isEmpty;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!isPaintReady) {
      return;
    }
    super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!isPaintReady) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
