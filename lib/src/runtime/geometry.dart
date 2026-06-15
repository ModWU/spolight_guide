part of '../../spotlight_guide.dart';

/// Resolved geometry for one step item target.
class _SpotlightGuideTargetGeometry {
  const _SpotlightGuideTargetGeometry({
    required this.anchorRect,
    required this.rects,
  });

  final Rect anchorRect;
  final List<Rect> rects;
}

/// One registered target rect resolved from a target id.
class _SpotlightGuideResolvedTarget {
  const _SpotlightGuideResolvedTarget({
    required this.id,
    required this.rect,
    this.anchorId,
  });

  final Object id;
  final Rect rect;
  final Object? anchorId;
}

/// One positioned hint item ready to be rendered by the overlay.
class _SpotlightGuideOverlayItem {
  const _SpotlightGuideOverlayItem({
    required this.item,
    required this.itemIndex,
    required this.targetRect,
    required this.targetRects,
    required this.rawTargetRects,
  });

  final SpotlightGuideStepItem item;
  final int itemIndex;
  final Rect targetRect;

  /// Visual hole rects, i.e. target rects expanded by
  /// [SpotlightGuideTargetDecoration.padding] and clipped to the visible
  /// overlay.
  final List<Rect> targetRects;

  /// The unpadded target rects, used for [SpotlightGuideStepItem.allowTargetInteraction]
  /// so taps pass through only over the real widget, not the surrounding padding.
  final List<Rect> rawTargetRects;
}

/// One dim-barrier cutout and optional visual decoration.
class _SpotlightGuideTargetHole {
  const _SpotlightGuideTargetHole({
    required this.rect,
    required this.decoration,
  });

  final Rect rect;
  final SpotlightGuideTargetDecoration decoration;
}
