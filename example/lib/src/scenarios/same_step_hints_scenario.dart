import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildSameStepHintsScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep(
      autoScrollOptions: const SpotlightGuideAutoScrollOptions(
        enabled: false,
      ),
      items: <SpotlightGuideStepItem>[
        _item(
          targetId: metricWeightId,
          title: 'Weight',
          message: 'Total grams',
        ),
        _item(targetId: metricCostId, title: 'Cost', message: 'Money in'),
        _item(targetId: metricPriceId, title: 'Price', message: 'Average'),
      ],
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
    placement: SpotlightGuidePlacement.bottom,
    margin: kExampleGuideMargin,
    maxWidth: 118,
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
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(message, maxLines: 2, style: const TextStyle(fontSize: 12)),
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
