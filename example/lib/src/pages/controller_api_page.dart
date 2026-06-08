import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/controller_usage_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class ControllerApiPage extends StatefulWidget {
  const ControllerApiPage({super.key});

  @override
  State<ControllerApiPage> createState() => _ControllerApiPageState();
}

class _ControllerApiPageState extends State<ControllerApiPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();
  String _guideStatus = 'Guide is idle.';

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Controller API',
      controller: _guideController,
      steps: buildControllerPortalScenario(),
      onStateChanged: _handleGuideStateChanged,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          const ScenarioPanel(title: 'Metrics', child: MetricsSection()),
          const SizedBox(height: 16),
          _buildControllerPanel(),
        ],
      ),
    );
  }

  Widget _buildControllerPanel() {
    return ScenarioPanel(
      title: 'Controller controls',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_guideStatus),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: _guideController.showPortal,
                child: const Text('Show portal'),
              ),
              OutlinedButton(
                onPressed: _guideController.previous,
                child: const Text('Previous'),
              ),
              OutlinedButton(
                onPressed: _guideController.next,
                child: const Text('Next'),
              ),
              OutlinedButton(
                onPressed: () => _guideController.goTo(1),
                child: const Text('Go to 2'),
              ),
              OutlinedButton(
                onPressed: _guideController.reset,
                child: const Text('Reset'),
              ),
              OutlinedButton(
                onPressed: _guideController.hide,
                child: const Text('Hide'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleGuideStateChanged(SpotlightGuideStateContext context) {
    if (!mounted) {
      return;
    }
    setState(() {
      _guideStatus =
          '${context.reason.name}: index ${context.index + 1}/${context.total}, '
          'resolved items ${context.resolvedItemCount}';
    });
  }
}
