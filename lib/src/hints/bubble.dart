part of '../../spotlight_guide.dart';

/// A speech-bubble widget painted by a [SpotlightGuideAnchoredDecoration].
///
/// The decoration owns the visual shape, padding, border, shadow, anchor size
/// and anchor position. The widget only lays out and clips [child], which keeps
/// styling reusable between built-in hints and custom hint UI.
class SpotlightGuideBubble extends StatelessWidget {
  const SpotlightGuideBubble({
    super.key,
    required this.child,
    required this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Content displayed inside the bubble body.
  final Widget child;

  /// Decoration used to paint and pad this bubble.
  final SpotlightGuideAnchoredDecoration decoration;

  /// Clip behavior applied to the content body.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    Widget content = IntrinsicHeight(child: child);
    final BorderRadiusGeometry? clipRadius = decoration.contentClipBorderRadius;
    if (clipRadius != null) {
      content = ClipRRect(
        borderRadius: clipRadius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }
    return Container(decoration: decoration, child: content);
  }
}
