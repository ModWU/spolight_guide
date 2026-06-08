import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildDynamicStepsScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      _item(
        targetId: metricCostId,
        title: 'Always present',
        message: 'This step is always included.',
        placement: SpotlightGuidePlacement.verticalAuto,
      ),
    ),
    SpotlightGuideStep.item(
      _item(
        targetId: optionalOfferId,
        title: 'Optional server target',
        message: 'If this target is not mounted, skip removes this step.',
        placement: SpotlightGuidePlacement.verticalAuto,
        missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
      ),
    ),
    SpotlightGuideStep.item(
      _item(
        targetId: addSavingId,
        title: 'Final dynamic step',
        message: 'State callbacks expose the resolved total.',
        placement: SpotlightGuidePlacement.top,
      ),
    ),
  ];
}

SpotlightGuideStepItem _item({
  required String targetId,
  required String title,
  required String message,
  required SpotlightGuidePlacement placement,
  SpotlightGuideMissingTargetBehavior? missingTargetBehavior,
}) {
  return SpotlightGuideStepItem(
    targetId: targetId,
    placement: placement,
    missingTargetBehavior: missingTargetBehavior,
    maxWidth: 310,
    hintBuilder: (context, guide) {
      return buildGuideHint(guide: guide, title: title, message: message);
    },
  );
}
