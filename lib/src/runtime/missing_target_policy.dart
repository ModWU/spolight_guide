part of '../../spotlight_guide.dart';

/// Applies the missing-target strategy for the current guide.
class _SpotlightGuideMissingTargetPolicy {
  const _SpotlightGuideMissingTargetPolicy({
    required this.portalBehavior,
    required this.targetResolver,
  });

  final SpotlightGuideMissingTargetBehavior portalBehavior;
  final _SpotlightGuideTargetResolver targetResolver;

  bool shouldKeepStepBeforeReveal(SpotlightGuideStep step) {
    if (step.onReveal != null) {
      return true;
    }
    for (final SpotlightGuideStepItem item in step.items) {
      if (_shouldKeepItemBeforeReveal(item)) {
        return true;
      }
    }
    return false;
  }

  bool shouldSkipStep(SpotlightGuideStep step) {
    for (final SpotlightGuideStepItem item in step.items) {
      if (item.highlightsWholePortalChild) {
        return false;
      }
      if (targetResolver.hasResolvedGeometry(item, Rect.zero)) {
        return false;
      }
      if (_behaviorFor(item) == SpotlightGuideMissingTargetBehavior.wait) {
        return false;
      }
    }
    return true;
  }

  bool _shouldKeepItemBeforeReveal(SpotlightGuideStepItem item) {
    if (item.highlightsWholePortalChild) {
      return true;
    }
    if (targetResolver.hasResolvedGeometry(item, Rect.zero)) {
      return true;
    }
    if (item.onReveal != null) {
      return true;
    }
    return _behaviorFor(item) == SpotlightGuideMissingTargetBehavior.wait;
  }

  SpotlightGuideMissingTargetBehavior _behaviorFor(
    SpotlightGuideStepItem item,
  ) {
    return item.missingTargetBehavior ?? portalBehavior;
  }
}
