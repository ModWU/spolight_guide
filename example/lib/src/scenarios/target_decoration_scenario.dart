import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildTargetDecorationScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: targetDecorationLayeredId,
        placement: SpotlightGuidePlacement.verticalAuto,
        targetDecoration: const SpotlightGuideTargetDecoration(
          padding: EdgeInsets.all(2),
          shape: SpotlightGuideRoundedRectTargetShape(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          layers: <SpotlightGuideTargetLayer>[
            SpotlightGuideTargetRingLayer(color: Color(0x1AFFFFFF), width: 16),
            SpotlightGuideTargetRingLayer(color: Color(0x33FFFFFF), width: 8),
          ],
        ),
        gap: 18,
        margin: kExampleGuideMargin,
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Layered target halo',
            message:
                'Use translucent ring layers when the target needs a crisp '
                'border-style halo instead of a blurred glow.',
          );
        },
      ),
    ),
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: targetDecorationSoftGlowId,
        placement: SpotlightGuidePlacement.verticalAuto,
        targetDecoration: const SpotlightGuideTargetDecoration(
          padding: EdgeInsets.all(6),
          shape: SpotlightGuideRoundedRectTargetShape(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          layers: <SpotlightGuideTargetLayer>[
            SpotlightGuideTargetGlowLayer(
              color: Color(0xF280FFF6),
              blurRadius: 16,
            ),
          ],
        ),
        gap: 18,
        margin: kExampleGuideMargin,
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Soft blurred glow',
            message:
                'Use a glow layer when the target needs a diffused halo that '
                'spreads softly into the dim barrier.',
          );
        },
      ),
    ),
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: targetDecorationGlowId,
        placement: SpotlightGuidePlacement.verticalAuto,
        targetDecoration: const SpotlightGuideTargetDecoration(
          padding: EdgeInsets.all(10),
          shape: SpotlightGuideOvalTargetShape(),
          layers: <SpotlightGuideTargetLayer>[
            SpotlightGuideTargetGlowLayer(
              color: Color(0xE6FFC107),
              blurRadius: 18,
            ),
            SpotlightGuideTargetRingLayer(color: Color(0xFFFFC107), width: 3),
          ],
        ),
        margin: kExampleGuideMargin,
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Shape-aware oval glow',
            message:
                'Oval target shapes can use the same layer system for circular '
                'controls, avatars and status indicators.',
          );
        },
      ),
    ),
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: targetDecorationDashedId,
        placement: SpotlightGuidePlacement.verticalAuto,
        targetDecoration: const SpotlightGuideTargetDecoration(
          padding: EdgeInsets.all(6),
          shape: SpotlightGuideRoundedRectTargetShape(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          layers: <SpotlightGuideTargetLayer>[
            SpotlightGuideTargetDashedOutlineLayer(
              color: Color(0xFFFFFFFF),
              width: 3,
              dashLength: 10,
              gapLength: 6,
              outset: 8,
            ),
          ],
        ),
        gap: 16,
        margin: kExampleGuideMargin,
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return buildGuideHint(
            guide: guide,
            title: 'Dashed outline layer',
            message:
                'Use a dashed outline layer for temporary attention states, '
                'selection boundaries or review markers.',
          );
        },
      ),
    ),
  ];
}
