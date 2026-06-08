import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildLargeGroupAnchorScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: metricGroupId,
        anchorTargetId: metricCostAnchorId,
        targetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        targetRadius: 18,
        placement: SpotlightGuidePlacement.verticalAuto,
        revealOptions: const SpotlightGuideRevealOptions(
          scrollTargetPolicy: SpotlightGuideRevealScrollTargetPolicy
              .anchorTargetWhenHighlightedAreaCannotFit,
        ),
        hintBuilder: (context, guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Repeated id group',
            message:
                'The three metric cards share one target id, so the whole '
                'group is highlighted. The bubble anchors to Total cost.',
          );
        },
      ),
    ),
  ];
}
