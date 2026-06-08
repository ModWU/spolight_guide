import 'package:flutter/material.dart';
import 'package:spotlight_guide/spotlight_guide.dart';

import '../guide_target_ids.dart';

const Size _anchorShapeSize = Size(56, 42);
const double _anchorVisualHalfExtent = 24;

List<SpotlightGuideStep> buildCustomAnchorScenario() {
  return <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: metricPriceId,
        placement: SpotlightGuidePlacement.bottom,
        targetAnchorPosition: const SpotlightGuideAnchorPosition.center(),
        decoration: _anchorDecoration(_CustomAnchorStyle.droplet),
        maxWidth: 360,
        hintBuilder: (context, guide) {
          return _CustomAnchorDemoHint(guide: guide);
        },
      ),
    ),
  ];
}

SpotlightGuideBubbleDecoration _anchorDecoration(_CustomAnchorStyle style) {
  return SpotlightGuideBubbleDecoration(
    borderRadius: 14,
    anchor: SpotlightGuidePathAnchor(shape: style.shape),
    contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}

enum _CustomAnchorStyle {
  droplet('Drop', Color(0xFF0891B2)),
  sweep('Sweep', Color(0xFFF59E0B)),
  arrow('Arrow', Color(0xFFEF4444)),
  none('None', Color(0xFF64748B));

  const _CustomAnchorStyle(this.label, this.color);

  final String label;
  final Color color;

  SpotlightGuidePathAnchorShape get shape {
    return switch (this) {
      _CustomAnchorStyle.droplet => const _DropletAnchorSpec(),
      _CustomAnchorStyle.sweep => const _SweepAnchorSpec(),
      _CustomAnchorStyle.arrow => const _ArrowAnchorSpec(),
      _CustomAnchorStyle.none => const _NoVisibleAnchorSpec(),
    };
  }
}

class _CustomAnchorDemoHint extends StatefulWidget {
  const _CustomAnchorDemoHint({required this.guide});

  final SpotlightGuideStepContext guide;

  @override
  State<_CustomAnchorDemoHint> createState() => _CustomAnchorDemoHintState();
}

class _CustomAnchorDemoHintState extends State<_CustomAnchorDemoHint> {
  _CustomAnchorStyle _style = _CustomAnchorStyle.droplet;

  @override
  Widget build(BuildContext context) {
    return SpotlightGuideBubbleHint(
      guide: widget.guide,
      decoration: _anchorDecoration(_style),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Step ${widget.guide.index + 1}/${widget.guide.total}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Custom anchor',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick an anchor style; the bubble redraws it while staying '
            'aimed at the target center.',
            style: TextStyle(fontSize: 15.5, height: 1.35),
          ),
          const SizedBox(height: 18),
          _AnchorChoiceStrip(
            selected: _style,
            onChanged: (value) {
              setState(() {
                _style = value;
              });
            },
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: widget.guide.finish,
              style: FilledButton.styleFrom(
                minimumSize: const Size(104, 50),
                shape: const StadiumBorder(),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnchorChoiceStrip extends StatelessWidget {
  const _AnchorChoiceStrip({required this.selected, required this.onChanged});

  final _CustomAnchorStyle selected;
  final ValueChanged<_CustomAnchorStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('custom-anchor-choice-scroll'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _CustomAnchorStyle.values.length; i++) ...[
            SizedBox(
              width: 96,
              child: _AnchorChoiceButton(
                style: _CustomAnchorStyle.values[i],
                selected: _CustomAnchorStyle.values[i] == selected,
                onPressed: () => onChanged(_CustomAnchorStyle.values[i]),
              ),
            ),
            if (i != _CustomAnchorStyle.values.length - 1)
              const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _AnchorChoiceButton extends StatelessWidget {
  const _AnchorChoiceButton({
    required this.style,
    required this.selected,
    required this.onPressed,
  });

  final _CustomAnchorStyle style;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = selected
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.82);
    final Color backgroundColor = selected
        ? const Color(0xFFD7F4EF)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.52);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedContainer(
          key: ValueKey<String>(
            'custom-anchor-${style.name}-${selected ? 'selected' : 'idle'}',
          ),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 54,
                height: 40,
                child: CustomPaint(
                  painter: _AnchorPreviewPainter(style, selected: selected),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  style.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnchorPreviewPainter extends CustomPainter {
  const _AnchorPreviewPainter(this.style, {required this.selected});

  final _CustomAnchorStyle style;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (selected) {
      _paintPreview(
        canvas,
        size,
        const Color(0x24000000),
        offset: const Offset(0, 1.5),
        blurSigma: 2,
      );
    }
    _paintPreview(canvas, size, style.color);
  }

  @override
  bool shouldRepaint(covariant _AnchorPreviewPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.selected != selected;
  }

  void _paintPreview(
    Canvas canvas,
    Size size,
    Color color, {
    Offset offset = Offset.zero,
    double blurSigma = 0,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    if (blurSigma > 0) {
      fill.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    }

    switch (style) {
      case _CustomAnchorStyle.droplet:
        canvas.drawPath(_dropletPreviewPath(size), fill);
        break;
      case _CustomAnchorStyle.sweep:
        _paintCurvedArrowPreview(canvas, size, fill, sweep: true);
        break;
      case _CustomAnchorStyle.arrow:
        _paintCurvedArrowPreview(canvas, size, fill, sweep: false);
        break;
      case _CustomAnchorStyle.none:
        _paintNoAnchorPreview(canvas, size, fill);
        break;
    }
    canvas.restore();
  }

  void _paintNoAnchorPreview(Canvas canvas, Size size, Paint fill) {
    final Paint stroke = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = fill.maskFilter;
    final double y = size.height * 0.55;
    canvas.drawLine(
      Offset(size.width * 0.26, y),
      Offset(size.width * 0.74, y),
      stroke,
    );
  }

  void _paintCurvedArrowPreview(
    Canvas canvas,
    Size size,
    Paint fill, {
    required bool sweep,
  }) {
    final double w = size.width;
    final double h = size.height;
    if (sweep) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.08, h * 0.86)
          ..cubicTo(w * 0.42, h * 0.8, w * 0.66, h * 0.55, w * 0.68, h * 0.26)
          ..lineTo(w * 0.48, h * 0.32)
          ..lineTo(w * 0.68, h * 0.02)
          ..lineTo(w * 0.96, h * 0.35)
          ..lineTo(w * 0.74, h * 0.31)
          ..cubicTo(w * 0.7, h * 0.64, w * 0.45, h * 0.86, w * 0.08, h * 0.86)
          ..close(),
        fill,
      );
      return;
    }

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.44, h * 0.9)
        ..cubicTo(w * 0.56, h * 0.7, w * 0.59, h * 0.48, w * 0.59, h * 0.25)
        ..lineTo(w * 0.38, h * 0.31)
        ..lineTo(w * 0.62, h * 0.0)
        ..lineTo(w * 0.86, h * 0.32)
        ..lineTo(w * 0.66, h * 0.28)
        ..cubicTo(w * 0.66, h * 0.56, w * 0.6, h * 0.76, w * 0.44, h * 0.9)
        ..close(),
      fill,
    );
  }
}

Path _dropletPreviewPath(Size size) {
  final double w = size.width;
  final double h = size.height;
  return Path()
    ..moveTo(w * 0.5, h * 0.1)
    ..cubicTo(w * 0.27, h * 0.3, w * 0.2, h * 0.56, w * 0.33, h * 0.74)
    ..cubicTo(w * 0.44, h * 0.9, w * 0.7, h * 0.9, w * 0.8, h * 0.72)
    ..cubicTo(w * 0.9, h * 0.54, w * 0.73, h * 0.31, w * 0.5, h * 0.1)
    ..close();
}

class _DropletAnchorSpec extends SpotlightGuidePathAnchorShape {
  const _DropletAnchorSpec();

  @override
  Size get preferredSize => _anchorShapeSize;

  @override
  double get connectionHalfExtent => 10;

  @override
  double get visualHalfExtent => _anchorVisualHalfExtent;

  @override
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {
    builder.cubicTo(path, -0.82, 0.18, -0.58, 0.72, 0, 1);
    builder.cubicTo(path, 0.58, 0.72, 0.82, 0.18, builder.endSide, 0);
  }
}

class _SweepAnchorSpec extends SpotlightGuidePathAnchorShape {
  const _SweepAnchorSpec();

  @override
  Size get preferredSize => _anchorShapeSize;

  @override
  double get connectionHalfExtent => 0;

  @override
  double get visualHalfExtent => _anchorVisualHalfExtent;

  @override
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {
    builder.cubicTo(path, 0.04, 0.14, 0.26, 0.36, 0.38, 0.58);
    builder.lineTo(path, 0.74, 0.58);
    builder.lineTo(path, 0, 1);
    builder.lineTo(path, -0.66, 0.58);
    builder.lineTo(path, -0.24, 0.6);
    builder.cubicTo(path, 0.08, 0.42, 0.08, 0.16, builder.endSide, 0);
  }
}

class _ArrowAnchorSpec extends SpotlightGuidePathAnchorShape {
  const _ArrowAnchorSpec();

  @override
  Size get preferredSize => _anchorShapeSize;

  @override
  double get connectionHalfExtent => 0;

  @override
  double get visualHalfExtent => _anchorVisualHalfExtent;

  @override
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {
    builder.cubicTo(path, 0.02, 0.16, 0.1, 0.38, 0.12, 0.62);
    builder.lineTo(path, 0.46, 0.62);
    builder.lineTo(path, 0, 1);
    builder.lineTo(path, -0.46, 0.62);
    builder.lineTo(path, -0.14, 0.62);
    builder.cubicTo(path, -0.08, 0.38, -0.02, 0.16, builder.endSide, 0);
  }
}

class _NoVisibleAnchorSpec extends SpotlightGuidePathAnchorShape {
  const _NoVisibleAnchorSpec();

  @override
  Size get preferredSize => _anchorShapeSize;

  @override
  double get connectionHalfExtent => 0;

  @override
  double get visualHalfExtent => 0;

  @override
  void addToPath(Path path, SpotlightGuideAnchorPathBuilder builder) {}
}
