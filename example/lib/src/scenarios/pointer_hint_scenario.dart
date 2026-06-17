import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../widgets/guide_hint.dart';

List<SpotlightGuideStep> buildPointerHintScenario() {
  return <SpotlightGuideStep>[
    _leftTargetPointerStep(),
    _pointerStep(
      targetId: pointerAboveTargetId,
      placement: SpotlightGuidePlacement.top,
      title: 'Top pointer',
      message:
          'Top placement puts the pointer between the bubble and the target '
          'top edge.',
      pointer: const SpotlightGuideHintPointer(
        builder: _buildDirectionalTapPointer,
        child: _whiteTapPointer,
        size: Size(56, 56),
        targetGap: _pointerTargetGap,
      ),
    ),
    _pointerStep(
      targetId: pointerCustomAssetId,
      placement: SpotlightGuidePlacement.verticalAuto,
      title: 'Custom pointer widget',
      message:
          'A pointer can be an image, animation, CustomPaint, icon, badge, or '
          'any widget that should visually connect the hint to the target.',
      pointer: const SpotlightGuideHintPointer(
        child: _CustomPointerBadge(),
        size: Size(88, 42),
        targetGap: _pointerTargetGap,
        visualOffset: SpotlightGuidePointerOffset.directional(end: 3, up: 2),
        layer: SpotlightGuidePointerLayer.aboveBubble,
        bubblePlacement: SpotlightGuidePointerBubblePlacement.bottom,
      ),
      revealOptions: const SpotlightGuideRevealOptions(
        scrollPolicy: SpotlightGuideRevealScrollPolicy.always,
        alignment: 0.12,
      ),
    ),
    _pointerStep(
      targetId: pointerEdgeAnchorId,
      placement: SpotlightGuidePlacement.right,
      title: 'Edge anchored pointer',
      message:
          'Move the bubble anchor toward the pointer edge while the pointer '
          'stays centered on the target.',
      targetAnchorPosition: const SpotlightGuideAnchorPosition.start(12),
      pointer: const SpotlightGuideHintPointer(
        builder: _buildDirectionalTapPointer,
        child: _whiteTapPointer,
        size: SpotlightGuideTapPointer.defaultSize,
        targetGap: _pointerTargetGap,
      ),
    ),
    _pointerStep(
      targetId: pointerAutoSideId,
      placement: SpotlightGuidePlacement.horizontalAuto,
      title: 'Auto side pointer',
      message:
          'Use auto horizontal placement when a localized layout can move the '
          'target. The bubble and pointer choose the side with more visible '
          'space.',
      pointer: const SpotlightGuideHintPointer(
        builder: _buildDirectionalTapPointer,
        child: _whiteTapPointer,
        size: SpotlightGuideTapPointer.defaultSize,
        targetGap: _pointerTargetGap,
      ),
    ),
    _pointerStep(
      targetId: pointerDirectAnchorId,
      placement: SpotlightGuidePlacement.verticalAuto,
      title: 'Direct target anchor',
      message:
          'Set pointer.anchorMode to target when the pointer is decorative and '
          'the bubble anchor should still connect directly to the target. Auto '
          'placement keeps the decorative pointer inside the visible area.',
      pointer: const SpotlightGuideHintPointer(
        builder: _buildDirectionalTapPointer,
        child: _whiteTapPointer,
        size: SpotlightGuideTapPointer.defaultSize,
        targetGap: _pointerTargetGap,
        anchorMode: SpotlightGuidePointerAnchorMode.target,
        layer: SpotlightGuidePointerLayer.aboveBubble,
      ),
    ),
  ];
}

SpotlightGuideStep _leftTargetPointerStep() {
  return _pointerStep(
    targetId: pointerLeftOfTargetId,
    placement: SpotlightGuidePlacement.start,
    title: 'Right-pointing pointer',
    message:
        'The pointer stays on the target left side and points at the target '
        'vertical center. The explanation bubble sits below it.',
    pointer: SpotlightGuideHintPointer(
      builder: _buildConnectedTapPointer,
      child: _whiteTapPointer,
      size: Size(_ConnectedTapPointer.size, _ConnectedTapPointer.height),
      pointerAnchorPosition: SpotlightGuideAnchorPosition.start(_ConnectedTapPointer.size / 2),
      bubblePlacement: SpotlightGuidePointerBubblePlacement.bottom,
      targetGap: _pointerTargetGap,
    ),
    gap: 0,
    showProgress: false,
  );
}

SpotlightGuideStep _pointerStep({
  required Object targetId,
  required SpotlightGuidePlacement placement,
  required String title,
  required String message,
  required SpotlightGuideHintPointer pointer,
  SpotlightGuideAnchorPosition targetAnchorPosition = const SpotlightGuideAnchorPosition.center(),
  SpotlightGuideRevealOptions? revealOptions,
  double gap = 10,
  bool showProgress = true,
}) {
  return SpotlightGuideStep.item(
    SpotlightGuideStepItem(
      targetId: targetId,
      placement: placement,
      targetAnchorPosition: targetAnchorPosition,
      targetDecoration: _pointerTargetDecoration,
      decoration: const SpotlightGuideBubbleDecoration(
        borderRadius: 10,
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      margin: kExampleGuideMargin,
      gap: gap,
      minWidth: 180,
      maxWidth: 300,
      revealOptions: revealOptions,
      hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
        return SpotlightGuideTextHint(
          guide: guide,
          title: title,
          message: message,
          pointer: pointer,
          showProgress: showProgress,
        );
      },
    ),
  );
}

const double _pointerTargetGap = 4;

const SpotlightGuideTargetDecoration _pointerTargetDecoration = SpotlightGuideTargetDecoration(
  padding: EdgeInsets.all(6),
  shape: SpotlightGuideRoundedRectTargetShape(borderRadius: BorderRadius.all(Radius.circular(14))),
  layers: <SpotlightGuideTargetLayer>[
    SpotlightGuideTargetGlowLayer(color: Color(0x40FFFFFF), blurRadius: 14, spreadRadius: 2),
    SpotlightGuideTargetRingLayer(color: Color(0xE6FFFFFF), width: 2),
  ],
);

const SpotlightGuideTapPointer _whiteTapPointer = SpotlightGuideTapPointer(
  color: Color(0xFFFFFFFF),
  backgroundColor: Color(0xE6316B67),
  ringColor: Color(0xBFFFFFFF),
);

Widget _buildDirectionalTapPointer(BuildContext context, SpotlightGuidePointerContext pointer, Widget child) {
  return Transform.rotate(angle: _tapPointerAngle(pointer), child: child);
}

Widget _buildConnectedTapPointer(BuildContext context, SpotlightGuidePointerContext pointer, Widget child) {
  return _ConnectedTapPointer(pointer: pointer, child: child);
}

class _ConnectedTapPointer extends StatelessWidget {
  const _ConnectedTapPointer({required this.pointer, required this.child});

  static const double size = 64;
  static const double _connectorLength = 80;
  static const double _connectorWidth = 1.4;
  static const double height = size + _connectorLength;

  final SpotlightGuidePointerContext pointer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const Color connectorColor = Color(0xDFFFFFFF);
    return SizedBox(
      key: const ValueKey<String>('right-pointing-pointer-slot'),
      width: size,
      height: height,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.topCenter,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            width: size,
            height: size,
            child: Transform.rotate(angle: _tapPointerAngle(pointer), child: child),
          ),
          Positioned(
            top: size,
            width: _connectorWidth,
            height: _connectorLength,
            child: DecoratedBox(
              key: const ValueKey<String>('right-pointing-pointer-connector'),
              decoration: BoxDecoration(
                color: connectorColor,
                borderRadius: BorderRadius.circular(_connectorWidth),
                boxShadow: <BoxShadow>[BoxShadow(color: connectorColor.withValues(alpha: 0.28), blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _tapPointerAngle(SpotlightGuidePointerContext pointer) {
  return pointer.rotationToTarget(from: SpotlightGuideTapPointer.naturalDirection);
}

class _CustomPointerBadge extends StatelessWidget {
  const _CustomPointerBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Center(child: Icon(Icons.ads_click_rounded, color: scheme.onTertiaryContainer, size: 26)),
    );
  }
}
