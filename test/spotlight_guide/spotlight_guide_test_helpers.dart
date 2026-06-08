import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a simple labeled hint and optionally records the resolved guide
/// context for later geometry assertions.
SpotlightGuideHintBuilder hint(
  String label, [
  Map<String, SpotlightGuideStepContext>? contexts,
]) {
  return sizedHint(label, 80, 32, contexts);
}

/// Builds a fixed-size hint used by placement and constraint tests.
SpotlightGuideHintBuilder sizedHint(
  String label,
  double width,
  double height, [
  Map<String, SpotlightGuideStepContext>? contexts,
]) {
  return (BuildContext context, SpotlightGuideStepContext guide) {
    contexts?[label] = guide;
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Colors.white,
        child: Center(child: Text(label, key: ValueKey<String>(label))),
      ),
    );
  };
}

/// Returns the side length that owns the arrow for the resolved placement.
double arrowSideExtent(SpotlightGuideStepContext guide) {
  return switch (guide.indicatorDirection) {
    SpotlightGuideIndicatorDirection.up ||
    SpotlightGuideIndicatorDirection.down => guide.hintRect.width,
    SpotlightGuideIndicatorDirection.left ||
    SpotlightGuideIndicatorDirection.right => guide.hintRect.height,
  };
}

/// Builds a minimal app shell with one [SpotlightGuidePortal].
///
/// The default child contains two visible targets, `a` and `b`, which keeps most
/// tests focused on guide behavior instead of setup.
Widget guideApp({
  List<SpotlightGuideStep> steps = const <SpotlightGuideStep>[],
  Key? appKey,
  Locale? locale,
  SpotlightGuidePortalController? controller,
  SpotlightGuideStepCallback? onStepWillShow,
  SpotlightGuideStateCallback? onStateChanged,
  VoidCallback? onFinish,
  SpotlightGuideBarrierTapCallback? onBarrierTap,
  SpotlightGuideBarrierDismissBehavior barrierDismissBehavior =
      SpotlightGuideBarrierDismissBehavior.disabled,
  SpotlightGuideBarrierStyle barrier = const SpotlightGuideBarrierStyle(),
  bool blockInteractionDuringPreparation = true,
  SpotlightGuideRevealPresentationStrategy revealPresentationStrategy =
      const SpotlightGuideDeferredRevealPresentationStrategy(),
  TextDirection textDirection = TextDirection.ltr,
  bool enabled = true,
  bool? autoStart,
  SpotlightGuideMissingTargetBehavior missingTargetBehavior =
      SpotlightGuideMissingTargetBehavior.wait,
  Widget? child,
}) {
  return MaterialApp(
    key: appKey,
    locale: locale,
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: SizedBox.expand(
          child: SpotlightGuidePortal(
            controller: controller,
            enabled: enabled,
            autoStart: autoStart,
            missingTargetBehavior: missingTargetBehavior,
            steps: steps,
            onStepWillShow: onStepWillShow,
            onStateChanged: onStateChanged,
            onFinish: onFinish,
            onBarrierTap: onBarrierTap,
            barrierDismissBehavior: barrierDismissBehavior,
            barrier: barrier,
            blockInteractionDuringPreparation:
                blockInteractionDuringPreparation,
            revealPresentationStrategy: revealPresentationStrategy,
            child:
                child ??
                Stack(
                  children: const <Widget>[
                    Positioned(
                      left: 40,
                      top: 40,
                      child: SpotlightGuideTarget(
                        id: 'a',
                        child: SizedBox(
                          width: 100,
                          height: 40,
                          child: ColoredBox(color: Colors.red),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 240,
                      top: 360,
                      child: SpotlightGuideTarget(
                        id: 'b',
                        child: SizedBox(
                          width: 80,
                          height: 50,
                          child: ColoredBox(color: Colors.blue),
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

/// Builds a stack with one positioned registered target.
Widget singleTargetStack({
  required Object id,
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  return Stack(
    children: <Widget>[
      Positioned(
        left: left,
        top: top,
        child: SpotlightGuideTarget(
          id: id,
          child: SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    ],
  );
}

/// Builds a stack whose target can be inserted or removed between pumps.
Widget optionalTargetStack({
  required bool showTarget,
  required Object id,
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  return Stack(
    children: <Widget>[
      if (showTarget)
        Positioned(
          left: left,
          top: top,
          child: SpotlightGuideTarget(
            id: id,
            child: SizedBox(
              width: width,
              height: height,
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
    ],
  );
}

/// Builds one offscreen target inside a vertical or horizontal scroll view.
///
/// Used by reveal tests that verify default `Scrollable.ensureVisible` behavior
/// for every fixed [SpotlightGuidePlacement].
Widget singleScrollableTarget({
  required Object id,
  required ScrollController controller,
  required Axis scrollDirection,
}) {
  final bool horizontal = scrollDirection == Axis.horizontal;
  return SingleChildScrollView(
    controller: controller,
    scrollDirection: scrollDirection,
    child: SizedBox(
      width: horizontal ? 1200 : 400,
      height: horizontal ? 400 : 1200,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: horizontal ? 1050 : 40,
            top: horizontal ? 40 : 1050,
            child: SpotlightGuideTarget(
              id: id,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds a horizontal scrollable with one highlighted group and one anchor
/// target inside that group.
Widget horizontalGroupedTargets({
  required ScrollController controller,
  required Object groupId,
  required Object anchorId,
  double contentWidth = 1200,
  double groupLeft = 0,
  double groupTop = 120,
  double groupWidth = 500,
  double groupHeight = 80,
  double anchorLeft = 300,
  double anchorTop = 140,
  double anchorWidth = 120,
  double anchorHeight = 40,
}) {
  return SingleChildScrollView(
    controller: controller,
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: contentWidth,
      height: 600,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: groupLeft,
            top: groupTop,
            child: SpotlightGuideTarget(
              id: groupId,
              child: SizedBox(
                width: groupWidth,
                height: groupHeight,
                child: const ColoredBox(color: Colors.red),
              ),
            ),
          ),
          Positioned(
            left: anchorLeft,
            top: anchorTop,
            child: SpotlightGuideTarget(
              id: anchorId,
              child: SizedBox(
                width: anchorWidth,
                height: anchorHeight,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Default interval used by auto-scroll widget tests.
///
/// Use [pumpAutoScrollInterval] with the same value so timer-driven tests stay
/// deterministic and do not advance the clock during initial frame pumps.
const Duration kAutoScrollTestInterval = Duration(milliseconds: 120);

/// Pumps layout frames after [SpotlightGuidePortalController.reset] without
/// advancing the fake-async clock (avoids firing auto-scroll timers early).
Future<void> pumpGuideFrames(WidgetTester tester, {int count = 12}) async {
  for (int i = 0; i < count; i++) {
    await tester.pump();
  }
}

/// Records [SpotlightGuideAutoScrollItemContext.itemIndex] for tests.
void recordAutoScrollItemIndex(
  List<int> indices,
  SpotlightGuideAutoScrollItemContext context,
) {
  indices.add(context.itemIndex);
}

/// Advances the fake-async clock by [interval] and settles animations.
Future<void> pumpAutoScrollInterval(
  WidgetTester tester, {
  Duration interval = kAutoScrollTestInterval,
}) async {
  await tester.pump(interval);
  await tester.pumpAndSettle();
}

/// Builds two mounted targets far apart on one scroll axis.
///
/// Used by same-step auto-scroll tests where the first item opens the step and
/// the second item should be revealed after the configured interval.
Widget multiItemScrollableTargets({
  required ScrollController controller,
  required Axis scrollDirection,
  required Object firstId,
  required Object secondId,
}) {
  final bool horizontal = scrollDirection == Axis.horizontal;
  return SingleChildScrollView(
    controller: controller,
    scrollDirection: scrollDirection,
    child: SizedBox(
      width: horizontal ? 1400 : 400,
      height: horizontal ? 400 : 1400,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 40,
            top: 40,
            child: SpotlightGuideTarget(
              id: firstId,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
          Positioned(
            left: horizontal ? 1150 : 40,
            top: horizontal ? 40 : 1150,
            child: SpotlightGuideTarget(
              id: secondId,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds three mounted targets along one scroll axis for multi-tick auto scroll.
Widget tripleItemScrollableTargets({
  required ScrollController controller,
  required Axis scrollDirection,
  required Object firstId,
  required Object secondId,
  required Object thirdId,
}) {
  final bool horizontal = scrollDirection == Axis.horizontal;
  return SingleChildScrollView(
    controller: controller,
    scrollDirection: scrollDirection,
    child: SizedBox(
      width: horizontal ? 2000 : 400,
      height: horizontal ? 400 : 2000,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 40,
            top: 40,
            child: SpotlightGuideTarget(
              id: firstId,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
          Positioned(
            left: horizontal ? 700 : 40,
            top: horizontal ? 40 : 700,
            child: SpotlightGuideTarget(
              id: secondId,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.green),
              ),
            ),
          ),
          Positioned(
            left: horizontal ? 1750 : 40,
            top: horizontal ? 40 : 1750,
            child: SpotlightGuideTarget(
              id: thirdId,
              child: const SizedBox(
                width: 100,
                height: 50,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Expected result for auto placement selection tests.
class PlacementCase {
  const PlacementCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
    required this.targetTop,
    required this.expected,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
  final double targetTop;
  final SpotlightGuidePlacement expected;
}

/// Fixed placement and scroll axis pair used by reveal tests.
class RevealPlacementCase {
  const RevealPlacementCase({
    required this.label,
    required this.placement,
    required this.scrollDirection,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final Axis scrollDirection;
}

/// Fixed placement case used to verify arrow safe-area behavior.
class SafeAreaPlacementCase {
  const SafeAreaPlacementCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
    required this.targetTop,
    required this.anchor,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
  final double targetTop;
  final SpotlightGuideAnchorPosition anchor;
}

/// Fixed placement case used to verify pointer positioning for side bubbles.
class PointerPlacementCase {
  const PointerPlacementCase({
    required this.label,
    required this.placement,
    required this.targetLeft,
  });

  final String label;
  final SpotlightGuidePlacement placement;
  final double targetLeft;
}

/// Pumps enough frames for the portal's post-frame preparation, measurement,
/// overlay rendering, and zero-duration scroll work to settle.
Future<void> pumpGuide(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Test widget used to prove toggling [SpotlightGuidePortal.enabled] does not
/// recreate the child subtree.
class CountingTargetStack extends StatefulWidget {
  const CountingTargetStack({super.key, required this.onInit});

  final VoidCallback onInit;

  @override
  State<CountingTargetStack> createState() => CountingTargetStackState();
}

class CountingTargetStackState extends State<CountingTargetStack> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const <Widget>[
        Positioned(
          left: 40,
          top: 40,
          child: SpotlightGuideTarget(
            id: 'a',
            child: SizedBox(
              width: 100,
              height: 40,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
