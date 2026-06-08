import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/basic_steps_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class BasicScenarioPage extends StatefulWidget {
  const BasicScenarioPage({super.key});

  @override
  State<BasicScenarioPage> createState() => _BasicScenarioPageState();
}

class _BasicScenarioPageState extends State<BasicScenarioPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Basic guide',
      controller: _guideController,
      steps: buildBasicStepsScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(title: 'Metrics', child: MetricsSection()),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Flow',
            child: Text(
              'This scenario highlights one target, then moves to the next '
              'target through the guide controller.',
            ),
          ),
        ],
      ),
    );
  }
}
