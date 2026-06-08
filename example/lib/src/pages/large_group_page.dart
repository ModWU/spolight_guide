import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/large_group_anchor_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class LargeGroupPage extends StatefulWidget {
  const LargeGroupPage({super.key});

  @override
  State<LargeGroupPage> createState() => _LargeGroupPageState();
}

class _LargeGroupPageState extends State<LargeGroupPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Large group',
      controller: _guideController,
      steps: buildLargeGroupAnchorScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(title: 'Grouped targets', child: MetricsSection()),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Repeated id anchor',
            child: Text(
              'The same target id can highlight several widgets while a '
              'specific anchor target controls bubble placement.',
            ),
          ),
        ],
      ),
    );
  }
}
