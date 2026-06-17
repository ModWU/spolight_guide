part of '../../spotlight_guide.dart';

/// Paints the dim barrier and cuts the union of all target holes.
class _SpotlightBarrierPainter extends CustomPainter {
  const _SpotlightBarrierPainter({
    required this.targetHoles,
    required this.color,
    required this.textDirection,
    required this.devicePixelRatio,
    required this.readiness,
  }) : super(repaint: readiness);

  final List<_SpotlightGuideTargetHole> targetHoles;
  final Color color;
  final TextDirection textDirection;
  final double devicePixelRatio;
  final _SpotlightGuideOverlayReadiness readiness;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final List<_SpotlightGuideTargetHole> visibleTargetHoles = readiness.isReady
        ? targetHoles
        : const <_SpotlightGuideTargetHole>[];

    if (visibleTargetHoles.isEmpty) {
      canvas.drawRect(bounds, Paint()..color = color);
      return;
    }

    if (!_needsTargetHoleClearingLayer(visibleTargetHoles)) {
      canvas.drawPath(
        _spotlightBarrierPath(
          size,
          visibleTargetHoles,
          textDirection,
          devicePixelRatio,
        ),
        Paint()..color = color,
      );
      _paintTargetRingLayers(
        canvas,
        _collectTargetRingLayers(
          size,
          visibleTargetHoles,
          textDirection,
          devicePixelRatio,
        ),
      );
      return;
    }

    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = color);
    final List<_DeferredTargetRingLayer> deferredRingLayers =
        _paintTargetDecorations(
          canvas,
          size,
          visibleTargetHoles,
          textDirection,
          devicePixelRatio,
        );
    _clearTargetHoles(
      canvas,
      visibleTargetHoles,
      textDirection,
      devicePixelRatio,
    );
    _paintTargetRingLayers(canvas, deferredRingLayers);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightBarrierPainter oldDelegate) {
    return !_sameTargetHoles(oldDelegate.targetHoles, targetHoles) ||
        oldDelegate.color != color ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.devicePixelRatio != devicePixelRatio ||
        oldDelegate.readiness != readiness;
  }
}

/// Clips barrier-only effects, such as backdrop blur, away from target holes.
class _SpotlightBarrierClipper extends CustomClipper<Path> {
  const _SpotlightBarrierClipper(
    this.targetHoles,
    this.textDirection,
    this.devicePixelRatio,
    this.readiness,
  ) : super(reclip: readiness);

  final List<_SpotlightGuideTargetHole> targetHoles;
  final TextDirection textDirection;
  final double devicePixelRatio;
  final _SpotlightGuideOverlayReadiness readiness;

  @override
  Path getClip(Size size) {
    return _spotlightBarrierPath(
      size,
      readiness.isReady ? targetHoles : const <_SpotlightGuideTargetHole>[],
      textDirection,
      devicePixelRatio,
    );
  }

  @override
  bool shouldReclip(covariant _SpotlightBarrierClipper oldClipper) {
    return !_sameTargetHoles(oldClipper.targetHoles, targetHoles) ||
        oldClipper.textDirection != textDirection ||
        oldClipper.devicePixelRatio != devicePixelRatio ||
        oldClipper.readiness != readiness;
  }
}

bool _needsTargetHoleClearingLayer(
  List<_SpotlightGuideTargetHole> targetHoles,
) {
  for (final _SpotlightGuideTargetHole targetHole in targetHoles) {
    for (final SpotlightGuideTargetLayer layer
        in targetHole.decoration.layers) {
      if (layer is! SpotlightGuideTargetRingLayer) {
        return true;
      }
    }
  }
  return false;
}

List<_DeferredTargetRingLayer> _collectTargetRingLayers(
  Size size,
  List<_SpotlightGuideTargetHole> targetHoles,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  final List<_DeferredTargetRingLayer> ringLayers =
      <_DeferredTargetRingLayer>[];
  for (final _SpotlightGuideTargetHole targetHole in targetHoles) {
    final SpotlightGuideTargetDecoration decoration = targetHole.decoration;
    if (decoration.layers.isEmpty) {
      continue;
    }
    final SpotlightGuideTargetPaintContext context =
        SpotlightGuideTargetPaintContext(
          rect: targetHole.rect,
          overlaySize: size,
          textDirection: textDirection,
          shape: decoration.shape,
          devicePixelRatio: devicePixelRatio,
        );
    for (final SpotlightGuideTargetLayer layer in decoration.layers) {
      if (layer is SpotlightGuideTargetRingLayer) {
        ringLayers.add(
          _DeferredTargetRingLayer(context: context, layer: layer),
        );
      }
    }
  }
  return ringLayers;
}

List<_DeferredTargetRingLayer> _paintTargetDecorations(
  Canvas canvas,
  Size size,
  List<_SpotlightGuideTargetHole> targetHoles,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  final List<_DeferredTargetRingLayer> ringLayers =
      <_DeferredTargetRingLayer>[];
  for (final _SpotlightGuideTargetHole targetHole in targetHoles) {
    final SpotlightGuideTargetDecoration decoration = targetHole.decoration;
    if (decoration.layers.isEmpty) {
      continue;
    }
    final SpotlightGuideTargetPaintContext context =
        SpotlightGuideTargetPaintContext(
          rect: targetHole.rect,
          overlaySize: size,
          textDirection: textDirection,
          shape: decoration.shape,
          devicePixelRatio: devicePixelRatio,
        );
    for (final SpotlightGuideTargetLayer layer in decoration.layers) {
      if (layer is SpotlightGuideTargetRingLayer) {
        ringLayers.add(
          _DeferredTargetRingLayer(context: context, layer: layer),
        );
      } else {
        layer.paint(canvas, context);
      }
    }
  }
  return ringLayers;
}

void _paintTargetRingLayers(
  Canvas canvas,
  List<_DeferredTargetRingLayer> ringLayers,
) {
  for (final _DeferredTargetRingLayer ringLayer in ringLayers) {
    ringLayer.layer.paint(canvas, ringLayer.context);
  }
}

class _DeferredTargetRingLayer {
  const _DeferredTargetRingLayer({required this.context, required this.layer});

  final SpotlightGuideTargetPaintContext context;
  final SpotlightGuideTargetRingLayer layer;
}

void _clearTargetHoles(
  Canvas canvas,
  List<_SpotlightGuideTargetHole> targetHoles,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  if (targetHoles.isEmpty) {
    return;
  }
  canvas.drawPath(
    _targetHolesPath(targetHoles, textDirection, devicePixelRatio),
    Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.clear,
  );
}

Path _spotlightBarrierPath(
  Size size,
  List<_SpotlightGuideTargetHole> targetHoles,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  final Path fullPath = Path()..addRect(Offset.zero & size);
  if (targetHoles.isEmpty) {
    return fullPath;
  }

  final Path holePath = _targetHolesPath(
    targetHoles,
    textDirection,
    devicePixelRatio,
  );
  return Path.combine(PathOperation.difference, fullPath, holePath);
}

Path _targetHolesPath(
  List<_SpotlightGuideTargetHole> targetHoles,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  Path holePath = _targetHolePath(
    targetHoles.first,
    textDirection,
    devicePixelRatio,
  );
  for (final _SpotlightGuideTargetHole targetHole in targetHoles.skip(1)) {
    holePath = Path.combine(
      PathOperation.union,
      holePath,
      _targetHolePath(targetHole, textDirection, devicePixelRatio),
    );
  }
  return holePath;
}

Path _targetHolePath(
  _SpotlightGuideTargetHole targetHole,
  TextDirection textDirection,
  double devicePixelRatio,
) {
  return targetHole.decoration.shape.createPath(
    rect: _snapRectToPhysicalPixels(targetHole.rect, devicePixelRatio),
    textDirection: textDirection,
  );
}

/// Absorbs taps over the dim barrier, except inside [interactiveHoles].
///
/// Taps that land in an interactive hole are not absorbed, so they reach the
/// widget behind the guide. Everywhere else the barrier behaves opaquely.
class _SpotlightBarrierRegion extends SingleChildRenderObjectWidget {
  const _SpotlightBarrierRegion({
    required this.interactiveHoles,
    required this.readiness,
    required super.child,
  });

  final List<Rect> interactiveHoles;
  final _SpotlightGuideOverlayReadiness readiness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightBarrierRegion(interactiveHoles, readiness);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightBarrierRegion renderObject,
  ) {
    renderObject
      ..interactiveHoles = interactiveHoles
      ..readiness = readiness;
  }
}

/// Render object backing [_SpotlightBarrierRegion].
class _RenderSpotlightBarrierRegion extends RenderProxyBox {
  _RenderSpotlightBarrierRegion(this._interactiveHoles, this._readiness);

  List<Rect> _interactiveHoles;

  set interactiveHoles(List<Rect> value) {
    if (_sameRects(_interactiveHoles, value)) {
      return;
    }
    _interactiveHoles = value;
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
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) {
      return false;
    }
    if (_readiness.isReady) {
      for (final Rect hole in _interactiveHoles) {
        if (hole.contains(position)) {
          return false;
        }
      }
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
