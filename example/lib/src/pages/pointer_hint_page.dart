import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import '../scenarios/pointer_hint_scenario.dart';
import '../widgets/example_cards.dart';
import '../widgets/guide_scenario_scaffold.dart';

class PointerHintPage extends StatefulWidget {
  const PointerHintPage({super.key});

  @override
  State<PointerHintPage> createState() => _PointerHintPageState();
}

class _PointerHintPageState extends State<PointerHintPage> {
  final SpotlightGuidePortalController _guideController =
      SpotlightGuidePortalController();

  @override
  Widget build(BuildContext context) {
    return GuideScenarioScaffold(
      title: 'Pointer hint',
      controller: _guideController,
      steps: buildPointerHintScenario(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const <Widget>[
          ScenarioPanel(
            title: 'Target and pointer chain',
            child: _AnchorChainDemo(),
          ),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Top and bottom pointers',
            child: _VerticalPointerDemo(),
          ),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Custom pointer widgets',
            child: _CustomPointerDemo(),
          ),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Edge anchor alignment',
            child: _EdgeAnchorDemo(),
          ),
          SizedBox(height: 16),
          ScenarioPanel(title: 'Auto side pointer', child: _AutoSideDemo()),
          SizedBox(height: 16),
          ScenarioPanel(
            title: 'Direct target anchor',
            child: _DirectAnchorDemo(),
          ),
        ],
      ),
    );
  }
}

class _AnchorChainDemo extends StatelessWidget {
  const _AnchorChainDemo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        _LegendPill(label: 'Bubble', color: Color(0xFF316B67)),
        Expanded(child: _ConnectorLine()),
        _LegendPill(label: 'Pointer', color: Color(0xFF7B3FF2)),
        Expanded(child: _ConnectorLine()),
        Flexible(
          flex: 3,
          fit: FlexFit.tight,
          child: SpotlightGuideTarget(
            id: pointerLeftOfTargetId,
            child: _PointerTargetCard(
              icon: Icons.more_horiz,
              title: 'Target',
              subtitle: 'Real app button',
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalPointerDemo extends StatelessWidget {
  const _VerticalPointerDemo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: SpotlightGuideTarget(
            id: pointerAboveTargetId,
            child: _PointerTargetCard(
              icon: Icons.notifications_active_outlined,
              title: 'Top target',
              subtitle: 'Pointer appears above',
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PointerTargetCard(
            icon: Icons.download_done_rounded,
            title: 'Plain target',
            subtitle: 'No guide target here',
            muted: true,
          ),
        ),
      ],
    );
  }
}

class _CustomPointerDemo extends StatelessWidget {
  const _CustomPointerDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        Text(
          'The pointer can be any widget: an image, animation, icon badge, or '
          'CustomPaint.',
          style: TextStyle(color: Colors.black54),
        ),
        SizedBox(height: 12),
        SpotlightGuideTarget(
          id: pointerCustomAssetId,
          child: _WidePointerTargetCard(),
        ),
      ],
    );
  }
}

class _EdgeAnchorDemo extends StatelessWidget {
  const _EdgeAnchorDemo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SpotlightGuideTarget(
        id: pointerEdgeAnchorId,
        child: SizedBox(
          width: 112,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFA),
              border: Border.all(color: const Color(0xFFD9E1E4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(10, 11, 10, 11),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: Color(0xFF316B67),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Start-edge\nanchor',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoSideDemo extends StatelessWidget {
  const _AutoSideDemo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        SpotlightGuideTarget(
          id: pointerAutoSideId,
          child: _PointerTargetCard(
            icon: Icons.translate_rounded,
            title: 'Auto side',
            subtitle: 'Uses horizontalAuto',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'When localization or responsive layout moves the target, keep the '
            'pointer attached to the resolved placement instead of hard-coding '
            'a physical side.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _DirectAnchorDemo extends StatelessWidget {
  const _DirectAnchorDemo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.center,
      child: SpotlightGuideTarget(
        id: pointerDirectAnchorId,
        child: SizedBox(
          width: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF1),
              border: Border.all(color: const Color(0xFFE6D7B8)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.near_me_rounded, color: Color(0xFF9A6A00)),
                  SizedBox(height: 8),
                  Text(
                    'Anchor stays on target',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pointer is decorative',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PointerTargetCard extends StatelessWidget {
  const _PointerTargetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF4F5F5) : scheme.surface,
        border: Border.all(
          color: muted ? const Color(0xFFE0E0E0) : const Color(0xFFD9E1E4),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: muted ? Colors.black38 : scheme.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidePointerTargetCard extends StatelessWidget {
  const _WidePointerTargetCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        border: Border.all(color: const Color(0xFFD9E1E4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFF316B67),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Custom pointer target',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The target stays ordinary; the pointer is separate UI.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Divider(color: Color(0xFFB8C4C7), thickness: 1.4),
    );
  }
}
