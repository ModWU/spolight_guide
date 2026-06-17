import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildSideAnchorScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      _item(
        targetId: sideAnchorLeftArrowId,
        title: 'Horizontal auto: left arrow',
        message:
            'Auto placement sees more room on the right, so the bubble sits there and points left.',
      ),
    ),
    SpotlightGuideStep.item(
      _item(
        targetId: sideAnchorRightArrowId,
        title: 'Horizontal auto: right arrow',
        message:
            'Auto placement sees more room on the left, so the bubble sits there and points right.',
      ),
    ),
  ];
}

SpotlightGuideStepItem _item({
  required String targetId,
  required String title,
  required String message,
}) {
  return SpotlightGuideStepItem(
    targetId: targetId,
    placement: SpotlightGuidePlacement.horizontalAuto,
    targetDecoration: const SpotlightGuideTargetDecoration(
      padding: EdgeInsets.all(5),
      shape: SpotlightGuideRoundedRectShape(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    maxWidth: 228,
    margin: kExampleGuideMargin,
    hintBuilder: (context, guide) {
      return buildGuideHint(guide: guide, title: title, message: message);
    },
  );
}
