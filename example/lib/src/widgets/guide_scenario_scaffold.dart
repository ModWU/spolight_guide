import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

class GuideScenarioScaffold extends StatelessWidget {
  const GuideScenarioScaffold({
    super.key,
    required this.title,
    required this.controller,
    required this.steps,
    required this.child,
    this.onReplay,
    this.onStateChanged,
    this.onBarrierTap,
    this.barrierDismissBehavior = SpotlightGuideDismissBehavior.disabled,
    this.missingTargetBehavior = SpotlightGuideMissingTargetBehavior.skip,
    this.autoStart = true,
  });

  final String title;
  final SpotlightGuidePortalController controller;
  final List<SpotlightGuideStep> steps;
  final Widget child;
  final VoidCallback? onReplay;
  final SpotlightGuideStateCallback? onStateChanged;
  final SpotlightGuideBarrierTapCallback? onBarrierTap;
  final SpotlightGuideDismissBehavior barrierDismissBehavior;
  final SpotlightGuideMissingTargetBehavior missingTargetBehavior;
  final bool autoStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Replay guide',
            icon: const Icon(Icons.replay),
            onPressed: onReplay ?? controller.reset,
          ),
          IconButton(
            tooltip: 'Hide guide',
            icon: const Icon(Icons.close),
            onPressed: controller.hide,
          ),
        ],
      ),
      body: SpotlightGuidePortal(
        controller: controller,
        autoStart: autoStart,
        steps: steps,
        missingTargetBehavior: missingTargetBehavior,
        onStateChanged: onStateChanged,
        onBarrierTap: onBarrierTap,
        barrierDismissBehavior: barrierDismissBehavior,
        barrier: const SpotlightGuideBarrierStyle(
          color: Color(0xA6000000),
          blurSigma: 1.5,
        ),
        child: child,
      ),
    );
  }
}
