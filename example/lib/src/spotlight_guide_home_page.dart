import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import 'guide_target_ids.dart';
import 'pages/barrier_dismiss_page.dart';
import 'pages/basic_scenario_page.dart';
import 'pages/controller_api_page.dart';
import 'pages/custom_anchor_page.dart';
import 'pages/dynamic_steps_page.dart';
import 'pages/large_group_page.dart';
import 'pages/lazy_target_page.dart';
import 'pages/same_step_hints_page.dart';
import 'pages/same_step_scroll_page.dart';
import 'pages/side_anchor_page.dart';
import 'widgets/guide_hint.dart';

class SpotlightGuideHomePage extends StatefulWidget {
  const SpotlightGuideHomePage({super.key});

  @override
  State<SpotlightGuideHomePage> createState() => _SpotlightGuideHomePageState();
}

class _SpotlightGuideHomePageState extends State<SpotlightGuideHomePage> {
  final SpotlightGuidePortalController _introController =
      SpotlightGuidePortalController();
  final ScrollController _scrollController = ScrollController();

  late final List<_ScenarioEntry> _entries = <_ScenarioEntry>[
    _ScenarioEntry(
      targetId: homeBasicId,
      title: 'Basic',
      subtitle: 'Two simple steps over visible targets.',
      icon: Icons.play_arrow,
      pageBuilder: (BuildContext context) => const BasicScenarioPage(),
      guideTitle: 'Basic guide',
      guideMessage:
          'Start with the smallest happy path: one target, then next.',
    ),
    _ScenarioEntry(
      targetId: homeSameStepHintsId,
      title: 'Same-step hints',
      subtitle: 'Several hints rendered at the same time.',
      icon: Icons.dashboard_customize,
      pageBuilder: (BuildContext context) => const SameStepHintsPage(),
      guideTitle: 'Same-step hints',
      guideMessage:
          'Use one step when nearby controls should be explained together.',
    ),
    _ScenarioEntry(
      targetId: homeSameStepScrollId,
      title: 'Same-step scroll',
      subtitle: 'One step that scrolls between distant targets.',
      icon: Icons.swap_vert,
      pageBuilder: (BuildContext context) => const SameStepScrollPage(),
      guideTitle: 'Same-step scroll',
      guideMessage:
          'This page shows the sequential auto-scroll behavior inside one step.',
    ),
    _ScenarioEntry(
      targetId: homeLazyTargetId,
      title: 'Lazy target',
      subtitle: 'Reveal a target that is not built yet.',
      icon: Icons.vertical_align_bottom,
      pageBuilder: (BuildContext context) => const LazyTargetPage(),
      guideTitle: 'Lazy target reveal',
      guideMessage:
          'Use onReveal when a lazy list row must be built before it can be highlighted.',
    ),
    _ScenarioEntry(
      targetId: homeBarrierDismissId,
      title: 'Barrier dismiss',
      subtitle: 'Close from empty-space taps at controlled times.',
      icon: Icons.touch_app,
      pageBuilder: (BuildContext context) => const BarrierDismissPage(),
      guideTitle: 'Barrier dismiss',
      guideMessage:
          'Compare default, complete-only and anytime outside-tap closing.',
    ),
    _ScenarioEntry(
      targetId: homeDynamicStepsId,
      title: 'Dynamic steps',
      subtitle: 'Skip optional targets and reset safely.',
      icon: Icons.rule,
      pageBuilder: (BuildContext context) => const DynamicStepsPage(),
      guideTitle: 'Dynamic steps',
      guideMessage:
          'This scenario covers server-driven targets and runtime target availability.',
    ),
    _ScenarioEntry(
      targetId: homeSideAnchorsId,
      title: 'Side anchors',
      subtitle: 'Horizontal auto placement chooses left or right.',
      icon: Icons.compare_arrows,
      pageBuilder: (BuildContext context) => const SideAnchorPage(),
      guideTitle: 'Side anchors',
      guideMessage:
          'This scene shows horizontalAuto choosing the larger side and drawing left or right arrows.',
    ),
    _ScenarioEntry(
      targetId: homeLargeGroupId,
      title: 'Large group',
      subtitle: 'Highlight repeated target ids as one group.',
      icon: Icons.center_focus_strong,
      pageBuilder: (BuildContext context) => const LargeGroupPage(),
      guideTitle: 'Large group anchor',
      guideMessage:
          'Use target groups when several widgets should light up together.',
    ),
    _ScenarioEntry(
      targetId: homeCustomAnchorId,
      title: 'Custom anchor',
      subtitle: 'Move the anchor and customize the bubble.',
      icon: Icons.call_split,
      pageBuilder: (BuildContext context) => const CustomAnchorPage(),
      guideTitle: 'Custom anchor',
      guideMessage:
          'This scene demonstrates anchor offsets and custom bubble decoration.',
    ),
    _ScenarioEntry(
      targetId: homeControllerApiId,
      title: 'Controller API',
      subtitle: 'Drive the guide with an external controller.',
      icon: Icons.settings_remote,
      pageBuilder: (BuildContext context) => const ControllerApiPage(),
      guideTitle: 'Controller API',
      guideMessage:
          'Open this when you want to test showPortal, next, previous, goTo and reset.',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotlight Guide Examples'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Replay intro',
            icon: const Icon(Icons.replay),
            onPressed: _replayIntro,
          ),
          IconButton(
            tooltip: 'Hide guide',
            icon: const Icon(Icons.close),
            onPressed: _introController.hide,
          ),
        ],
      ),
      body: SpotlightGuidePortal(
        controller: _introController,
        autoStart: true,
        steps: _buildIntroSteps(),
        barrierDismissBehavior: SpotlightGuideBarrierDismissBehavior.anytime,
        barrier: const SpotlightGuideBarrierStyle(
          color: Color(0xA6000000),
          blurSigma: 1.5,
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: <Widget>[
              for (final _ScenarioEntry entry in _entries) ...<Widget>[
                SpotlightGuideTarget(
                  id: entry.targetId,
                  child: _ScenarioButton(
                    entry: entry,
                    onPressed: () => _openScenario(entry),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<SpotlightGuideStep> _buildIntroSteps() {
    return _entries
        .map((_ScenarioEntry entry) {
          return SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: entry.targetId,
              placement: SpotlightGuidePlacement.verticalAuto,
              targetPadding: const EdgeInsets.all(4),
              targetRadius: 12,
              decoration: SpotlightGuideBubbleDecoration(
                anchor: SpotlightGuideTriangleAnchor(
                  size: Size(24, 16),
                  tipArcAngle: pi / 6,
                ),
              ),
              //maxWidth: 320,
              margin: EdgeInsets.symmetric(horizontal: 16),
              targetAnchorPosition: SpotlightGuideAnchorPosition.start(0),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return buildGuideHint(
                      guide: guide,
                      title: entry.guideTitle,
                      message: entry.guideMessage,
                    );
                  },
            ),
          );
        })
        .toList(growable: false);
  }

  void _openScenario(_ScenarioEntry entry) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: entry.pageBuilder));
  }

  Future<void> _replayIntro() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) {
      return;
    }
    _introController.reset();
  }
}

class _ScenarioButton extends StatelessWidget {
  const _ScenarioButton({required this.entry, required this.onPressed});

  final _ScenarioEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(104),
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Row(
        children: <Widget>[
          Icon(entry.icon, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(entry.subtitle, maxLines: 3),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _ScenarioEntry {
  const _ScenarioEntry({
    required this.targetId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pageBuilder,
    required this.guideTitle,
    required this.guideMessage,
  });

  final String targetId;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder pageBuilder;
  final String guideTitle;
  final String guideMessage;
}
