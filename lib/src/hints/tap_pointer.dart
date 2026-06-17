part of '../../spotlight_guide.dart';

/// A small built-in tap pointer that can be used in
/// [SpotlightGuidePointer.child].
///
/// It avoids requiring an image asset for the common "tap here" guide pattern.
/// Use a custom widget or `Image.asset` when the pointer should match product
/// illustration assets.
class SpotlightGuideTapPointer extends StatelessWidget {
  const SpotlightGuideTapPointer({
    super.key,
    this.color,
    this.backgroundColor,
    this.ringColor,
    this.icon = Icons.touch_app_rounded,
    this.iconSize = 30,
    this.shadowColor = const Color(0x33000000),
  });

  /// Recommended [SpotlightGuidePointer.size].
  static const Size defaultSize = Size(64, 64);

  /// Natural direction of the built-in tap icon before any rotation is applied.
  ///
  /// Pass this to [SpotlightGuidePointerContext.rotationToTarget] when the
  /// built-in tap pointer should face the resolved target direction.
  static const SpotlightGuidePointerDirection naturalDirection =
      SpotlightGuidePointerDirection.up();

  /// Icon and primary ring color.
  final Color? color;

  /// Center circle background.
  final Color? backgroundColor;

  /// Outer ring color. Defaults to [color] with lower opacity.
  final Color? ringColor;

  /// Icon drawn in the center circle.
  final IconData icon;

  /// Center icon size before the whole pointer is scaled by its parent.
  final double iconSize;

  /// Shadow color behind the center circle.
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color resolvedColor = color ?? scheme.primary;
    final Color resolvedBackground =
        backgroundColor ?? scheme.surface.withValues(alpha: 0.96);
    final Color resolvedRing =
        ringColor ?? resolvedColor.withValues(alpha: 0.24);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: defaultSize.width,
        height: defaultSize.height,
        child: CustomPaint(
          painter: _SpotlightGuideTapPointerPainter(
            ringColor: resolvedRing,
            shadowColor: shadowColor,
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolvedBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: resolvedColor.withValues(alpha: 0.34),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: 42,
                child: Icon(icon, color: resolvedColor, size: iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightGuideTapPointerPainter extends CustomPainter {
  const _SpotlightGuideTapPointerPainter({
    required this.ringColor,
    required this.shadowColor,
  });

  final Color ringColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        !size.width.isFinite ||
        !size.height.isFinite) {
      return;
    }
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 3;
    if (radius <= 0 || !radius.isFinite) {
      return;
    }
    final Paint outerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = ringColor.withValues(alpha: ringColor.a * 0.28);
    final Paint outerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = ringColor;
    final Paint shadow = Paint()
      ..style = PaintingStyle.fill
      ..color = shadowColor.withValues(alpha: shadowColor.a * 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas
      ..drawCircle(center.translate(0, 3), radius - 3, shadow)
      ..drawCircle(center, radius, outerFill)
      ..drawCircle(center, radius, outerStroke);
  }

  @override
  bool shouldRepaint(covariant _SpotlightGuideTapPointerPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
