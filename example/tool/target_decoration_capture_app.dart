import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';
import 'package:spotlight_guide_example/src/pages/target_decoration_page.dart';

void main() {
  runApp(const TargetDecorationCaptureApp());
}

class TargetDecorationCaptureApp extends StatelessWidget {
  const TargetDecorationCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF316B67)),
        useMaterial3: true,
      ),
      home: const _AutoSteppingTargetDecorationPage(),
    );
  }
}

class _AutoSteppingTargetDecorationPage extends StatefulWidget {
  const _AutoSteppingTargetDecorationPage();

  @override
  State<_AutoSteppingTargetDecorationPage> createState() =>
      _AutoSteppingTargetDecorationPageState();
}

class _AutoSteppingTargetDecorationPageState
    extends State<_AutoSteppingTargetDecorationPage> {
  final SpotlightGuidePortalController _controller =
      SpotlightGuidePortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _controller.goTo(_captureStep);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TargetDecorationPage(controller: _controller);
  }
}

const int _captureStep = int.fromEnvironment('SPOTLIGHT_CAPTURE_STEP');
