import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/same_step_hints_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class SameStepHintsPage extends StatefulWidget {
  const SameStepHintsPage({super.key});

  @override
  State<SameStepHintsPage> createState() => _SameStepHintsPageState();
}

class _SameStepHintsPageState extends State<SameStepHintsPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Same-step hints',
      controller: _guideController,
      steps: buildSameStepHintsScenario(),
      barrierDismissBehavior: SpotlightGuideDismissBehavior.onComplete,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(title: 'Metrics', child: MetricsSection()),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'One step, three hints',
            child: Text(
              'All three metric cards are explained in a single step with '
              'multiple hint bubbles.',
            ),
          ),
        ],
      ),
    );
  }
}
