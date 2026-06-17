import 'dart:async';

import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spotlight_guide_test_helpers.dart';

/// Controller lifecycle and async preparation tests.
///
/// Run this file when changing [SpotlightGuidePortalController],
/// [SpotlightGuidePortal.onStepWillShow], step list updates, item updates,
/// finish/reset/next behavior, or controller replacement during rebuilds.
void main() {
  testWidgets('next advances steps and finishes on the last step', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('step-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('step-1'),
            ),
          ),
        ],
      ),
    );

    expect(find.byKey(const ValueKey<String>('step-0')), findsNothing);

    controller.reset();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('step-0')), findsOneWidget);

    controller.next();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('step-0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('step-1')), findsOneWidget);

    controller.next();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('step-1')), findsNothing);
    expect(finishCount, 1);
  });

  testWidgets('active guide survives step list shrink', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('shrink-0', contexts),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('shrink-1', contexts),
            ),
          ),
        ],
      ),
    );
    controller.reset();
    await pumpGuide(tester);
    controller.next();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('shrink-1')), findsOneWidget);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    contexts['shrink-0-updated'] = guide;
                    return Text(
                      '${guide.index + 1}/${guide.total} '
                      'first=${guide.isFirst} last=${guide.isLast}',
                      key: const ValueKey<String>('shrink-0-updated'),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(controller.index, 0);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
    expect(
      find.byKey(const ValueKey<String>('shrink-0-updated')),
      findsOneWidget,
    );
    expect(find.text('1/1 first=true last=true'), findsOneWidget);
    expect(contexts['shrink-0-updated']?.total, 1);
    expect(contexts['shrink-0-updated']?.isFirst, isTrue);
    expect(contexts['shrink-0-updated']?.isLast, isTrue);
  });

  testWidgets('active guide updates current step items', (tester) async {
    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('items-old'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('items-old')), findsOneWidget);

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep(
            items: <SpotlightGuideStepItem>[
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('items-new-a'),
              ),
              SpotlightGuideStepItem(
                targetId: 'b',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('items-new-b'),
              ),
            ],
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('items-old')), findsNothing);
    expect(find.byKey(const ValueKey<String>('items-new-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('items-new-b')), findsOneWidget);
  });

  testWidgets('async onStepWillShow delays showing the hint', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Completer<void> completer = Completer<void>();
    int? preparedIndex;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          preparedIndex = index;
          return completer.future;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('async-step'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await tester.pump();
    expect(preparedIndex, 0);
    expect(controller.isShowing, isTrue);
    expect(find.byKey(const ValueKey<String>('async-step')), findsNothing);

    completer.complete();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('async-step')), findsOneWidget);
  });

  testWidgets('preparation blocks child taps by default', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Completer<void> completer = Completer<void>();
    int childTapCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          return completer.future;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('blocked-preparation'),
            ),
          ),
        ],
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('preparation-child'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  childTapCount++;
                },
              ),
            ),
            const Positioned(
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
        ),
      ),
    );

    controller.reset();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('blocked-preparation')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('preparation-child')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(childTapCount, 0);

    completer.complete();
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('blocked-preparation')),
      findsOneWidget,
    );
  });

  testWidgets('preparation can allow child taps when configured', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Completer<void> completer = Completer<void>();
    int childTapCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        blockDuringPreparation: false,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          return completer.future;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('pass-through-preparation'),
            ),
          ),
        ],
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('pass-through-child'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  childTapCount++;
                },
              ),
            ),
            const Positioned(
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
        ),
      ),
    );

    controller.reset();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('pass-through-preparation')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('pass-through-child')));
    await tester.pump();
    expect(childTapCount, 1);

    completer.complete();
    await pumpGuide(tester);
    expect(
      find.byKey(const ValueKey<String>('pass-through-preparation')),
      findsOneWidget,
    );
  });

  testWidgets('preparation can allow child taps while reveal scrolling', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    int childTapCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        blockDuringPreparation: false,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'scroll-reveal-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              revealOptions: const SpotlightGuideRevealOptions(
                duration: Duration(milliseconds: 300),
                alignment: 0.5,
              ),
              hintBuilder: hint('scroll-reveal-pass-through'),
            ),
          ),
        ],
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(
                height: 1400,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 40,
                      top: 1100,
                      child: SpotlightGuideTarget(
                        id: 'scroll-reveal-target',
                        child: SizedBox(
                          width: 100,
                          height: 40,
                          child: ColoredBox(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('scroll-reveal-child'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  childTapCount++;
                },
              ),
            ),
          ],
        ),
      ),
    );

    controller.reset();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey<String>('scroll-reveal-pass-through')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('scroll-reveal-child')));
    await tester.pump();
    expect(childTapCount, 1);

    await pumpGuide(tester);
    expect(scrollController.offset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('scroll-reveal-pass-through')),
      findsOneWidget,
    );
  });

  testWidgets('finish cancels a pending async step preparation', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Completer<void> completer = Completer<void>();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          return completer.future;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('cancelled-step'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await tester.pump();
    controller.finish();
    completer.complete();
    await pumpGuide(tester);

    expect(controller.isShowing, isFalse);
    expect(find.byKey(const ValueKey<String>('cancelled-step')), findsNothing);
  });

  testWidgets('onStepWillShow errors are reported and do not show hints', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onStepWillShow: (int index, SpotlightGuideStep step) {
          throw StateError('prepare failed');
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('error-step'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await tester.pump();
    await tester.pump();
    FlutterError.onError = previousOnError;

    expect(errors, isNotEmpty);
    expect(controller.isShowing, isFalse);
    expect(find.byKey(const ValueKey<String>('error-step')), findsNothing);
  });

  testWidgets('replacing controller preserves active guide state', (
    tester,
  ) async {
    final SpotlightGuidePortalController firstController =
        SpotlightGuidePortalController();
    final SpotlightGuidePortalController secondController =
        SpotlightGuidePortalController();
    int finishCount = 0;

    Widget buildApp(SpotlightGuidePortalController controller) {
      return guideApp(
        controller: controller,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('replace-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('replace-1'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp(firstController));
    firstController.reset();
    await pumpGuide(tester);
    firstController.next();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('replace-1')), findsOneWidget);

    await tester.pumpWidget(buildApp(secondController));
    await pumpGuide(tester);
    expect(secondController.index, 1);
    expect(secondController.isShowing, isTrue);
    expect(find.byKey(const ValueKey<String>('replace-1')), findsOneWidget);

    secondController.next();
    await pumpGuide(tester);
    expect(secondController.isShowing, isFalse);
    expect(finishCount, 1);
  });

  testWidgets('guide auto-starts when no controller is supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('auto-start'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('auto-start')), findsOneWidget);
  });

  testWidgets(
    'auto-start waits for route push transition before showing hints',
    (tester) async {
      int routeTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                key: const ValueKey<String>('open-route'),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) => _AutoStartGuideRoutePage(
                            onTap: () {
                              routeTapCount++;
                            },
                          ),
                      transitionsBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                            Widget child,
                          ) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('open-route')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byKey(const ValueKey<String>('route-hint')), findsNothing);
      await tester.tapAt(const Offset(700, 300));
      await tester.pump();
      expect(routeTapCount, 1);

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('route-hint')), findsOneWidget);
      await tester.tapAt(const Offset(700, 300));
      await tester.pump();
      expect(routeTapCount, 1);
    },
  );

  testWidgets(
    'controller show waits for route push transition before showing hints',
    (tester) async {
      int routeTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                key: const ValueKey<String>('open-controller-route'),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                          ) => _ControllerGuideRoutePage(
                            onTap: () {
                              routeTapCount++;
                            },
                          ),
                      transitionsBuilder:
                          (
                            BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                            Widget child,
                          ) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('open-controller-route')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        find.byKey(const ValueKey<String>('controller-route-hint')),
        findsNothing,
      );
      await tester.tapAt(const Offset(700, 300));
      await tester.pump();
      expect(routeTapCount, 1);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('controller-route-hint')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(700, 300));
      await tester.pump();
      expect(routeTapCount, 1);
    },
  );

  testWidgets('unmount during auto-start preparation reports no errors', (
    tester,
  ) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('unmount-auto-start'),
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(
      find.byKey(const ValueKey<String>('unmount-auto-start')),
      findsNothing,
    );
  });

  testWidgets('guide.finish from a hint button closes and notifies once', (
    tester,
  ) async {
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return TextButton(
                      key: const ValueKey<String>('finish-button'),
                      onPressed: guide.finish,
                      child: const Text('done'),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('finish-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('finish-button')));
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('finish-button')), findsNothing);
    expect(finishCount, 1);
  });

  testWidgets('guide.hide from a hint button closes without onFinish', (
    tester,
  ) async {
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder:
                  (BuildContext context, SpotlightGuideStepContext guide) {
                    return TextButton(
                      key: const ValueKey<String>('hide-button'),
                      onPressed: guide.hide,
                      child: const Text('hide'),
                    );
                  },
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('hide-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('hide-button')));
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('hide-button')), findsNothing);
    expect(finishCount, 0);
  });

  testWidgets('commands issued before attach are replayed after attach', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    // Reset before the portal exists. The command must be queued and replayed.
    controller.reset();
    expect(controller.isShowing, isTrue);

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('pending-command'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(
      find.byKey(const ValueKey<String>('pending-command')),
      findsOneWidget,
    );
  });

  testWidgets(
    'runtime showSteps issued before attach is replayed after attach',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();

      controller.showSteps(<SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'a',
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            hintBuilder: hint('pending-show'),
          ),
        ),
      ]);
      expect(controller.isShowing, isTrue);

      await tester.pumpWidget(
        guideApp(controller: controller, steps: const <SpotlightGuideStep>[]),
      );
      await pumpGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('pending-show')),
        findsOneWidget,
      );
    },
  );

  testWidgets('finish on an idle guide does not notify onFinish', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('idle-finish'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('idle-finish')), findsNothing);

    controller.finish();
    await pumpGuide(tester);

    expect(finishCount, 0);
    expect(controller.isShowing, isFalse);
  });

  testWidgets('disabling the portal hides the guide without onFinish', (
    tester,
  ) async {
    int finishCount = 0;

    Widget buildApp({required bool enabled}) {
      return guideApp(
        enabled: enabled,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('disable-hide'),
            ),
          ),
        ],
      );
    }

    await tester.pumpWidget(buildApp(enabled: true));
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('disable-hide')), findsOneWidget);

    await tester.pumpWidget(buildApp(enabled: false));
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('disable-hide')), findsNothing);
    expect(finishCount, 0);
  });

  testWidgets('emptying the steps while active finishes the guide', (
    tester,
  ) async {
    int finishCount = 0;
    void onFinish() {
      finishCount++;
    }

    await tester.pumpWidget(
      guideApp(
        onFinish: onFinish,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('empty-steps'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('empty-steps')), findsOneWidget);

    await tester.pumpWidget(
      guideApp(onFinish: onFinish, steps: const <SpotlightGuideStep>[]),
    );
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('empty-steps')), findsNothing);
    expect(finishCount, 1);
  });

  testWidgets('barrier tap runs onBarrierTap and can advance the guide', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int barrierTaps = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onBarrierTap: (SpotlightGuidePortalController c) {
          barrierTaps++;
          c.next();
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('barrier-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('barrier-1'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('barrier-0')), findsOneWidget);

    // Tap a far corner of the dim barrier, away from the hint bubble.
    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(barrierTaps, 1);
    expect(find.byKey(const ValueKey<String>('barrier-0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('barrier-1')), findsOneWidget);
  });

  testWidgets('barrier tap is absorbed by default', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onFinish: () => finishCount++,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('default-barrier'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(finishCount, 0);
    expect(controller.isShowing, isTrue);
    expect(
      find.byKey(const ValueKey<String>('default-barrier')),
      findsOneWidget,
    );
  });

  testWidgets('barrier dismiss onComplete waits for the last step', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        barrierDismissBehavior: SpotlightGuideDismissBehavior.onComplete,
        onFinish: () => finishCount++,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('complete-first'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('complete-last'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(finishCount, 0);
    expect(
      find.byKey(const ValueKey<String>('complete-first')),
      findsOneWidget,
    );

    controller.next();
    await pumpGuide(tester);
    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(finishCount, 1);
    expect(controller.isShowing, isFalse);
    expect(find.byKey(const ValueKey<String>('complete-last')), findsNothing);
  });

  testWidgets('barrier dismiss anytime can finish mid-flow', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        barrierDismissBehavior: SpotlightGuideDismissBehavior.anytime,
        onFinish: () => finishCount++,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('anytime-first'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('anytime-last'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(finishCount, 1);
    expect(controller.isShowing, isFalse);
    expect(find.byKey(const ValueKey<String>('anytime-first')), findsNothing);
  });

  testWidgets('onBarrierTap can advance using the internal controller', (
    tester,
  ) async {
    // No external controller is supplied: the callback must still be able to
    // drive the guide through the controller it receives.
    await tester.pumpWidget(
      guideApp(
        onBarrierTap: (SpotlightGuidePortalController c) => c.next(),
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('internal-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('internal-1'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('internal-0')), findsOneWidget);

    await tester.tapAt(const Offset(10, 590));
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('internal-0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('internal-1')), findsOneWidget);
  });

  testWidgets('previous steps back and clamps on the first step', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        onFinish: () {
          finishCount++;
        },
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('prev-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('prev-1'),
            ),
          ),
        ],
      ),
    );

    controller.reset();
    await pumpGuide(tester);
    controller.next();
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('prev-1')), findsOneWidget);

    controller.previous();
    await pumpGuide(tester);
    expect(controller.index, 0);
    expect(find.byKey(const ValueKey<String>('prev-0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('prev-1')), findsNothing);

    // previous on the first step is a no-op and never finishes the guide.
    controller.previous();
    await pumpGuide(tester);
    expect(controller.index, 0);
    expect(controller.isShowing, isTrue);
    expect(finishCount, 0);
  });

  testWidgets('goTo jumps to a step and clamps out-of-range indices', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('goto-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('goto-1'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('goto-2'),
            ),
          ),
        ],
      ),
    );

    // goTo shows the guide directly at the requested step.
    controller.goTo(2);
    await pumpGuide(tester);
    expect(controller.index, 2);
    expect(find.byKey(const ValueKey<String>('goto-2')), findsOneWidget);

    controller.goTo(1);
    await pumpGuide(tester);
    expect(controller.index, 1);
    expect(find.byKey(const ValueKey<String>('goto-1')), findsOneWidget);

    // Out-of-range indices are clamped to the valid range.
    controller.goTo(99);
    await pumpGuide(tester);
    expect(controller.index, 2);
    expect(find.byKey(const ValueKey<String>('goto-2')), findsOneWidget);

    controller.goTo(-5);
    await pumpGuide(tester);
    expect(controller.index, 0);
    expect(find.byKey(const ValueKey<String>('goto-0')), findsOneWidget);
  });

  testWidgets('guide auto-starts when async steps arrive later', (
    tester,
  ) async {
    await tester.pumpWidget(guideApp(steps: const <SpotlightGuideStep>[]));
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('async-auto')), findsNothing);

    await tester.pumpWidget(
      guideApp(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('async-auto'),
            ),
          ),
        ],
      ),
    );
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('async-auto')), findsOneWidget);
  });

  testWidgets('external controller can still auto-start after data loads', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    Widget buildApp(List<SpotlightGuideStep> steps) {
      return guideApp(controller: controller, autoStart: true, steps: steps);
    }

    await tester.pumpWidget(buildApp(const <SpotlightGuideStep>[]));
    await pumpGuide(tester);
    expect(controller.isShowing, isFalse);

    await tester.pumpWidget(
      buildApp(<SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'a',
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            hintBuilder: hint('controller-auto'),
          ),
        ),
      ]),
    );
    await pumpGuide(tester);

    expect(controller.isShowing, isTrue);
    expect(
      find.byKey(const ValueKey<String>('controller-auto')),
      findsOneWidget,
    );
  });

  testWidgets(
    'controller.showSteps displays runtime steps with auto-start disabled',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      int finishCount = 0;

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          onFinish: () {
            finishCount++;
          },
          steps: const <SpotlightGuideStep>[],
        ),
      );
      await pumpGuide(tester);
      expect(controller.isShowing, isFalse);

      controller.showSteps(<SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'a',
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            hintBuilder: hint('runtime-0'),
          ),
        ),
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'b',
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            hintBuilder: hint('runtime-1'),
          ),
        ),
      ]);
      await pumpGuide(tester);
      expect(find.byKey(const ValueKey<String>('runtime-0')), findsOneWidget);

      controller.next();
      await pumpGuide(tester);
      expect(find.byKey(const ValueKey<String>('runtime-0')), findsNothing);
      expect(find.byKey(const ValueKey<String>('runtime-1')), findsOneWidget);

      controller.next();
      await pumpGuide(tester);
      expect(controller.isShowing, isFalse);
      expect(finishCount, 1);
    },
  );

  testWidgets('controller.showSteps can replace runtime steps with one step', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    final Map<String, SpotlightGuideStepContext> contexts =
        <String, SpotlightGuideStepContext>{};

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: const <SpotlightGuideStep>[],
      ),
    );

    controller.showSteps(<SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'a',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: hint('runtime-two-0'),
        ),
      ),
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'b',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: hint('runtime-two-1'),
        ),
      ),
    ], index: 1);
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('runtime-two-1')), findsOneWidget);

    controller.showSteps(<SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'a',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
            contexts['runtime-one'] = guide;
            return Text(
              '${guide.index + 1}/${guide.total} '
              'first=${guide.isFirst} last=${guide.isLast}',
              key: const ValueKey<String>('runtime-one'),
            );
          },
        ),
      ),
    ]);
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('runtime-two-1')), findsNothing);
    expect(find.byKey(const ValueKey<String>('runtime-one')), findsOneWidget);
    expect(find.text('1/1 first=true last=true'), findsOneWidget);
    expect(controller.index, 0);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
    expect(contexts['runtime-one']?.total, 1);
    expect(contexts['runtime-one']?.isFirst, isTrue);
    expect(contexts['runtime-one']?.isLast, isTrue);
  });

  testWidgets('controller.showSteps empty steps hides without onFinish', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        onFinish: () {
          finishCount++;
        },
        steps: const <SpotlightGuideStep>[],
      ),
    );

    controller.showSteps(<SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'a',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: hint('runtime-empty'),
        ),
      ),
    ]);
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('runtime-empty')), findsOneWidget);

    controller.showSteps(const <SpotlightGuideStep>[]);
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('runtime-empty')), findsNothing);
    expect(controller.isShowing, isFalse);
    expect(finishCount, 0);
  });

  testWidgets('controller.hide closes without onFinish', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();
    int finishCount = 0;

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        onFinish: () {
          finishCount++;
        },
      ),
    );

    controller.showSteps(<SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'a',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: hint('hide-runtime'),
        ),
      ),
    ]);
    await pumpGuide(tester);
    expect(find.byKey(const ValueKey<String>('hide-runtime')), findsOneWidget);

    controller.hide();
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('hide-runtime')), findsNothing);
    expect(controller.isShowing, isFalse);
    expect(finishCount, 0);
  });

  testWidgets('portal steps can be omitted for runtime-only guides', (
    tester,
  ) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpotlightGuidePortal(
            controller: controller,
            autoStart: false,
            child: Stack(
              children: const <Widget>[
                Positioned(
                  left: 40,
                  top: 40,
                  child: SpotlightGuideTarget(
                    id: 'a',
                    child: SizedBox(width: 80, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    controller.showSteps(<SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'a',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: hint('runtime-only'),
        ),
      ),
    ]);
    await pumpGuide(tester);

    expect(find.byKey(const ValueKey<String>('runtime-only')), findsOneWidget);
    expect(controller.total, 1);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isTrue);
  });

  testWidgets('controller.showPortal uses portal steps', (tester) async {
    final SpotlightGuidePortalController controller =
        SpotlightGuidePortalController();

    await tester.pumpWidget(
      guideApp(
        controller: controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'a',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('portal-show-0'),
            ),
          ),
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'b',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('portal-show-1'),
            ),
          ),
        ],
      ),
    );

    controller.showPortal();
    await pumpGuide(tester);
    expect(controller.total, 2);
    expect(controller.isFirst, isTrue);
    expect(controller.isLast, isFalse);
    expect(find.byKey(const ValueKey<String>('portal-show-0')), findsOneWidget);

    controller.next();
    await pumpGuide(tester);
    expect(controller.isFirst, isFalse);
    expect(controller.isLast, isTrue);
    expect(find.byKey(const ValueKey<String>('portal-show-1')), findsOneWidget);
  });

  testWidgets(
    'controller.showPortal does not restart when parent rebuilds portal steps',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();
      int shownCount = 0;

      await tester.pumpWidget(
        _RebuildingPortalStepsApp(
          controller: controller,
          onShown: () {
            shownCount++;
          },
        ),
      );

      controller.showPortal();
      await pumpGuideFrames(tester, count: 20);

      expect(shownCount, 1);
      expect(find.byKey(const ValueKey<String>('rebuilt-1')), findsOneWidget);

      for (int i = 0; i < 20; i++) {
        await tester.pump();
      }

      expect(shownCount, 1);
      expect(find.byKey(const ValueKey<String>('rebuilt-1')), findsOneWidget);
    },
  );

  testWidgets(
    'controller.showPortal switches from runtime steps back to portal steps',
    (tester) async {
      final SpotlightGuidePortalController controller =
          SpotlightGuidePortalController();

      await tester.pumpWidget(
        guideApp(
          controller: controller,
          autoStart: false,
          steps: <SpotlightGuideStep>[
            SpotlightGuideStep.item(
              SpotlightGuideStepItem(
                targetId: 'a',
                targetDecoration: const SpotlightGuideTargetDecoration(
                  padding: EdgeInsets.zero,
                ),
                hintBuilder: hint('portal-after-runtime'),
              ),
            ),
          ],
        ),
      );

      controller.showSteps(<SpotlightGuideStep>[
        SpotlightGuideStep.item(
          SpotlightGuideStepItem(
            targetId: 'b',
            targetDecoration: const SpotlightGuideTargetDecoration(
              padding: EdgeInsets.zero,
            ),
            hintBuilder: hint('runtime-before-portal'),
          ),
        ),
      ]);
      await pumpGuide(tester);
      expect(
        find.byKey(const ValueKey<String>('runtime-before-portal')),
        findsOneWidget,
      );

      controller.showPortal();
      await pumpGuide(tester);

      expect(
        find.byKey(const ValueKey<String>('runtime-before-portal')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('portal-after-runtime')),
        findsOneWidget,
      );
      expect(controller.total, 1);
      expect(controller.isFirst, isTrue);
      expect(controller.isLast, isTrue);
    },
  );
}

class _AutoStartGuideRoutePage extends StatelessWidget {
  const _AutoStartGuideRoutePage({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpotlightGuidePortal(
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'route-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('route-hint'),
            ),
          ),
        ],
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('route-page-surface'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
              ),
            ),
            const Positioned(
              left: 220,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'route-target',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControllerGuideRoutePage extends StatefulWidget {
  const _ControllerGuideRoutePage({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ControllerGuideRoutePage> createState() =>
      _ControllerGuideRoutePageState();
}

class _ControllerGuideRoutePageState extends State<_ControllerGuideRoutePage> {
  final SpotlightGuidePortalController _controller =
      SpotlightGuidePortalController();

  @override
  void initState() {
    super.initState();
    _controller.showPortal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpotlightGuidePortal(
        controller: _controller,
        autoStart: false,
        steps: <SpotlightGuideStep>[
          SpotlightGuideStep.item(
            SpotlightGuideStepItem(
              targetId: 'controller-route-target',
              targetDecoration: const SpotlightGuideTargetDecoration(
                padding: EdgeInsets.zero,
              ),
              hintBuilder: hint('controller-route-hint'),
            ),
          ),
        ],
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('controller-route-page-surface'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
              ),
            ),
            const Positioned(
              left: 220,
              top: 120,
              child: SpotlightGuideTarget(
                id: 'controller-route-target',
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RebuildingPortalStepsApp extends StatefulWidget {
  const _RebuildingPortalStepsApp({
    required this.controller,
    required this.onShown,
  });

  final SpotlightGuidePortalController controller;
  final VoidCallback onShown;

  @override
  State<_RebuildingPortalStepsApp> createState() =>
      _RebuildingPortalStepsAppState();
}

class _RebuildingPortalStepsAppState extends State<_RebuildingPortalStepsApp> {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SpotlightGuidePortal(
          controller: widget.controller,
          autoStart: false,
          steps: _steps(),
          onStateChanged: (SpotlightGuideStateDetails state) {
            if (state.reason != SpotlightGuideStateChangeReason.shown) {
              return;
            }
            widget.onShown();
            setState(() {
              _rebuildCount++;
            });
          },
          child: Stack(
            children: const <Widget>[
              Positioned(
                left: 40,
                top: 40,
                child: SpotlightGuideTarget(
                  id: 'rebuilding-target',
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SpotlightGuideStep> _steps() {
    final int buildNumber = _rebuildCount;
    return <SpotlightGuideStep>[
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'rebuilding-target',
          targetDecoration: const SpotlightGuideTargetDecoration(
            padding: EdgeInsets.zero,
          ),
          hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
            return SizedBox(
              width: 80,
              height: 32,
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Text(
                    'rebuilt-$buildNumber',
                    key: ValueKey<String>('rebuilt-$buildNumber'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
