import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/dynamic_steps_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class DynamicStepsPage extends StatefulWidget {
  const DynamicStepsPage({super.key});

  @override
  State<DynamicStepsPage> createState() => _DynamicStepsPageState();
}

class _DynamicStepsPageState extends State<DynamicStepsPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();
  final ScrollController _pageController = ScrollController();

  bool _showOptionalOffer = true;
  String _guideStatus = 'Guide is idle.';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Dynamic steps',
      controller: _guideController,
      steps: buildDynamicStepsScenario(),
      missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
      onReplay: _resetGuideFromRuntimeControls,
      onStateChanged: _handleGuideStateChanged,
      child: SingleChildScrollView(
        controller: _pageController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ScenarioPanel(title: 'Metrics', child: MetricsSection()),
            const SizedBox(height: 16),
            if (_showOptionalOffer) ...const <Widget>[
              OptionalApiSection(),
              SizedBox(height: 16),
            ],
            const AddSavingButton(),
            const SizedBox(height: 16),
            _buildRuntimeState(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeState() {
    return ScenarioPanel(
      title: 'Runtime state',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_guideStatus),
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include optional API target'),
            subtitle: const Text(
              'Turn this off before replaying Dynamic steps.',
            ),
            value: _showOptionalOffer,
            onChanged: (bool value) {
              setState(() {
                _showOptionalOffer = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
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
                onPressed: _resetGuideFromRuntimeControls,
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

  Future<void> _resetGuideFromRuntimeControls() async {
    if (_pageController.hasClients) {
      await _pageController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) {
      return;
    }
    _guideController.reset();
  }

  void _handleGuideStateChanged(SpotlightGuideStateDetails details) {
    if (!mounted) {
      return;
    }
    setState(() {
      _guideStatus =
          '${details.reason.name}: index ${details.index + 1}/${details.total}, '
          'resolved items ${details.resolvedItemCount}';
    });
  }
}
