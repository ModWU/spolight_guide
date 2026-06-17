part of '../../spotlight_guide.dart';

/// A ready-to-use text hint for common guide steps.
///
/// This widget keeps the low-level [SpotlightGuideBubbleHint] API available
/// while removing the boilerplate needed for ordinary title/message/action
/// hints. It owns its content padding, so
/// [SpotlightGuideBubbleDecoration.contentPadding] can stay zero by default for
/// fully custom hint bodies.
///
/// Use [SpotlightGuideBubbleHint] directly when a step needs a custom layout.
class SpotlightGuideTextHint extends StatelessWidget {
  const SpotlightGuideTextHint({
    super.key,
    required this.guide,
    required this.title,
    this.message,
    this.progressLabel,
    this.showProgress = true,
    this.showActions = true,
    this.showBackButton = true,
    this.showSkipButton = false,
    this.backLabel = 'Back',
    this.nextLabel = 'Next',
    this.doneLabel = 'Done',
    this.skipLabel = 'Skip',
    this.onBack,
    this.onPrimary,
    this.onSkip,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.titleStyle,
    this.messageStyle,
    this.progressStyle,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.footer,
    this.semanticsLabel,
    this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Resolved layout and navigation data for the active guide item.
  final SpotlightGuideStepContext guide;

  /// Main hint title.
  final String title;

  /// Optional explanatory copy below [title].
  final String? message;

  /// Optional progress text override.
  ///
  /// When null, a compact step/item progress label is generated from [guide].
  final String? progressLabel;

  /// Whether to show the progress label.
  final bool showProgress;

  /// Whether to show the action row.
  ///
  /// For same-step multi-item guides, actions are shown only on the final item
  /// so earlier auto-scroll hints do not accidentally finish the whole guide.
  final bool showActions;

  /// Whether to show a back action when the current step is not the first step.
  final bool showBackButton;

  /// Whether to show a skip action.
  final bool showSkipButton;

  /// Label for the back button.
  final String backLabel;

  /// Label for the primary button before the final visible item.
  final String nextLabel;

  /// Label for the primary button on the final visible item.
  final String doneLabel;

  /// Label for the skip button.
  final String skipLabel;

  /// Override the default back behavior.
  final VoidCallback? onBack;

  /// Override the default primary behavior.
  ///
  /// By default the button calls [SpotlightGuideStepContext.next] or
  /// [SpotlightGuideStepContext.finish] on the final visible item.
  final VoidCallback? onPrimary;

  /// Override the default skip behavior.
  ///
  /// By default the skip button calls [SpotlightGuideStepContext.finish].
  final VoidCallback? onSkip;

  /// Padding owned by the text body.
  final EdgeInsetsGeometry padding;

  /// Optional style for [title].
  final TextStyle? titleStyle;

  /// Optional style for [message].
  final TextStyle? messageStyle;

  /// Optional style for the progress label.
  final TextStyle? progressStyle;

  /// Optional style for the next/done action.
  final ButtonStyle? primaryButtonStyle;

  /// Optional style for back and skip actions.
  final ButtonStyle? secondaryButtonStyle;

  /// Optional widget placed between the text block and action row.
  final Widget? footer;

  /// Optional semantic label for screen readers.
  ///
  /// When null, [title] and [message] are used.
  final String? semanticsLabel;

  /// Optional bubble decoration override.
  final SpotlightGuideAnchoredDecoration? decoration;

  /// Clip behavior applied to the bubble content body.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return SpotlightGuideBubbleHint(
      guide: guide,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: semanticsLabel ?? _defaultSemanticsLabel,
        child: Padding(
          padding: padding,
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
                      if (showProgress) ...<Widget>[
                        Text(
                          progressLabel ?? _defaultProgressLabel,
                          style: _effectiveProgressStyle(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(title, style: _effectiveTitleStyle(context)),
                      if (message != null && message!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(message!, style: _effectiveMessageStyle(context)),
                      ],
                    ],
                  ),
                ),
              ),
              if (footer != null) ...<Widget>[
                const SizedBox(height: 14),
                footer!,
              ],
              if (_shouldShowActions) ...<Widget>[
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (showSkipButton)
          TextButton(
            onPressed: onSkip ?? guide.finish,
            style: secondaryButtonStyle,
            child: Text(skipLabel),
          ),
        if (showBackButton && !guide.isFirst)
          TextButton(
            onPressed: onBack ?? guide.previous,
            style: secondaryButtonStyle,
            child: Text(backLabel),
          ),
        FilledButton(
          onPressed:
              onPrimary ?? (_isFinalVisibleItem ? guide.finish : guide.next),
          style: primaryButtonStyle,
          child: Text(_isFinalVisibleItem ? doneLabel : nextLabel),
        ),
      ],
    );
  }

  TextStyle _effectiveProgressStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return progressStyle ??
        TextStyle(
          fontSize: 12,
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        );
  }

  TextStyle _effectiveTitleStyle(BuildContext context) {
    return titleStyle ??
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
  }

  TextStyle _effectiveMessageStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return messageStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.82),
          height: 1.35,
        ) ??
        TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.82),
          height: 1.35,
        );
  }

  String get _defaultProgressLabel {
    final String step = 'Step ${guide.index + 1}/${guide.total}';
    if (guide.itemTotal <= 1) {
      return step;
    }
    return '$step - Item ${guide.itemIndex + 1}/${guide.itemTotal}';
  }

  String get _defaultSemanticsLabel {
    final String? copy = message;
    if (copy == null || copy.isEmpty) {
      return title;
    }
    return '$title. $copy';
  }

  bool get _isFinalVisibleItem => guide.isLast && guide.isLastItem;

  bool get _shouldShowActions {
    if (!showActions) {
      return false;
    }
    return guide.itemTotal == 1 || guide.isLastItem;
  }
}
