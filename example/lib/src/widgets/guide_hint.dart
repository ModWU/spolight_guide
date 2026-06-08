import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

Widget buildGuideHint({
  required SpotlightGuideStepContext guide,
  required String title,
  required String message,
}) {
  final String progress = guide.itemTotal > 1
      ? 'Step ${guide.index + 1}/${guide.total} · Item ${guide.itemIndex + 1}/${guide.itemTotal}'
      : 'Step ${guide.index + 1}/${guide.total}';
  return SpotlightGuideBubbleHint(
    guide: guide,
    child: GuideHintBody(
      title: title,
      message: message,
      progress: progress,
      primaryLabel: guide.isLast ? 'Done' : 'Next',
      onPrimary: guide.next,
      onSecondary: guide.isFirst ? null : guide.previous,
    ),
  );
}

class GuideHintBody extends StatelessWidget {
  const GuideHintBody({
    super.key,
    required this.title,
    required this.message,
    required this.progress,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String progress;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    progress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(message),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (onSecondary != null) ...<Widget>[
                TextButton(onPressed: onSecondary, child: const Text('Back')),
                const SizedBox(width: 8),
              ],
              FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
