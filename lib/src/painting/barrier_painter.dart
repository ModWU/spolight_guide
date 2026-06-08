part of '../../spotlight_guide.dart';

/// Paints the dim barrier and cuts the union of all target holes.
class _SpotlightBarrierPainter extends CustomPainter {
  const _SpotlightBarrierPainter({
    required this.targetHoles,
    required this.color,
  });

  final List<_SpotlightGuideTargetHole> targetHoles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _spotlightBarrierPath(size, targetHoles),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightBarrierPainter oldDelegate) {
    return !_sameTargetHoles(oldDelegate.targetHoles, targetHoles) ||
        oldDelegate.color != color;
  }
}

/// Clips barrier-only effects, such as backdrop blur, away from target holes.
class _SpotlightBarrierClipper extends CustomClipper<Path> {
  const _SpotlightBarrierClipper(this.targetHoles);

  final List<_SpotlightGuideTargetHole> targetHoles;

  @override
  Path getClip(Size size) {
    return _spotlightBarrierPath(size, targetHoles);
  }

  @override
  bool shouldReclip(covariant _SpotlightBarrierClipper oldClipper) {
    return !_sameTargetHoles(oldClipper.targetHoles, targetHoles);
  }
}

Path _spotlightBarrierPath(
  Size size,
  List<_SpotlightGuideTargetHole> targetHoles,
) {
  final Path fullPath = Path()..addRect(Offset.zero & size);
  if (targetHoles.isEmpty) {
    return fullPath;
  }

  Path holePath = _targetHolePath(targetHoles.first);
  for (final _SpotlightGuideTargetHole targetHole in targetHoles.skip(1)) {
    holePath = Path.combine(
      PathOperation.union,
      holePath,
      _targetHolePath(targetHole),
    );
  }

  return Path.combine(PathOperation.difference, fullPath, holePath);
}

Path _targetHolePath(_SpotlightGuideTargetHole targetHole) {
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      targetHole.rect,
      Radius.circular(targetHole.radius),
    ),
  );
}

/// Absorbs taps over the dim barrier, except inside [interactiveHoles].
///
/// Taps that land in an interactive hole are not absorbed, so they reach the
/// widget behind the guide. Everywhere else the barrier behaves opaquely.
class _SpotlightBarrierRegion extends SingleChildRenderObjectWidget {
  const _SpotlightBarrierRegion({
    required this.interactiveHoles,
    required super.child,
  });

  final List<Rect> interactiveHoles;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightBarrierRegion(interactiveHoles);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightBarrierRegion renderObject,
  ) {
    renderObject.interactiveHoles = interactiveHoles;
  }
}

/// Render object backing [_SpotlightBarrierRegion].
class _RenderSpotlightBarrierRegion extends RenderProxyBox {
  _RenderSpotlightBarrierRegion(this._interactiveHoles);

  List<Rect> _interactiveHoles;

  set interactiveHoles(List<Rect> value) {
    if (_sameRects(_interactiveHoles, value)) {
      return;
    }
    _interactiveHoles = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) {
      return false;
    }
    for (final Rect hole in _interactiveHoles) {
      if (hole.contains(position)) {
        return false;
      }
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
