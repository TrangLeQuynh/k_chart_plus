import 'dart:math';
import 'dart:ui';

extension CanvasExtension on Canvas {
  void drawDashLine(Offset begin, Offset end, Paint paint, [ double space = 3.0, double width = 4.0]) {
    if (begin.dx == end.dx) {
      /// draw vertical line
      double startDy = begin.dy;
      double endDy = end.dy;
      while (startDy < endDy) {
        this.drawLine(
          Offset(begin.dx, startDy),
          Offset(begin.dx, min(startDy + width, endDy)),
          paint,
        );
        startDy += space + width;
      }
    }

    if (begin.dy == end.dy) {
      /// draw horizontal line
      double startDx = begin.dx;
      double endDx = end.dx;
      while (startDx < endDx) {
        this.drawLine(
          Offset(startDx, begin.dy),
          Offset(min(startDx + width, endDx), begin.dy),
          paint,
        );

        startDx += space + width;
      }
    }
  }
}
