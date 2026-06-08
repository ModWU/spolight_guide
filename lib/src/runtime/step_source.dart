part of '../../spotlight_guide.dart';

/// Owns the active step sequence.
///
/// The portal has two possible sources: configured portal steps and runtime
/// steps supplied by a controller. Keeping that decision here avoids scattering
/// null checks through rendering, navigation and controller sync code.
class _SpotlightGuideStepSource {
  _SpotlightGuideStepSource({required List<SpotlightGuideStep> portalSteps})
    : _portalSteps = List<SpotlightGuideStep>.unmodifiable(portalSteps);

  List<SpotlightGuideStep> _portalSteps;
  List<SpotlightGuideStep>? _runtimeSteps;

  List<SpotlightGuideStep> get steps => _runtimeSteps ?? _portalSteps;

  List<SpotlightGuideStep> get portalSteps => _portalSteps;

  List<SpotlightGuideStep>? get runtimeSteps => _runtimeSteps;

  bool get usesRuntimeSteps => _runtimeSteps != null;

  bool updatePortalSteps(List<SpotlightGuideStep> steps) {
    final bool changed = !listEquals(_portalSteps, steps);
    _portalSteps = List<SpotlightGuideStep>.unmodifiable(steps);
    return changed && !usesRuntimeSteps;
  }

  void usePortalSteps() {
    _runtimeSteps = null;
  }

  void useRuntimeSteps(List<SpotlightGuideStep> steps) {
    _runtimeSteps = List<SpotlightGuideStep>.unmodifiable(steps);
  }
}
