import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../scenarios/target_decoration_scenario.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class TargetDecorationPage extends StatefulWidget {
  const TargetDecorationPage({super.key, this.controller});

  final SpotlightGuidePortalController? controller;

  @override
  State<TargetDecorationPage> createState() => _TargetDecorationPageState();
}

class _TargetDecorationPageState extends State<TargetDecorationPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  SpotlightGuidePortalController get _effectiveGuideController =>
      widget.controller ?? _guideController;

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Target decoration',
      controller: _effectiveGuideController,
      steps: buildTargetDecorationScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          const ScenarioPanel(
            title: 'Layered border halo',
            child: _LayeredRingTarget(),
          ),
          const SizedBox(height: 16),
          const ScenarioPanel(
            title: 'Soft blurred glow',
            child: _SoftGlowTarget(),
          ),
          const SizedBox(height: 16),
          const ScenarioPanel(title: 'Oval glow', child: _OvalGlowTarget()),
          const SizedBox(height: 16),
          const ScenarioPanel(
            title: 'Dashed outline',
            child: _DashedOutlineTarget(),
          ),
        ],
      ),
    );
  }
}

class _LayeredRingTarget extends StatelessWidget {
  const _LayeredRingTarget();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SpotlightGuideTarget(
        id: targetDecorationLayeredId,
        child: SizedBox(
          width: 210,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.layers, color: Color(0xFF1565C0)),
                  SizedBox(height: 10),
                  Text(
                    'Layered border',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Translucent white ring layers',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftGlowTarget extends StatelessWidget {
  const _SoftGlowTarget();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SpotlightGuideTarget(
        id: targetDecorationSoftGlowId,
        child: SizedBox(
          width: 230,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Icon(Icons.blur_on, color: Color(0xFF00897B), size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Soft glow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Blurred halo layer',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OvalGlowTarget extends StatelessWidget {
  const _OvalGlowTarget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SpotlightGuideTarget(
          id: targetDecorationGlowId,
          child: const SizedBox(
            width: 76,
            height: 76,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF8E1),
              ),
              child: Icon(Icons.wb_sunny, color: Color(0xFFF9A825), size: 34),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Oval target shapes can use the same layer list. The highlight '
            'stays outside the transparent hole so the target remains crisp.',
          ),
        ),
      ],
    );
  }
}

class _DashedOutlineTarget extends StatelessWidget {
  const _DashedOutlineTarget();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SpotlightGuideTarget(
        id: targetDecorationDashedId,
        child: SizedBox(
          width: 240,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.border_style, color: Color(0xFF5E35B1), size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Dashed outline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reusable path effect',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
