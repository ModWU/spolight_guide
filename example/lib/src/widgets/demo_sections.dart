import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';
import 'example_cards.dart';

class MetricsSection extends StatelessWidget {
  const MetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MetricTarget(
          targetId: metricWeightId,
          title: 'Total weight',
          value: '128.5 g',
          icon: Icons.scale,
        ),
        const SizedBox(width: 8),
        _MetricTarget(
          targetId: metricCostId,
          anchorId: metricCostAnchorId,
          title: 'Total cost',
          value: 'JPY 82,400',
          icon: Icons.payments,
        ),
        const SizedBox(width: 8),
        _MetricTarget(
          targetId: metricPriceId,
          title: 'Unit price',
          value: '641/g',
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _MetricTarget extends StatelessWidget {
  const _MetricTarget({
    required this.targetId,
    required this.title,
    required this.value,
    required this.icon,
    this.anchorId,
  });

  final String targetId;
  final String title;
  final String value;
  final IconData icon;
  final Object? anchorId;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SpotlightGuideTarget(
        id: metricGroupId,
        anchorId: anchorId,
        child: SpotlightGuideTarget(
          id: targetId,
          child: MetricCard(title: title, value: value, icon: icon),
        ),
      ),
    );
  }
}

class WideTargetsSection extends StatelessWidget {
  const WideTargetsSection({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ScenarioPanel(
      title: 'Wide same-step targets',
      child: SizedBox(
        height: 112,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const <Widget>[
              SpotlightGuideTarget(
                id: wideStartId,
                child: _WideCard(title: 'Visible card', value: 'Start'),
              ),
              SizedBox(width: 220),
              SpotlightGuideTarget(
                id: wideEndId,
                child: _WideCard(title: 'Offscreen card', value: 'End'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityIntroSection extends StatelessWidget {
  const ActivityIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpotlightGuideTarget(
      id: activityHeaderId,
      child: ScenarioPanel(
        title: 'Recent activity',
        child: Text(
          'The lazy target scenario scrolls this history list until the target '
          'row exists, then positions the hint after reveal finishes.',
        ),
      ),
    );
  }
}

class HistoryListSection extends StatelessWidget {
  const HistoryListSection({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E4E7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListView.builder(
          controller: controller,
          itemExtent: historyItemExtent,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: 42,
          itemBuilder: (BuildContext context, int index) {
            final bool isTarget = index == lazyHistoryIndex;
            final Widget row = HistoryRow(index: index, isTarget: isTarget);
            if (isTarget) {
              return SpotlightGuideTarget(id: lazyHistoryId, child: row);
            }
            return row;
          },
        ),
      ),
    );
  }
}

class OptionalApiSection extends StatelessWidget {
  const OptionalApiSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpotlightGuideTarget(
      id: optionalOfferId,
      child: ScenarioPanel(
        title: 'Optional API section',
        child: Text(
          'This block simulates a server-driven target. Dynamic steps skip this '
          'guide item when the target is not mounted.',
        ),
      ),
    );
  }
}

class AddSavingButton extends StatelessWidget {
  const AddSavingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SpotlightGuideTarget(
      id: addSavingId,
      child: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add saving'),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FA),
          border: Border.all(color: const Color(0xFFE6EAED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
