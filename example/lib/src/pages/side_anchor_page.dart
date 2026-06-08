import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../scenarios/side_anchor_scenario.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class SideAnchorPage extends StatefulWidget {
  const SideAnchorPage({super.key});

  @override
  State<SideAnchorPage> createState() => _SideAnchorPageState();
}

class _SideAnchorPageState extends State<SideAnchorPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Side anchors',
      controller: _guideController,
      steps: buildSideAnchorScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(
            title: 'Left and right arrows',
            child: _SideAnchorTargets(),
          ),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Placement',
            child: Text(
              'Use horizontalAuto when a product surface can place the hint on '
              'whichever horizontal side has more visible space.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAnchorTargets extends StatelessWidget {
  const _SideAnchorTargets();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const <Widget>[
        Row(
          children: <Widget>[
            SpotlightGuideTarget(
              id: sideAnchorLeftArrowId,
              child: _SideTargetCard(
                icon: Icons.keyboard_arrow_left,
                title: 'Left arrow',
                value: 'Right side',
              ),
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: 22),
        Row(
          children: <Widget>[
            Spacer(),
            SpotlightGuideTarget(
              id: sideAnchorRightArrowId,
              child: _SideTargetCard(
                icon: Icons.keyboard_arrow_right,
                title: 'Right arrow',
                value: 'Left side',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SideTargetCard extends StatelessWidget {
  const _SideTargetCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      height: 98,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FA),
          border: Border.all(color: const Color(0xFFE6EAED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 7),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
