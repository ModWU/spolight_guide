import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildControllerPortalScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      _item(
        targetId: metricCostId,
        title: 'Portal steps',
        message:
            'These steps live on SpotlightGuidePortal.steps and are shown '
            'with controller.showPortal().',
        placement: SpotlightGuidePlacement.bottom,
      ),
    ),
    SpotlightGuideStep.item(
      _item(
        targetId: metricPriceId,
        title: 'Controller navigation',
        message:
            'Use next, previous, goTo, reset, hide, or finish from an '
            'external controller.',
        placement: SpotlightGuidePlacement.bottom,
      ),
    ),
  ];
}

SpotlightGuideStepItem _item({
  required String targetId,
  required String title,
  required String message,
  required SpotlightGuidePlacement placement,
}) {
  return SpotlightGuideStepItem(
    targetId: targetId,
    placement: placement,
    margin: kExampleGuideMargin,
    maxWidth: 320,
    hintBuilder: (context, guide) {
      return buildGuideHint(guide: guide, title: title, message: message);
    },
  );
}
