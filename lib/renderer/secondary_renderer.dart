import 'package:flutter/material.dart';
import 'package:k_chart_plus/indicator/indicator_template.dart';
import '../entity/macd_entity.dart';
import 'base_chart_renderer.dart';

class SecondaryRenderer extends BaseChartRenderer<MACDEntity> {
  SecondaryIndicator indicator;
  final KChartStyle chartStyle;
  final KChartColors chartColors;
  final double scaleX;

  SecondaryRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.indicator,
    int fixedLength,
    this.chartStyle,
    this.chartColors, {
    this.scaleX = 1.0,
  }) : super(
    chartRect: mainRect,
    maxValue: maxValue,
    minValue: minValue,
    topPadding: topPadding,
    fixedLength: fixedLength,
    gridColor: chartColors.gridColor,
  );

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    indicator.drawChart(lastPoint, curPoint, lastX, curX, getY, canvas, chartColors, scaleX);
  }

  @override
  void drawText(Canvas canvas, MACDEntity data, double x) {
    TextSpan? span = indicator.drawFigure(data, fixedLength, chartColors);
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    indicator.drawVerticalText(
      canvas: canvas,
      style: textStyle,
      maxValue: maxValue,
      minValue: minValue,
      fixedLength: fixedLength,
      chartRect: Rect.fromLTRB(
        chartRect.left,
        chartRect.top - topPadding,
        chartRect.right - chartStyle.space,
        chartRect.bottom,
      ),
    );
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    // canvas.drawLine(Offset(0, chartRect.top), Offset(chartRect.width, chartRect.top), gridPaint); //hidden line
    canvas.drawLine(
      Offset(0, chartRect.bottom),
      Offset(chartRect.width, chartRect.bottom),
      gridPaint,
    );
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //mSecondaryRect垂直线
      canvas.drawLine(
        Offset(columnSpace * i, chartRect.top - topPadding),
        Offset(columnSpace * i, chartRect.bottom),
        gridPaint,
      );
    }
  }
}
