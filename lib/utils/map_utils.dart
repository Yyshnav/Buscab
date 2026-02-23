import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ridesync/theme/app_theme.dart';

class MapUtils {
  static Future<BitmapDescriptor> getVehicleMarker() async {
    const size = 120;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2.5,
      shadowPaint,
    );

    // Draw background circle
    final Paint circlePaint = Paint()..color = AppTheme.primary;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      circlePaint,
    );

    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );

    // Draw Icon
    const iconSize = 60.0;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_taxi_rounded.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: Icons.local_taxi_rounded.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - iconSize / 2, size / 2 - iconSize / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
}
