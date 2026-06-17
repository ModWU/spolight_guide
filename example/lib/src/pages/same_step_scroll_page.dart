import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/same_step_scroll_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class SameStepScrollPage extends StatefulWidget {
  const SameStepScrollPage({super.key});

  @override
  State<SameStepScrollPage> createState() => _SameStepScrollPageState();
}

class _SameStepScrollPageState extends State<SameStepScrollPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();
  final ScrollController _wideController = ScrollController();
  String _autoScrollStatus = 'Waiting for same-step scroll';

  @override
  void dispose() {
    _wideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Same-step scroll',
      controller: _guideController,
      steps: buildSameStepScrollScenario(
        onItemChanged: _handleAutoScrollChanged,
      ),
      onReplay: _replayGuide,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          WideTargetsSection(controller: _wideController),
          const SizedBox(height: 16),
          ScenarioPanel(
            title: 'Auto-scroll status',
            child: Text(_autoScrollStatus),
          ),
        ],
      ),
    );
  }

  void _replayGuide() {
    if (_wideController.hasClients) {
      _wideController.jumpTo(0);
    }
    setState(() {
      _autoScrollStatus = 'Waiting for same-step scroll';
    });
    _guideController.reset();
  }

  void _handleAutoScrollChanged(SpotlightGuideAutoScrollDetails details) {
    if (!mounted) {
      return;
    }
    setState(() {
      _autoScrollStatus =
          'Auto-scroll item ${details.itemIndex + 1}/${details.itemTotal}: '
          '${details.key ?? details.primaryTargetId ?? 'whole page'}';
    });
  }
}
