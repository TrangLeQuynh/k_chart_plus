import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

part 'indicator_style.dart';

part 'main/sar_indicator.dart';
part 'main/ma_indicator.dart';
part 'main/boll_indicator.dart';
part 'main/ema_indicator.dart';

part 'secondary/macd_indicator.dart';
part 'secondary/cci_indicator.dart';
part 'secondary/kdj_indicator.dart';
part 'secondary/rsi_indicator.dart';
part 'secondary/wr_indicator.dart';

typedef GetYFunction= double Function(double y);

abstract class IndicatorTemplate<T, K> {
  final String name;

  final String shortName;

  final List<int> calcParams;

  final K indicatorStyle;

  IndicatorTemplate({
    required this.name,
    required this.shortName,
    required this.calcParams,
    required this.indicatorStyle,
  });


  /// record.$1 : min value
  /// record.$2: max value
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV);

  TextSpan? drawFigure(T value, int precision, KChartColors chartColors);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors, double scaleX);

  void calc(List<KLineEntity> dataList);

  /// text format
  TextStyle getTextStyle(Color? color) {
    return TextStyle(fontSize: 10, color: color);
  }

  String formatNumber(double value, int precision) {
    return NumberUtil.format(value, precision) ?? '--';
  }
}

abstract class MainIndicator<T, K> extends IndicatorTemplate<T, K> {
  MainIndicator({
    required super.name,
    required super.shortName,
    required super.calcParams,
    required super.indicatorStyle,
  });
}

abstract class SecondaryIndicator<T, K> extends IndicatorTemplate<T, K> {
  SecondaryIndicator({
    required super.name,
    required super.shortName,
    required super.calcParams,
    required super.indicatorStyle,
  });

  void drawVerticalText({
    required Canvas canvas,
    required TextStyle style,
    required double maxValue,
    required double minValue,
    required int fixedLength,
    required Rect chartRect,
  });
}
