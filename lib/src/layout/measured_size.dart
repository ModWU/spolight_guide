part of '../../spotlight_guide.dart';

/// Render helper that reports its child's laid-out size after a frame.
class _MeasuredSize extends SingleChildRenderObjectWidget {
  const _MeasuredSize({
    super.key,
    required this.onChanged,
    this.notifyAlways = false,
    required super.child,
  });

  final ValueChanged<Size> onChanged;
  final bool notifyAlways;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasuredSize(onChanged, notifyAlways: notifyAlways);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasuredSize renderObject,
  ) {
    renderObject
      ..onChanged = onChanged
      ..notifyAlways = notifyAlways;
  }
}

/// Render object backing [_MeasuredSize].
class _RenderMeasuredSize extends RenderProxyBox {
  _RenderMeasuredSize(this.onChanged, {required bool notifyAlways})
    : _notifyAlways = notifyAlways;

  ValueChanged<Size> onChanged;
  bool _notifyAlways;
  Size? _oldSize;
  Size? _lastNotifiedSize;

  bool get notifyAlways => _notifyAlways;

  set notifyAlways(bool value) {
    if (_notifyAlways == value) {
      return;
    }
    _notifyAlways = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? size;
    if (!notifyAlways && _oldSize == newSize) {
      return;
    }
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!notifyAlways && _lastNotifiedSize == newSize) {
        return;
      }
      _lastNotifiedSize = newSize;
      onChanged(newSize);
      if (notifyAlways && attached) {
        markNeedsLayout();
      }
    });
  }
}
