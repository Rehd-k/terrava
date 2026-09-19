import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:terrava/core/theme/terrava_theme.dart';

Future<Uint8List> createListingBeaconBitmap({
  required String label,
  required String propertyType,
  required String transactionType,
  required bool selected,
}) async {
  Color background;
  Color foreground;
  if (propertyType == 'LAND') {
    background = TerravaColors.secondary;
    foreground = TerravaColors.onSecondary;
  } else if (transactionType == 'RENT' || transactionType == 'LEASE') {
    background = TerravaColors.tertiaryContainer;
    foreground = TerravaColors.tertiaryFixed;
  } else {
    background = TerravaColors.primary;
    foreground = TerravaColors.onPrimary;
  }

  const height = 72.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: foreground,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final width = textPainter.width + 56;
  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(4, 4, width - 8, height - 18),
    const Radius.circular(999),
  );
  final paint = Paint()..color = background;
  canvas.drawRRect(rrect, paint);
  if (selected) {
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..color = TerravaColors.secondaryFixed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
  textPainter.paint(canvas, Offset((width - textPainter.width) / 2, 14));
  final tip = Path()
    ..moveTo(width / 2 - 8, height - 18)
    ..lineTo(width / 2 + 8, height - 18)
    ..lineTo(width / 2, height - 4)
    ..close();
  canvas.drawPath(tip, paint);

  final image = await recorder.endRecording().toImage(
    width.ceil(),
    height.ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
