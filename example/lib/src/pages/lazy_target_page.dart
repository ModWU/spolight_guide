import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../scenarios/lazy_target_reveal_scenario.dart';
import '../widgets/demo_sections.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class LazyTargetPage extends StatefulWidget {
  const LazyTargetPage({super.key});

  @override
  State<LazyTargetPage> createState() => _LazyTargetPageState();
}

class _LazyTargetPageState extends State<LazyTargetPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();
  final ScrollController _pageController = ScrollController();
  final ScrollController _historyController = ScrollController();

  @override
  void dispose() {
    _pageController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Lazy target',
      controller: _guideController,
      steps: buildLazyTargetRevealScenario(
        pageController: _pageController,
        historyController: _historyController,
      ),
      onReplay: _replayGuide,
      child: ListView(
        controller: _pageController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          const _LazySetupPanel(),
          const SizedBox(height: 16),
          const ActivityIntroSection(),
          const SizedBox(height: 12),
          HistoryListSection(controller: _historyController),
        ],
      ),
    );
  }

  void _replayGuide() {
    if (_pageController.hasClients) {
      _pageController.jumpTo(0);
    }
    if (_historyController.hasClients) {
      _historyController.jumpTo(0);
    }
    _guideController.reset();
  }
}

class _LazySetupPanel extends StatelessWidget {
  const _LazySetupPanel();

  @override
  Widget build(BuildContext context) {
    return const ScenarioPanel(
      title: 'Preparation',
      child: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('The target list starts below this setup area.'),
            SizedBox(height: 18),
            _SetupRow(icon: Icons.filter_alt, label: 'Filters ready'),
            SizedBox(height: 12),
            _SetupRow(icon: Icons.timeline, label: 'Activity feed loaded'),
            SizedBox(height: 12),
            _SetupRow(icon: Icons.touch_app, label: 'Guide waits offscreen'),
            Spacer(),
            Text(
              'Replay the guide to watch the page reveal the nested lazy row.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 17,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        SizedBox(width: 10),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
