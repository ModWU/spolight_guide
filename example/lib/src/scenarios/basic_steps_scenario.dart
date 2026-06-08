import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildBasicStepsScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      _item(
        targetId: metricCostId,
        title: 'Basic target',
        message: 'This step highlights one mounted target.',
        placement: SpotlightGuidePlacement.bottom,
      ),
    ),
    SpotlightGuideStep.item(
      _item(
        targetId: metricPriceId,
        title: 'Next step',
        message: 'The controller advances to the next step, then finishes.',
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
    maxWidth: 310,
    hintBuilder: (context, guide) {
      return buildGuideHint(guide: guide, title: title, message: message);
    },
  );
}
