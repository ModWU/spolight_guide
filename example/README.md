# Spotlight Guide Example

This app is a small playground for the main `spotlight_guide` integration
patterns.

Scenarios live in `lib/src/scenarios/`:

- `basic_steps_scenario.dart`: normal multi-step guide.
- `pointer_hint_scenario.dart`: built-in and custom pointer widgets, fixed
  sides, semantic/auto placement, and direct-target anchor mode.
- `barrier_dismiss_scenario.dart`: disabled, final-only, and anytime
  empty-space dismiss behavior.
- `same_step_hints_scenario.dart`: several hints in the same step.
- `same_step_scroll_scenario.dart`: same-step targets that require scroll,
  using an offscreen target in a horizontal scroll view.
- `lazy_target_reveal_scenario.dart`: a lazy list target that is not built at
  first and is revealed through `onReveal`.
- `side_anchor_scenario.dart`: horizontal auto placement with left and right
  arrows.
- `large_group_anchor_scenario.dart`: repeated target ids, large spotlight
  groups, and anchor target selection.
- `target_decoration_scenario.dart`: shape-aware rings, glows, shadows, and
  dashed target layers.
- `custom_anchor_scenario.dart`: custom target anchor position and selectable
  custom bubble arrows.
- `dynamic_steps_scenario.dart`: API-driven optional targets with skip behavior.
- `controller_usage_scenario.dart`: portal-owned steps shown through an external
  controller.

Run it from this directory:

```sh
flutter run
```

Or run it from the package root:

```sh
cd example
flutter run -d ios
flutter run -d android
```

README preview assets can be regenerated with Python and Pillow:

```sh
cd example
flutter test tool/readme_capture_test.dart --update-goldens
cd ..
python3 example/tool/build_readme_gifs.py
```
