part of '../../spotlight_guide.dart';

bool _sameRects(List<Rect> previous, List<Rect> current) {
  if (previous.length != current.length) {
    return false;
  }
  for (int i = 0; i < previous.length; i++) {
    if (previous[i] != current[i]) {
      return false;
    }
  }
  return true;
}

bool _sameTargetHoles(
  List<_SpotlightGuideTargetHole> previous,
  List<_SpotlightGuideTargetHole> current,
) {
  if (previous.length != current.length) {
    return false;
  }
  for (int i = 0; i < previous.length; i++) {
    if (previous[i].rect != current[i].rect ||
        previous[i].decoration != current[i].decoration) {
      return false;
    }
  }
  return true;
}

List<Object> _uniqueObjects(List<Object> values) {
  final List<Object> result = <Object>[];
  for (final Object value in values) {
    if (result.contains(value)) {
      continue;
    }
    result.add(value);
  }
  return result;
}

extension on Rect {
  Rect inflateRect(EdgeInsets padding) {
    return Rect.fromLTRB(
      left - padding.left,
      top - padding.top,
      right + padding.right,
      bottom + padding.bottom,
    );
  }
}
