import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Same-step [SpotlightGuideAutoScrollOptions] behavior.
///
/// These tests use [kAutoScrollTestInterval] with [pumpGuideFrames] and
/// [pumpAutoScrollInterval] so timer-driven work stays deterministic.
void main() {
  SpotlightGuideStep twoItemAutoScrollStep({
    SpotlightGuideAutoScrollOptions? autoScrollOptions,
    List<SpotlightGuideStepItem>? items,
  }) {
    return SpotlightGuideStep(
      revealOptions: const SpotlightGuideRevealOptions(duration: Duration.zero),
      autoScrollOptions:
          autoScrollOptions ??
          const SpotlightGuideAutoScrollOptions(
            interval: kAutoScrollTestInterval,
          ),
      items:
          items ??
          <SpotlightGuideStepItem>[
            SpotlightGuideStepItem(
              targetId: 'auto-a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('auto-a'),
            ),
            SpotlightGuideStepItem(
              targetId: 'auto-b',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('auto-b'),
            ),
          ],
    );
  }

  testWidgets('zero interval advances to the next item without waiting', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'zero-first',
          secondId: 'zero-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: Duration.zero,
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'zero-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('zero-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'zero-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('zero-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);

    expect(scrollController.offset, greaterThan(0));
    expect(find.byKey(const ValueKey<String>('zero-first')), findsNothing);
    expect(find.byKey(const ValueKey<String>('zero-second')), findsOneWidget);
  });

  testWidgets('three-item auto scroll reports indices 0 then 1 then 2', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<int> focusedIndices = <int>[];
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: tripleItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'tri-first',
          secondId: 'tri-second',
          thirdId: 'tri-third',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              interval: kAutoScrollTestInterval,
              onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                recordAutoScrollIndex(focusedIndices, details);
              },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'tri-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('tri-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'tri-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('tri-second'),
              ),
              SpotlightGuideStepItem(
                targetId: 'tri-third',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('tri-third'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuideFrames(tester);
    expect(focusedIndices, <int>[0]);
    expect(find.byKey(const ValueKey<String>('tri-first')), findsOneWidget);

    await pumpAutoScrollInterval(tester);
    expect(focusedIndices, <int>[0, 1]);
    expect(find.byKey(const ValueKey<String>('tri-second')), findsOneWidget);

    await pumpAutoScrollInterval(tester);
    expect(focusedIndices, <int>[0, 1, 2]);
    expect(find.byKey(const ValueKey<String>('tri-third')), findsOneWidget);
    expect(focusedIndices.toSet().length, 3);
  });

  testWidgets('finish before the interval prevents later auto-scroll work', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<int> focusedIndices = <int>[];
    int secondRevealCount = 0;
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'cancel-first',
          secondId: 'cancel-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              interval: kAutoScrollTestInterval,
              onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                recordAutoScrollIndex(focusedIndices, details);
              },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'cancel-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('cancel-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'cancel-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                onReveal: (_) {
                  secondRevealCount++;
                },
                hintBuilder: hint('cancel-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuideFrames(tester);
    expect(focusedIndices, <int>[0]);

    controller.finish();
    await pumpAutoScrollInterval(tester);

    expect(controller.isShowing, isFalse);
    expect(focusedIndices, <int>[0]);
    expect(secondRevealCount, 0);
    expect(find.byKey(const ValueKey<String>('cancel-second')), findsNothing);
  });

  testWidgets('next step before the interval abandons later same-step items', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    int secondRevealCount = 0;
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'advance-first',
          secondId: 'advance-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: const SpotlightGuideAutoScrollOptions(
              interval: kAutoScrollTestInterval,
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'advance-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('advance-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'advance-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                onReveal: (_) {
                  secondRevealCount++;
                },
                hintBuilder: hint('advance-second'),
              ),
            ],
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'advance-first',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('step-two'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuideFrames(tester);
    expect(find.byKey(const ValueKey<String>('advance-first')), findsOneWidget);
    expect(secondRevealCount, 0);

    controller.next();
    await pumpGuideFrames(tester);
    await pumpGuide(tester);

    expect(secondRevealCount, 0);
    expect(find.byKey(const ValueKey<String>('advance-second')), findsNothing);
    expect(find.byKey(const ValueKey<String>('step-two')), findsOneWidget);
  });

  testWidgets('single-item step does not run auto scroll callbacks', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<int> focusedIndices = <int>[];

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                recordAutoScrollIndex(focusedIndices, details);
              },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('solo'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    await pumpAutoScrollInterval(tester);

    expect(focusedIndices, isEmpty);
    expect(find.byKey(const ValueKey<String>('solo')), findsOneWidget);
  });

  testWidgets('disabled auto scroll does not call onItemChanged', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<int> focusedIndices = <int>[];
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'disabled-first',
          secondId: 'disabled-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              enabled: false,
              onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                recordAutoScrollIndex(focusedIndices, details);
              },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'disabled-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('disabled-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'disabled-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('disabled-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    await pumpAutoScrollInterval(tester);

    expect(focusedIndices, isEmpty);
    expect(scrollController.offset, greaterThan(0));
  });

  testWidgets(
    'onItemChanged does not repeat indices across extra frame pumps',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final List<int> focusedIndices = <int>[];
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: multiItemScrollableTargets(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            firstId: 'dedupe-first',
            secondId: 'dedupe-second',
          ),
          steps: <SpotlightGuideStep>[
            twoItemAutoScrollStep(
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                interval: kAutoScrollTestInterval,
                onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                  recordAutoScrollIndex(focusedIndices, details);
                },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'dedupe-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('dedupe-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'dedupe-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('dedupe-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);
      await pumpAutoScrollInterval(tester);
      for (int i = 0; i < 20; i++) {
        await tester.pump();
      }

      expect(focusedIndices, <int>[0, 1]);
    },
  );

  testWidgets(
    'disabled skipVisibleItems still focuses already visible later items',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final List<int> focusedIndices = <int>[];

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: const Stack(
            children: <Widget>[
              Positioned(
                left: 80,
                top: 80,
                child: SpotlightGuideTarget(
                  id: 'force-visible-first',
                  child: SizedBox(
                    width: 80,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
              Positioned(
                left: 220,
                top: 160,
                child: SpotlightGuideTarget(
                  id: 'force-visible-second',
                  child: SizedBox(
                    width: 80,
                    height: 40,
                    child: ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                interval: kAutoScrollTestInterval,
                skipVisibleItems: false,
                onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                  recordAutoScrollIndex(focusedIndices, details);
                },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'force-visible-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('force-visible-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'force-visible-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('force-visible-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);
      expect(focusedIndices, <int>[0]);
      expect(
        find.byKey(const ValueKey<String>('force-visible-first')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('force-visible-second')),
        findsNothing,
      );

      await pumpAutoScrollInterval(tester);

      expect(focusedIndices, <int>[0, 1]);
      expect(
        find.byKey(const ValueKey<String>('force-visible-first')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('force-visible-second')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'horizontal auto scroll reveals the second item after one interval',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: multiItemScrollableTargets(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            firstId: 'h-first',
            secondId: 'h-second',
          ),
          steps: <SpotlightGuideStep>[
            twoItemAutoScrollStep(
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'h-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('h-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'h-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('h-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);
      expect(find.byKey(const ValueKey<String>('h-first')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('h-second')), findsNothing);
      expect(scrollController.offset, 0);

      await pumpAutoScrollInterval(tester);

      expect(scrollController.offset, greaterThan(0));
      expect(find.byKey(const ValueKey<String>('h-first')), findsNothing);
      expect(find.byKey(const ValueKey<String>('h-second')), findsOneWidget);
    },
  );

  testWidgets(
    'partially visible later item waits for auto-scroll focus before rendering',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final List<int> focusedIndices = <int>[];
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: const SizedBox(
              width: 850,
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 40,
                    child: SpotlightGuideTarget(
                      id: 'peek-first',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 750,
                    top: 40,
                    child: SpotlightGuideTarget(
                      id: 'peek-second',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                interval: kAutoScrollTestInterval,
                onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                  recordAutoScrollIndex(focusedIndices, details);
                },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'peek-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('peek-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'peek-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('peek-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);

      expect(scrollController.offset, 0);
      expect(focusedIndices, <int>[0]);
      expect(find.byKey(const ValueKey<String>('peek-first')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('peek-second')), findsNothing);

      await pumpAutoScrollInterval(tester);

      expect(scrollController.offset, greaterThan(0));
      expect(focusedIndices, <int>[0, 1]);
      expect(find.byKey(const ValueKey<String>('peek-first')), findsNothing);
      expect(find.byKey(const ValueKey<String>('peek-second')), findsOneWidget);
    },
  );

  testWidgets(
    'unmounted later target with onReveal still starts auto scroll at index 0',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final List<int> focusedIndices = <int>[];
      int lazyRevealCount = 0;
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: Column(
            children: <Widget>[
              const SpotlightGuideTarget(
                id: 'lazy-auto-first',
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemExtent: 50,
                  itemCount: 80,
                  itemBuilder: (BuildContext context, int index) {
                    final Widget row = SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ColoredBox(
                        color: index.isEven ? Colors.blue : Colors.green,
                      ),
                    );
                    if (index == 60) {
                      return SpotlightGuideTarget(
                        id: 'lazy-auto-second',
                        child: row,
                      );
                    }
                    return row;
                  },
                ),
              ),
            ],
          ),
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                interval: kAutoScrollTestInterval,
                onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                  recordAutoScrollIndex(focusedIndices, details);
                },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'lazy-auto-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('lazy-auto-first'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'lazy-auto-second',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  onReveal: (_) {
                    lazyRevealCount++;
                    scrollController.jumpTo(60 * 50);
                  },
                  hintBuilder: hint('lazy-auto-second'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);

      expect(focusedIndices, <int>[0]);
      expect(
        find.byKey(const ValueKey<String>('lazy-auto-first')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('lazy-auto-second')),
        findsNothing,
      );
      expect(lazyRevealCount, 0);

      await pumpAutoScrollInterval(tester);

      expect(focusedIndices, <int>[0, 1]);
      expect(lazyRevealCount, 1);
      expect(scrollController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey<String>('lazy-auto-second')),
        findsOneWidget,
      );
    },
  );

  testWidgets('reset during auto scroll restarts focused indices from 0', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<int> focusedIndices = <int>[];
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'restart-first',
          secondId: 'restart-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              interval: kAutoScrollTestInterval,
              onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                recordAutoScrollIndex(focusedIndices, details);
              },
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'restart-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('restart-first'),
              ),
              SpotlightGuideStepItem(
                targetId: 'restart-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('restart-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuideFrames(tester);
    await pumpAutoScrollInterval(tester);
    expect(focusedIndices, <int>[0, 1]);

    focusedIndices.clear();
    controller.reset();
    await pumpGuideFrames(tester);
    expect(focusedIndices, <int>[0]);
    expect(find.byKey(const ValueKey<String>('restart-first')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('restart-second')), findsNothing);

    controller.finish();
    await pumpGuide(tester);
  });

  testWidgets('onItemChanged exposes item index, target ids, and item key', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    final List<SpotlightGuideAutoScrollDetails> details =
        <SpotlightGuideAutoScrollDetails>[];
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        child: multiItemScrollableTargets(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          firstId: 'ctx-first',
          secondId: 'ctx-second',
        ),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            revealOptions: const SpotlightGuideRevealOptions(
              duration: Duration.zero,
            ),
            autoScrollOptions: SpotlightGuideAutoScrollOptions(
              interval: kAutoScrollTestInterval,
              onItemChanged: details.add,
            ),
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                key: 'intro',
                targetId: 'ctx-first',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('ctx-first'),
              ),
              SpotlightGuideStepItem(
                key: 'detail',
                targetId: 'ctx-second',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('ctx-second'),
              ),
            ],
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuideFrames(tester);
    await pumpAutoScrollInterval(tester);

    expect(details.length, 2);
    expect(details[0].itemIndex, 0);
    expect(details[0].itemTotal, 2);
    expect(details[0].key, 'intro');
    expect(details[0].highlightTargetIds, <Object>['ctx-first']);
    expect(details[0].primaryTargetId, 'ctx-first');
    expect(details[1].itemIndex, 1);
    expect(details[1].key, 'detail');
    expect(details[1].highlightTargetIds, <Object>['ctx-second']);
  });

  testWidgets(
    'auto scroll can focus an item that highlights multiple target ids at once',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final ScrollController scrollController = ScrollController();
      final Map<String, SpotlightGuideStepContext> guideContexts =
          <String, SpotlightGuideStepContext>{};
      SpotlightGuideAutoScrollDetails? secondFocus;
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const SizedBox(
              height: 1400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 40,
                    top: 40,
                    child: SpotlightGuideTarget(
                      id: 'pair-first',
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    top: 1150,
                    child: SpotlightGuideTarget(
                      id: 'pair-a',
                      child: SizedBox(
                        width: 80,
                        height: 50,
                        child: ColoredBox(color: Colors.green),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 140,
                    top: 1150,
                    child: SpotlightGuideTarget(
                      id: 'pair-b',
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
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration.zero,
              ),
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                interval: kAutoScrollTestInterval,
                onItemChanged: (SpotlightGuideAutoScrollDetails details) {
                  if (details.itemIndex == 1) {
                    secondFocus = details;
                  }
                },
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'pair-first',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('pair-first'),
                ),
                SpotlightGuideStepItem(
                  key: 'pair-group',
                  targetIds: const <Object>['pair-a', 'pair-b'],
                  anchorTargetId: 'pair-a',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('pair-group', guideContexts),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuideFrames(tester);
      expect(find.byKey(const ValueKey<String>('pair-first')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pair-group')), findsNothing);

      await pumpAutoScrollInterval(tester);
      await pumpGuide(tester);

      expect(secondFocus?.itemIndex, 1);
      expect(secondFocus?.key, 'pair-group');
      expect(secondFocus?.highlightTargetIds, const <Object>[
        'pair-a',
        'pair-b',
      ]);
      expect(secondFocus?.primaryTargetId, 'pair-a');
      expect(find.byKey(const ValueKey<String>('pair-group')), findsOneWidget);
      expect(guideContexts['pair-group']!.targetRects.length, 2);
    },
  );

  testWidgets(
    'all items already visible shows every hint without auto-scroll callbacks',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      final List<SpotlightGuideAutoScrollDetails> details =
          <SpotlightGuideAutoScrollDetails>[];

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep(
              autoScrollOptions: SpotlightGuideAutoScrollOptions(
                onItemChanged: details.add,
              ),
              items: <SpotlightGuideStepItem>[
                SpotlightGuideStepItem(
                  targetId: 'a',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('visible-a'),
                ),
                SpotlightGuideStepItem(
                  targetId: 'b',
                  targetDecoration: const SpotlightGuideTargetDecoration(
                    padding: EdgeInsets.zero,
                  ),
                  hintBuilder: hint('visible-b'),
                ),
              ],
            ),
          ],
        ),
      );

      controller.reset();
      await pumpGuide(tester);
      await pumpAutoScrollInterval(tester);

      expect(details, isEmpty);
      expect(find.byKey(const ValueKey<String>('visible-a')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('visible-b')), findsOneWidget);
    },
  );
}
