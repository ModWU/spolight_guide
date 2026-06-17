import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../scenarios/barrier_dismiss_scenario.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class BarrierDismissPage extends StatefulWidget {
  const BarrierDismissPage({super.key});

  @override
  State<BarrierDismissPage> createState() => _BarrierDismissPageState();
}

class _BarrierDismissPageState extends State<BarrierDismissPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  BarrierDismissDemoMode _mode = BarrierDismissDemoMode.anytime;
  String _guideStatus = 'Guide is idle.';

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Barrier dismiss',
      controller: _guideController,
      steps: buildBarrierDismissScenario(_mode),
      barrierDismissBehavior: _mode.behavior,
      onStateChanged: _handleGuideStateChanged,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          ScenarioPanel(title: 'Dismiss behavior', child: _buildModePanel()),
          const SizedBox(height: 16),
          ScenarioPanel(title: 'Targets', child: _buildTargets()),
        ],
      ),
    );
  }

  Widget _buildModePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<BarrierDismissDemoMode>(
          showSelectedIcon: false,
          segments: const <ButtonSegment<BarrierDismissDemoMode>>[
            ButtonSegment<BarrierDismissDemoMode>(
              value: BarrierDismissDemoMode.anytime,
              icon: Icon(Icons.touch_app),
              label: Text('Any'),
            ),
            ButtonSegment<BarrierDismissDemoMode>(
              value: BarrierDismissDemoMode.onComplete,
              icon: Icon(Icons.flag),
              label: Text('Final'),
            ),
            ButtonSegment<BarrierDismissDemoMode>(
              value: BarrierDismissDemoMode.disabled,
              icon: Icon(Icons.block),
              label: Text('Off'),
            ),
          ],
          selected: <BarrierDismissDemoMode>{_mode},
          onSelectionChanged: _selectMode,
        ),
        const SizedBox(height: 12),
        Text(_mode.summary),
        const Divider(height: 24),
        Text(_guideStatus),
      ],
    );
  }

  Widget _buildTargets() {
    return Column(
      children: const <Widget>[
        SpotlightGuideTarget(
          id: barrierDismissAnytimeId,
          child: _DismissTargetRow(
            icon: Icons.touch_app,
            title: 'Anytime close',
            value: 'No button in the hint',
          ),
        ),
        Divider(height: 20),
        SpotlightGuideTarget(
          id: barrierDismissOnCompleteStartId,
          child: _DismissTargetRow(
            icon: Icons.looks_one,
            title: 'Complete-only start',
            value: 'Outside tap waits',
          ),
        ),
        SizedBox(height: 8),
        SpotlightGuideTarget(
          id: barrierDismissOnCompleteEndId,
          child: _DismissTargetRow(
            icon: Icons.looks_two,
            title: 'Complete-only final',
            value: 'Outside tap finishes',
          ),
        ),
        Divider(height: 20),
        SpotlightGuideTarget(
          id: barrierDismissDisabledId,
          child: _DismissTargetRow(
            icon: Icons.block,
            title: 'Default disabled',
            value: 'Button finishes',
          ),
        ),
      ],
    );
  }

  void _selectMode(Set<BarrierDismissDemoMode> selected) {
    final BarrierDismissDemoMode nextMode = selected.single;
    if (nextMode == _mode) {
      _guideController.reset();
      return;
    }
    setState(() {
      _mode = nextMode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _guideController.reset();
      }
    });
  }

  void _handleGuideStateChanged(SpotlightGuideStateDetails details) {
    if (!mounted) {
      return;
    }
    setState(() {
      _guideStatus =
          '${details.reason.name}: index ${details.index + 1}/${details.total}, '
          'mode ${_mode.name}';
    });
  }
}

class _DismissTargetRow extends StatelessWidget {
  const _DismissTargetRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 19,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
