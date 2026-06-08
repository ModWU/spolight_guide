# Spotlight Guide Examples

## Saving More Button Guide

This mirrors the saving page pattern: the real more button is highlighted by the barrier hole, while the pointer image and bubble are custom guide UI.

```dart
SpotlightGuidePortal(
  enabled: model.showMoreGuide,
  barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
  steps: <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: SavingGuideTargets.more,
        placement: SpotlightGuidePlacement.bottom,
        targetAnchorPosition: const SpotlightGuideAnchorPosition.end(-8),
        decoration: const SpotlightGuideBubbleDecoration(
          borderRadius: 8,
          anchor: SpotlightGuideTriangleAnchor(
            size: Size(24, 16),
            tipArcAngle: 0.35,
          ),
        ),
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return SpotlightGuideBubbleHint(
            guide: guide,
            pointer: Image.asset('assets/guide_hand.png'),
            pointerSize: const Size(70, 54),
            pointerAnchorPosition: const SpotlightGuideAnchorPosition.end(14),
            bubbleBodyOffset: 100,
            child: TextButton(
              onPressed: guide.finish,
              child: const Text('I know'),
            ),
          );
        },
      ),
    ),
  ],
  onFinish: controller.markMoreGuideSeen,
  child: SpotlightGuideTarget(
    id: SavingGuideTargets.more,
    child: IconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: openMoreActions,
    ),
  ),
)
```

## API-Driven Steps

When automatic display is allowed, rebuild the portal with the returned steps.
The first non-empty list starts when no external controller is supplied.

```dart
SpotlightGuidePortal(
  enabled: userAllowsAutoGuide,
  steps: buildGuideSteps(remoteGuideConfig),
  onFinish: markGuideSeen,
  child: page,
)
```

When the user disables automatic guides, or when a guide should appear after a
later scenario, keep a controller and show the runtime steps directly.

```dart
final SpotlightGuidePortalController guideController =
    SpotlightGuidePortalController();

SpotlightGuidePortal(
  controller: guideController,
  autoStart: false,
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
  onStateChanged: (SpotlightGuideStateContext state) {
    trackGuideState(
      index: state.index,
      total: state.total,
      resolvedItemCount: state.resolvedItemCount,
      reason: state.reason,
    );
  },
  child: page,
);

Future<void> maybeShowGuide() async {
  final RemoteGuideConfig config = await api.fetchGuideConfig();
  final List<SpotlightGuideStep> steps = <SpotlightGuideStep>[
    if (config.showAnalyse)
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'saving-analyse',
          hintBuilder: buildAnalyseHint,
        ),
      ),
    if (config.showMore)
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'saving-more',
          hintBuilder: buildMoreHint,
        ),
      ),
  ];

  if (steps.isEmpty) {
    guideController.hide();
  } else {
    guideController.showSteps(steps);
  }
}
```

If one of the returned steps points at a target that is not present in the
current page state, the portal-level `skip` behavior removes it from the active
sequence. That means progress state updates as if the step were never returned:
`2 / 3` can become `2 / 2` and the current hint rebuilds with `isLast == true`.
For a lazy or conditionally inserted target that should be allowed to appear
later, override the item:

```dart
SpotlightGuideStepItem(
  targetId: 'lazy-row',
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
  onReveal: revealLazyRow,
  hintBuilder: buildLazyRowHint,
)
```

## Empty-Space Dismiss

The dim barrier absorbs taps by default. Opt in when empty-space taps should
close the guide:

```dart
SpotlightGuidePortal(
  barrierDismissBehavior: SpotlightGuideBarrierDismissBehavior.onComplete,
  steps: steps,
  child: page,
)
```

Use `onComplete` when outside taps should work only after the last step or final
same-step item is visible. Use `anytime` for lightweight introductions where the
user may dismiss immediately:

```dart
SpotlightGuidePortal(
  barrierDismissBehavior: SpotlightGuideBarrierDismissBehavior.anytime,
  steps: steps,
  child: page,
)
```

## Lazy List Row

Use `onReveal` when the row may not be mounted.

```dart
SpotlightGuideStepItem(
  targetId: 'history-row-40',
  onReveal: (SpotlightGuideRevealContext context) async {
    await context.scrollToIndex(
      controller: historyScrollController,
      index: 40,
      itemExtent: rowExtent,
      alignment: 0.2,
    );
  },
  revealOptions: const SpotlightGuideRevealOptions(
    alignment: 0.5,
    duration: Duration(milliseconds: 250),
  ),
  hintBuilder: buildHistoryHint,
)
```

The default reveal scrolls only if the mounted target is outside the visible
viewport. If a product deliberately wants every reveal to recenter the target,
set `scrollPolicy: SpotlightGuideRevealScrollPolicy.always`.

For one hint that lights a large group but should point at one important card,
set `anchorTargetId`. The default reveal scroll target policy uses the full
group when it can fit, then falls back to the anchor when the group is too
large:

```dart
SpotlightGuideStepItem(
  targetIds: const <Object>['summary-row', 'summary-cost'],
  anchorTargetId: 'summary-cost',
  revealOptions: const SpotlightGuideRevealOptions(
    scrollTargetPolicy:
        SpotlightGuideRevealScrollTargetPolicy.anchorTargetWhenHighlightedAreaCannotFit,
  ),
  hintBuilder: buildCostHint,
)
```

## Same Step With Distant Targets

The default `SpotlightGuideStepAutoScrollOptions` scrolls to later hidden mounted items after a short interval. Override it only when the step should remain static.

```dart
SpotlightGuideStep(
  autoScrollOptions: SpotlightGuideStepAutoScrollOptions(
    interval: const Duration(milliseconds: 900),
    onAutoScrollItemChanged: (SpotlightGuideAutoScrollItemContext context) {
      final String progress =
          '${context.itemIndex + 1} / ${context.itemTotal}';
      final Object? analyticsKey = context.key ?? context.primaryHighlightTargetId;
      // context.highlightTargetIds lists every id lit by the focused item
    },
  ),
  items: <SpotlightGuideStepItem>[
    SpotlightGuideStepItem(targetId: 'top-filter', hintBuilder: buildFilterHint),
    SpotlightGuideStepItem(targetId: 'bottom-submit', hintBuilder: buildSubmitHint),
  ],
)
```

Disable the aid:

```dart
SpotlightGuideStep(
  autoScrollOptions: const SpotlightGuideStepAutoScrollOptions(enabled: false),
  items: items,
)
```

## Same-Step Layout Patterns

| Goal | Configuration |
| --- | --- |
| One hint, multiple areas lit together | One [SpotlightGuideStepItem] with `targetIds` (optional `anchorTargetId`) |
| Highlight every mounted instance of the same kind | Reuse one `SpotlightGuideTarget.id`; the instances become one target group |
| Highlight a repeated group but point at one chosen instance | Set `SpotlightGuideTarget.anchorId` on that instance and use `anchorTargetId` |
| Several hints at once (all on screen) | Multiple items in one step; auto scroll stays off when nothing is hidden |
| Several distant areas, explained one by one | Multiple items + default `autoScrollOptions`; use `onAutoScrollItemChanged` for copy/analytics |
| Stable business label independent of target id | `SpotlightGuideStepItem(key: 'your-key', targetId: 'widget-id', ...)` |
| Scroll to a lazy row, then highlight it | Later item `onReveal` + default auto scroll (deferred until its turn) |

```dart
// One hint, two registered targets
SpotlightGuideStepItem(
  key: 'save-group',
  targetIds: const <Object>['save-button', 'save-caption'],
  anchorTargetId: 'save-button',
  hintBuilder: buildSaveGroupHint,
)

// Repeated id group, with one explicit anchor target.
SpotlightGuideTarget(
  id: 'summary-card-group',
  anchorId: 'summary-cost-anchor',
  child: totalCostCard,
)

SpotlightGuideStepItem(
  targetId: 'summary-card-group',
  anchorTargetId: 'summary-cost-anchor',
  hintBuilder: buildCostHint,
)

// Progress copy + analytics in auto scroll
onAutoScrollItemChanged: (SpotlightGuideAutoScrollItemContext context) {
  if (context.highlightsWholePortalChild) {
    return;
  }
  track('guide_focus', context.key ?? context.highlightTargetIds);
}
```

## Tap The Highlighted Button To Continue

Let the user press the real highlighted control to advance, instead of dimming
it out. Taps inside the hole reach the page; the rest of the barrier still
absorbs.

```dart
SpotlightGuideStep.item(
  SpotlightGuideStepItem(
    targetId: 'send-button',
    allowTargetInteraction: true,
    placement: SpotlightGuidePlacement.top,
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return SpotlightGuideBubbleHint(
        guide: guide,
        child: const Text('Tap send to continue'),
      );
    },
  ),
)
```

## Stepping Back And Jumping

```dart
// From a hint button:
hintBuilder: (context, guide) => Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    TextButton(onPressed: guide.previous, child: const Text('Back')),
    TextButton(onPressed: guide.next, child: const Text('Next')),
  ],
);

// Or directly through the controller:
controller.goTo(0);
```
