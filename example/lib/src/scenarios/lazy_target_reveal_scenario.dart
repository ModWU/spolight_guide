import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildLazyTargetRevealScenario({
  required ScrollController historyController,
}) {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: lazyHistoryId,
        placement: SpotlightGuidePlacement.verticalAuto,
        maxWidth: 320,
        onReveal: (SpotlightGuideRevealContext context) {
          return context.scrollToIndex(
            controller: historyController,
            index: lazyHistoryIndex,
            itemExtent: historyItemExtent,
            alignment: 0.4,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            settleFrames: 2,
          );
        },
        hintBuilder: (context, guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Lazy list target',
            message:
                'onReveal scrolls the list until this row is built, then '
                'the default reveal pass keeps it visible.',
          );
        },
      ),
    ),
  ];
}
