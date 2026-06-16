import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

const EdgeInsets kExampleGuideMargin = EdgeInsets.all(18);

Widget buildGuideHint({
  required SpotlightGuideStepContext guide,
  required String title,
  required String message,
}) {
  return SpotlightGuideTextHint(guide: guide, title: title, message: message);
}
