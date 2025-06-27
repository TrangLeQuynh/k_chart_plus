import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:k_chart_plus/chart_style.dart';
import 'package:k_chart_plus/entity/index.dart';

part 'main/sar_indicator.dart';
part 'main/ma_indicator.dart';
part 'main/boll_indicator.dart';

part 'secondary/macd_indicator.dart';
part 'secondary/cci_indicator.dart';
part 'secondary/kdj_indicator.dart';
part 'secondary/rsi_indicator.dart';
part 'secondary/wr_indicator.dart';

typedef GetYFunction= double Function(double y);

abstract class IndicatorTemplate<T> {
  final String name;

  final String shortName;

  final List<int> calcParams;

  final ChartColors chartColors;
  final ChartStyle? chartStyle;

  /// painter
  final Paint _linePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0;

  IndicatorTemplate({
    required this.name,
    required this.shortName,
    required this.calcParams,
    this.chartColors = const ChartColors(),
    this.chartStyle,
  });


  /// record.$1 : min value
  /// record.$2: max value
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV);

  TextSpan? drawFigure(T value, int precision);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas);

  void calc(List<KLineEntity> dataList);

  /// text format
  TextStyle getTextStyle(Color? color) {
    return TextStyle(fontSize: 10, color: color);
  }

  String formatNumber(double value, int precision) {
    return value.toStringAsFixed(precision);
  }
}

abstract class MainIndicator<T> extends IndicatorTemplate<T> {
  MainIndicator({
    required super.name,
    required super.shortName,
    required super.calcParams,
    super.chartColors,
    super.chartStyle,
  });
}

abstract class SecondaryIndicator<T> extends IndicatorTemplate<T> {
  SecondaryIndicator({
    required super.name,
    required super.shortName,
    required super.calcParams,
    super.chartColors,
    super.chartStyle,
  });
}
