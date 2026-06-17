import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

enum BarrierDismissDemoMode {
  anytime,
  onComplete,
  disabled;

  SpotlightGuideDismissBehavior get behavior {
    return switch (this) {
      BarrierDismissDemoMode.anytime => SpotlightGuideDismissBehavior.anytime,
      BarrierDismissDemoMode.onComplete =>
        SpotlightGuideDismissBehavior.onComplete,
      BarrierDismissDemoMode.disabled => SpotlightGuideDismissBehavior.disabled,
    };
  }

  String get summary {
    return switch (this) {
      BarrierDismissDemoMode.anytime =>
        'Outside taps finish immediately, even on the first visible step.',
      BarrierDismissDemoMode.onComplete =>
        'Outside taps are ignored until the final visible step.',
      BarrierDismissDemoMode.disabled =>
        'Outside taps are absorbed; the hint button controls completion.',
    };
  }
}

List<SpotlightGuideStep> buildBarrierDismissScenario(
  BarrierDismissDemoMode mode,
) {
  return switch (mode) {
    BarrierDismissDemoMode.anytime => <SpotlightGuideStep>[
      SpotlightGuideStep.item(
        _passiveItem(
          targetId: barrierDismissAnytimeId,
          title: 'Tap outside anytime',
          message:
              'This hint intentionally has no button. A tap on the dim area '
              'finishes the guide from this first step.',
        ),
      ),
    ],
    BarrierDismissDemoMode.onComplete => <SpotlightGuideStep>[
      SpotlightGuideStep.item(
        _buttonItem(
          targetId: barrierDismissOnCompleteStartId,
          title: 'Complete-only start',
          message:
              'Outside taps are ignored while the flow still has another step.',
        ),
      ),
      SpotlightGuideStep.item(
        _passiveItem(
          targetId: barrierDismissOnCompleteEndId,
          title: 'Complete-only final step',
          message:
              'There is no Done button here. Tapping the dim area now finishes '
              'because the flow is complete.',
        ),
      ),
    ],
    BarrierDismissDemoMode.disabled => <SpotlightGuideStep>[
      SpotlightGuideStep.item(
        _buttonItem(
          targetId: barrierDismissDisabledId,
          title: 'Default absorbs outside taps',
          message:
              'The default mode keeps outside taps from closing the guide. '
              'Use the button to finish this one.',
        ),
      ),
    ],
  };
}

SpotlightGuideStepItem _buttonItem({
  required String targetId,
  required String title,
  required String message,
}) {
  return SpotlightGuideStepItem(
    targetId: targetId,
    placement: SpotlightGuidePlacement.verticalAuto,
    margin: kExampleGuideMargin,
    maxWidth: 320,
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return buildGuideHint(guide: guide, title: title, message: message);
    },
  );
}

SpotlightGuideStepItem _passiveItem({
  required String targetId,
  required String title,
  required String message,
}) {
  return SpotlightGuideStepItem(
    targetId: targetId,
    placement: SpotlightGuidePlacement.verticalAuto,
    margin: kExampleGuideMargin,
    maxWidth: 320,
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return SpotlightGuideTextHint(
        guide: guide,
        title: title,
        message: message,
        showActions: false,
      );
    },
  );
}
