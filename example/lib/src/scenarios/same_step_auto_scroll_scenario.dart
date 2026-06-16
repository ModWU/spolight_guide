import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildSameStepAutoScrollScenario({
  required SpotlightGuideAutoScrollItemCallback onAutoScrollItemChanged,
}) {
  return <SpotlightGuideStep>[
    SpotlightGuideStep(
      autoScrollOptions: SpotlightGuideStepAutoScrollOptions(
        interval: const Duration(milliseconds: 900),
        onAutoScrollItemChanged: onAutoScrollItemChanged,
      ),
      items: <SpotlightGuideStepItem>[
        _item(
          key: 'wide-start',
          targetId: wideStartId,
          title: 'Start',
          message: 'Already visible.',
          placement: SpotlightGuidePlacement.verticalAuto,
        ),
        _item(
          key: 'wide-end',
          targetId: wideEndId,
          title: 'Offscreen',
          message: 'Same step scroll.',
          placement: SpotlightGuidePlacement.verticalAuto,
        ),
      ],
    ),
  ];
}

SpotlightGuideStepItem _item({
  required Object key,
  required String targetId,
  required String title,
  required String message,
  required SpotlightGuidePlacement placement,
}) {
  return SpotlightGuideStepItem(
    key: key,
    targetId: targetId,
    placement: placement,
    margin: kExampleGuideMargin,
    revealOptions: const SpotlightGuideRevealOptions(
      duration: Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
    ),
    maxWidth: 190,
    hintBuilder: (context, guide) {
      return SpotlightGuideBubbleHint(
        guide: guide,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${guide.itemIndex + 1}/${guide.itemTotal}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(message, style: const TextStyle(fontSize: 12)),
              if (guide.isLastItem) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: guide.finish,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
