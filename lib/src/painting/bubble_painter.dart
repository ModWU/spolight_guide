part of '../../spotlight_guide.dart';

/// Paints [SpotlightGuideBubbleDecoration] as one continuous path.
class _SpotlightGuideBubblePainter extends BoxPainter {
  _SpotlightGuideBubblePainter(this.decoration);

  final SpotlightGuideBubbleDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size size = configuration.size ?? Size.zero;
    if (size.isEmpty) {
      return;
    }

    final Path path = _buildPath(offset, size);

    for (final BoxShadow shadow
        in decoration.boxShadow ?? const <BoxShadow>[]) {
      final BoxShadow safeShadow = BoxShadow(
        color: shadow.color,
        offset: _finiteOffsetOrZero(shadow.offset),
        blurRadius: _nonNegativeFiniteOrZero(shadow.blurRadius),
        spreadRadius: _nonNegativeFiniteOrZero(shadow.spreadRadius),
        blurStyle: shadow.blurStyle,
      );
      canvas.drawPath(path.shift(safeShadow.offset), safeShadow.toPaint());
    }

    canvas.drawPath(path, Paint()..color = decoration.color);
    _paintBorder(canvas, path);
  }

  void _paintBorder(Canvas canvas, Path path) {
    final double borderWidth = _nonNegativeFiniteOrZero(
      decoration.border.width,
    );
    if (decoration.border.style == BorderStyle.none || borderWidth <= 0) {
      return;
    }
    final Paint borderPaint = decoration.border.toPaint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipPath(path, doAntiAlias: true);
    canvas.drawPath(path, borderPaint);
    canvas.restore();
  }

  Path _buildPath(Offset offset, Size size) {
    final SpotlightGuideAnchorGeometry? geometry =
        decoration.effectiveAnchorGeometry;
    final Rect body = _bodyRect(offset, size, geometry);
    final double radius = math.min(
      _nonNegativeFiniteOrZero(decoration.borderRadius),
      math.min(body.width, body.height) / 2,
    );
    final SpotlightGuideAnchorConnection? connection = _resolveConnection(
      body: body,
      offset: offset,
      size: size,
      geometry: geometry,
    );
    if (connection == null) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
    }
    return switch (connection.direction) {
      SpotlightGuideIndicatorDirection.up => _buildTopAnchorPath(
        body,
        radius,
        connection,
        offset,
        size,
        geometry,
      ),
      SpotlightGuideIndicatorDirection.down => _buildBottomAnchorPath(
        body,
        radius,
        connection,
        offset,
        size,
        geometry,
      ),
      SpotlightGuideIndicatorDirection.left => _buildLeftAnchorPath(
        body,
        radius,
        connection,
        offset,
        size,
        geometry,
      ),
      SpotlightGuideIndicatorDirection.right => _buildRightAnchorPath(
        body,
        radius,
        connection,
        offset,
        size,
        geometry,
      ),
    };
  }

  Rect _bodyRect(
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    final double depth = geometry == null
        ? 0
        : _nonNegativeFiniteOrZero(decoration.anchor.preferredSize.height);
    final double bodyWidth = math.max(0, size.width - depth);
    final double bodyHeight = math.max(0, size.height - depth);
    return switch (geometry?.direction) {
      SpotlightGuideIndicatorDirection.up => Rect.fromLTWH(
        offset.dx,
        offset.dy + depth,
        size.width,
        bodyHeight,
      ),
      SpotlightGuideIndicatorDirection.down => Rect.fromLTWH(
        offset.dx,
        offset.dy,
        size.width,
        bodyHeight,
      ),
      SpotlightGuideIndicatorDirection.left => Rect.fromLTWH(
        offset.dx + depth,
        offset.dy,
        bodyWidth,
        size.height,
      ),
      SpotlightGuideIndicatorDirection.right => Rect.fromLTWH(
        offset.dx,
        offset.dy,
        bodyWidth,
        size.height,
      ),
      null => Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    };
  }

  SpotlightGuideAnchorConnection? _resolveConnection({
    required Rect body,
    required Offset offset,
    required Size size,
    required SpotlightGuideAnchorGeometry? geometry,
  }) {
    return decoration.anchor.resolveConnection(
      body: body,
      paintOffset: offset,
      paintSize: size,
      geometry: geometry,
    );
  }

  Path _buildTopAnchorPath(
    Rect body,
    double radius,
    SpotlightGuideAnchorConnection connection,
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    final Path path = Path()
      ..moveTo(body.left + radius, body.top)
      ..lineTo(connection.start, body.top);
    _addAnchor(path, body, offset, size, geometry);
    return path
      ..lineTo(body.right - radius, body.top)
      ..quadraticBezierTo(body.right, body.top, body.right, body.top + radius)
      ..lineTo(body.right, body.bottom - radius)
      ..quadraticBezierTo(
        body.right,
        body.bottom,
        body.right - radius,
        body.bottom,
      )
      ..lineTo(body.left + radius, body.bottom)
      ..quadraticBezierTo(
        body.left,
        body.bottom,
        body.left,
        body.bottom - radius,
      )
      ..lineTo(body.left, body.top + radius)
      ..quadraticBezierTo(body.left, body.top, body.left + radius, body.top)
      ..close();
  }

  Path _buildBottomAnchorPath(
    Rect body,
    double radius,
    SpotlightGuideAnchorConnection connection,
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    final Path path = Path()
      ..moveTo(body.left + radius, body.top)
      ..lineTo(body.right - radius, body.top)
      ..quadraticBezierTo(body.right, body.top, body.right, body.top + radius)
      ..lineTo(body.right, body.bottom - radius)
      ..quadraticBezierTo(
        body.right,
        body.bottom,
        body.right - radius,
        body.bottom,
      )
      ..lineTo(connection.end, body.bottom);
    _addAnchor(path, body, offset, size, geometry);
    return path
      ..lineTo(body.left + radius, body.bottom)
      ..quadraticBezierTo(
        body.left,
        body.bottom,
        body.left,
        body.bottom - radius,
      )
      ..lineTo(body.left, body.top + radius)
      ..quadraticBezierTo(body.left, body.top, body.left + radius, body.top)
      ..close();
  }

  Path _buildLeftAnchorPath(
    Rect body,
    double radius,
    SpotlightGuideAnchorConnection connection,
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    final Path path = Path()
      ..moveTo(body.left + radius, body.top)
      ..lineTo(body.right - radius, body.top)
      ..quadraticBezierTo(body.right, body.top, body.right, body.top + radius)
      ..lineTo(body.right, body.bottom - radius)
      ..quadraticBezierTo(
        body.right,
        body.bottom,
        body.right - radius,
        body.bottom,
      )
      ..lineTo(body.left + radius, body.bottom)
      ..quadraticBezierTo(
        body.left,
        body.bottom,
        body.left,
        body.bottom - radius,
      )
      ..lineTo(body.left, connection.end);
    _addAnchor(path, body, offset, size, geometry);
    return path
      ..lineTo(body.left, body.top + radius)
      ..quadraticBezierTo(body.left, body.top, body.left + radius, body.top)
      ..close();
  }

  Path _buildRightAnchorPath(
    Rect body,
    double radius,
    SpotlightGuideAnchorConnection connection,
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    final Path path = Path()
      ..moveTo(body.left + radius, body.top)
      ..lineTo(body.right - radius, body.top)
      ..quadraticBezierTo(body.right, body.top, body.right, body.top + radius)
      ..lineTo(body.right, connection.start);
    _addAnchor(path, body, offset, size, geometry);
    return path
      ..lineTo(body.right, body.bottom - radius)
      ..quadraticBezierTo(
        body.right,
        body.bottom,
        body.right - radius,
        body.bottom,
      )
      ..lineTo(body.left + radius, body.bottom)
      ..quadraticBezierTo(
        body.left,
        body.bottom,
        body.left,
        body.bottom - radius,
      )
      ..lineTo(body.left, body.top + radius)
      ..quadraticBezierTo(body.left, body.top, body.left + radius, body.top)
      ..close();
  }

  void _addAnchor(
    Path path,
    Rect body,
    Offset offset,
    Size size,
    SpotlightGuideAnchorGeometry? geometry,
  ) {
    decoration.anchor.addToPath(
      path: path,
      body: body,
      paintOffset: offset,
      paintSize: size,
      geometry: geometry,
    );
  }
}
