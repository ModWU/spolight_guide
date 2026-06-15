import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotlight_guide_example/src/spotlight_guide_example_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Directory('../doc/images/readme/frames').createSync(recursive: true);
    return _loadRobotoFonts();
  });

  testWidgets('capture basic guide frame', (WidgetTester tester) async {
    await _pumpScenario(tester, 'Basic', waitFor: find.text('Basic target'));
    await _capture(tester, 'basic_01.png');
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _capture(tester, 'basic_02.png');
    await _hideGuide(tester);
  });

  testWidgets('capture same-step hints frame', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Same-step hints',
      waitFor: find.text('Weight'),
    );
    await _capture(tester, 'same_step_hints_01.png');
    await _hideGuide(tester);
  });

  testWidgets('capture same-step scroll frames', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Same-step scroll',
      waitFor: find.text('Already visible.'),
    );
    await _capture(tester, 'same_step_scroll_01.png');
    await _pumpFor(tester, const Duration(milliseconds: 900));
    for (int i = 2; i <= 15; i++) {
      await _capture(tester, _numberedFrame('same_step_scroll', i));
      await _pumpFor(tester, const Duration(milliseconds: 45));
    }
    await _pumpUntilFound(tester, find.text('Offscreen'));
    await _capture(tester, 'same_step_scroll_16.png');
    await _hideGuide(tester);
  });

  testWidgets('capture lazy target reveal frame', (WidgetTester tester) async {
    await _pumpScenario(tester, 'Lazy target');
    await _pumpUntilFound(
      tester,
      find.text('Lazy list target'),
      timeout: const Duration(seconds: 5),
    );
    await _capture(tester, 'lazy_target_01.png');
    await _hideGuide(tester);

    await tester.tap(find.byTooltip('Replay guide'));
    await tester.pump();
    await _capture(tester, 'lazy_target_scroll_01.png');
    for (int i = 2; i <= 25; i++) {
      await _pumpFor(tester, const Duration(milliseconds: 55));
      await _capture(tester, _numberedFrame('lazy_target_scroll', i));
    }
    await _pumpUntilFound(
      tester,
      find.text('Lazy list target'),
      timeout: const Duration(seconds: 5),
    );
    await _capture(tester, 'lazy_target_scroll_26.png');
    await _hideGuide(tester);
  });

  testWidgets('capture barrier dismiss frames', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Barrier dismiss',
      waitFor: find.text('Tap outside anytime'),
    );
    await _capture(tester, 'barrier_dismiss_01.png');
    await tester.tapAt(const Offset(32, 760));
    await tester.pumpAndSettle();
    await _capture(tester, 'barrier_dismiss_02.png');

    await tester.tap(find.text('Final'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Complete-only start'));
    await _capture(tester, 'barrier_dismiss_03.png');
    await tester.tapAt(const Offset(32, 760));
    await tester.pumpAndSettle();
    await _capture(tester, 'barrier_dismiss_04.png');
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Complete-only final step'));
    await _capture(tester, 'barrier_dismiss_05.png');
    await tester.tapAt(const Offset(32, 760));
    await tester.pumpAndSettle();
    await _capture(tester, 'barrier_dismiss_06.png');
  });

  testWidgets('capture side anchor frames', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Side anchors',
      waitFor: find.text('Horizontal auto: left arrow'),
    );
    await _capture(tester, 'side_anchor_left_01.png');
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Horizontal auto: right arrow'));
    await _capture(tester, 'side_anchor_right_01.png');
    await _hideGuide(tester);
  });

  testWidgets('capture group and custom anchor frames', (
    WidgetTester tester,
  ) async {
    await _pumpScenario(
      tester,
      'Large group',
      waitFor: find.text('Repeated id group'),
    );
    await _capture(tester, 'anchor_group_01.png');
    await _hideGuide(tester);

    await _pumpFreshApp(tester);
    await _tapScenario(tester, 'Custom anchor');
    await _pumpUntilFound(tester, find.textContaining('Pick an anchor style'));
    await _capture(tester, 'anchor_group_02.png');
    await tester.tap(find.text('Sweep'));
    await tester.pumpAndSettle();
    await _capture(tester, 'anchor_group_03.png');
    await tester.tap(find.text('Arrow'));
    await tester.pumpAndSettle();
    await _capture(tester, 'anchor_group_04.png');
    await tester.drag(
      find.byKey(const ValueKey<String>('custom-anchor-choice-scroll')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await _capture(tester, 'anchor_group_05.png');
    await _hideGuide(tester);
  });

  testWidgets('capture controller API frame', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Controller API',
      waitFor: find.text('Portal steps'),
    );
    await _capture(tester, 'controller_01.png');
    await _hideGuide(tester);
  });

  testWidgets('capture target decoration frames', (WidgetTester tester) async {
    await _pumpScenario(
      tester,
      'Target decoration',
      waitFor: find.text('Layered target halo'),
    );
    await _capture(tester, 'target_decoration_01.png');

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.textContaining('diffused halo'));
    await _capture(tester, 'target_decoration_02.png');

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Shape-aware oval glow'));
    await _capture(tester, 'target_decoration_03.png');

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Dashed outline layer'));
    await _capture(tester, 'target_decoration_04.png');
    await _hideGuide(tester);
  });
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const Duration frame = Duration(milliseconds: 100);
  Duration elapsed = Duration.zero;
  while (elapsed < duration) {
    final Duration remaining = duration - elapsed;
    final Duration delta = remaining < frame ? remaining : frame;
    await tester.pump(delta);
    elapsed += delta;
  }
  await tester.pump();
}

Future<void> _pumpScenario(
  WidgetTester tester,
  String label, {
  Finder? waitFor,
}) async {
  await _setPhoneViewport(tester);
  await _pumpFreshApp(tester);
  await _tapScenario(tester, label);
  if (waitFor != null) {
    await _pumpUntilFound(tester, waitFor);
  }
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _loadRobotoFonts() async {
  final Directory flutterRoot = _findFlutterRoot();
  final Directory fontDir = Directory(
    '${flutterRoot.path}/bin/cache/artifacts/material_fonts',
  );
  final FontLoader loader = FontLoader('Roboto')
    ..addFont(_loadFont(fontDir, 'Roboto-Regular.ttf'))
    ..addFont(_loadFont(fontDir, 'Roboto-Medium.ttf'))
    ..addFont(_loadFont(fontDir, 'Roboto-Bold.ttf'));
  await loader.load();
}

Directory _findFlutterRoot() {
  final String? fromEnvironment = Platform.environment['FLUTTER_ROOT'];
  if (fromEnvironment != null && Directory(fromEnvironment).existsSync()) {
    return Directory(fromEnvironment);
  }

  Directory directory = File(Platform.resolvedExecutable).parent;
  for (int i = 0; i < 4; i++) {
    directory = directory.parent;
  }
  return directory;
}

Future<ByteData> _loadFont(Directory fontDir, String fileName) async {
  final Uint8List bytes = await File('${fontDir.path}/$fileName').readAsBytes();
  return ByteData.view(bytes.buffer);
}

Future<void> _pumpFreshApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(const SpotlightGuideExampleApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await _skipHomeIntro(tester);
}

Future<void> _tapScenario(WidgetTester tester, String label) async {
  final Finder scenarioButton = find.widgetWithText(OutlinedButton, label);
  await tester.scrollUntilVisible(
    scenarioButton,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(scenarioButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  const Duration frame = Duration(milliseconds: 100);
  Duration elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(frame);
    elapsed += frame;
  }
  expect(finder, findsWidgets);
}

Future<void> _hideGuide(WidgetTester tester) async {
  final bool finishedWithButton = await _finishCurrentGuide(tester);
  if (!finishedWithButton) {
    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();
  }
}

Future<void> _skipHomeIntro(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 820));
  await tester.pumpAndSettle();
}

Future<bool> _finishCurrentGuide(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pumpAndSettle();
    final Finder done = find.text('Done').hitTestable();
    if (done.evaluate().isNotEmpty) {
      await tester.tap(done);
      await tester.pumpAndSettle();
      return true;
    }

    final Finder next = find.text('Next').hitTestable();
    if (next.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      continue;
    }
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  return false;
}

Future<void> _capture(WidgetTester tester, String fileName) async {
  await tester.pump();
  await expectLater(
    find.byType(SpotlightGuideExampleApp),
    matchesGoldenFile('../../doc/images/readme/frames/$fileName'),
  );
}

String _numberedFrame(String prefix, int index) {
  return '${prefix}_${index.toString().padLeft(2, '0')}.png';
}
