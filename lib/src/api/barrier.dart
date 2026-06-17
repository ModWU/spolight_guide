part of '../../spotlight_guide.dart';

/// Visual style for the full-screen barrier behind a guide step.
///
/// The barrier is step-level state because it describes the atmosphere around
/// all hints in that step. Target holes, hole padding, hole radius and target
/// interaction stay on [SpotlightGuideStepItem] because each highlighted widget
/// can need different treatment.
///
/// [blurSigma] is clipped to the dimmed barrier shape, so spotlight holes remain
/// sharp and keep the original target brightness/clarity.
///
/// Example:
///
/// ```dart
/// SpotlightGuidePortal(
///   barrier: const SpotlightGuideBarrierStyle(
///     color: Color(0x8C000000),
///     blurSigma: 4,
///   ),
///   steps: <SpotlightGuideStep>[
///     SpotlightGuideStep(
///       // Only color is overridden here; blurSigma is inherited from portal.
///       barrier: SpotlightGuideBarrierStyle(color: Colors.black54),
///       items: items,
///     ),
///   ],
///   child: page,
/// )
/// ```
class SpotlightGuideBarrierStyle {
  const SpotlightGuideBarrierStyle({this.color, this.blurSigma})
    : assert(
        blurSigma == null || blurSigma >= 0,
        'blurSigma must not be negative.',
      );

  /// Built-in fallback used before portal and step styles are merged.
  static const SpotlightGuideBarrierStyle fallback = SpotlightGuideBarrierStyle(
    color: Color(0x99000000),
    blurSigma: 0,
  );

  /// Color painted over the non-highlighted area.
  ///
  /// Null means inherit from the portal or built-in fallback.
  final Color? color;

  /// Background blur applied to the non-highlighted area.
  ///
  /// A value of zero disables blur. The blur is clipped with the same holes as
  /// [color], so highlighted targets are not blurred.
  /// Null means inherit from the portal or built-in fallback.
  final double? blurSigma;

  /// Resolved color after applying the built-in fallback.
  Color get effectiveColor => color ?? fallback.color!;

  /// Resolved blur sigma after applying the built-in fallback.
  double get effectiveBlurSigma {
    return _nonNegativeFiniteOrZero(blurSigma ?? fallback.blurSigma!);
  }

  bool get hasBlur => effectiveBlurSigma > 0;

  SpotlightGuideBarrierStyle copyWith({Color? color, double? blurSigma}) {
    return SpotlightGuideBarrierStyle(
      color: color ?? this.color,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  /// Returns this style with non-null fields from [other] replacing it.
  ///
  /// This mirrors the way [TextStyle.merge] is commonly used: portal style can
  /// define shared defaults, and a step style can override only the fields it
  /// needs.
  SpotlightGuideBarrierStyle merge(SpotlightGuideBarrierStyle? other) {
    if (other == null) {
      return this;
    }
    return SpotlightGuideBarrierStyle(
      color: other.color ?? color,
      blurSigma: other.blurSigma ?? blurSigma,
    );
  }

  /// Applies the built-in fallback so every field has an effective value.
  SpotlightGuideBarrierStyle resolve() {
    return fallback.merge(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SpotlightGuideBarrierStyle &&
        other.color == color &&
        other.blurSigma == blurSigma;
  }

  @override
  int get hashCode => Object.hash(color, blurSigma);
}
