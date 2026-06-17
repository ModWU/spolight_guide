/// Flutter widgets for building spotlight-style product guides.
///
/// Wrap a page or feature area with [SpotlightGuidePortal], register
/// highlighted widgets with [SpotlightGuideTarget], and describe each guide
/// moment with [SpotlightGuideStep] and [SpotlightGuideStepItem]. The package
/// handles target lookup, reveal scrolling, auto placement, safe-area
/// adjustment, bubble anchors, optional pointers, and target-hole decoration.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

part 'src/api/callbacks.dart';
part 'src/api/barrier.dart';
part 'src/api/reveal.dart';
part 'src/api/placement.dart';
part 'src/api/steps.dart';
part 'src/api/portal.dart';
part 'src/api/target.dart';
part 'src/api/target_decoration.dart';
part 'src/api/controller.dart';
part 'src/runtime/geometry.dart';
part 'src/runtime/step_source.dart';
part 'src/runtime/target_resolver.dart';
part 'src/runtime/missing_target_policy.dart';
part 'src/runtime/reveal_scroll_strategy.dart';
part 'src/hints/bubble.dart';
part 'src/hints/pointer.dart';
part 'src/hints/bubble_hint.dart';
part 'src/hints/bubble_anchor.dart';
part 'src/hints/bubble_decoration.dart';
part 'src/hints/tap_pointer.dart';
part 'src/hints/paint_gate.dart';
part 'src/hints/text_hint.dart';
part 'src/layout/overlay_layout.dart';
part 'src/layout/hint_layout.dart';
part 'src/painting/barrier_painter.dart';
part 'src/painting/bubble_painter.dart';
part 'src/utils/collections.dart';
