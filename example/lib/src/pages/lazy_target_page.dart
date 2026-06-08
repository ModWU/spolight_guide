import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/lazy_target_reveal_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/guide_scenario_scaffold.dart';

class LazyTargetPage extends StatefulWidget {
  const LazyTargetPage({super.key});

  @override
  State<LazyTargetPage> createState() => _LazyTargetPageState();
}

class _LazyTargetPageState extends State<LazyTargetPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();
  final ScrollController _historyController = ScrollController();

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Lazy target',
      controller: _guideController,
      steps: buildLazyTargetRevealScenario(
        historyController: _historyController,
      ),
      onReplay: _replayGuide,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          const ActivityIntroSection(),
          const SizedBox(height: 12),
          HistoryListSection(controller: _historyController),
        ],
      ),
    );
  }

  void _replayGuide() {
    if (_historyController.hasClients) {
      _historyController.jumpTo(0);
    }
    _guideController.reset();
  }
}
