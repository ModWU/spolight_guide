import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/custom_anchor_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class CustomAnchorPage extends StatefulWidget {
  const CustomAnchorPage({super.key});

  @override
  State<CustomAnchorPage> createState() => _CustomAnchorPageState();
}

class _CustomAnchorPageState extends State<CustomAnchorPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Custom anchor',
      controller: _guideController,
      steps: buildCustomAnchorScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(title: 'Metrics', child: MetricsSection()),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Anchor offset',
            child: Text(
              'The hint uses a custom anchor position and a larger rounded '
              'triangle decoration.',
            ),
          ),
        ],
      ),
    );
  }
}
