import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:k_chart_plus/chart_style.dart';
import 'package:k_chart_plus/entity/index.dart';
part 'main/sar_indicator.dart';
part 'main/ma_indicator.dart';
part 'main/boll_indicator.dart';

enum FigureType {
  line, circle
}

class FigureItem {
  FigureType type;
  double? lastY;
  double? curY;
  Color color;

  FigureItem({
    required this.type,
    required this.color,
    required this.curY,
    this.lastY,
  });
}

abstract class IndicatorTemplate<T> {
  final String name;

  final String shortName;

  final List<int> calcParams;

  const IndicatorTemplate({
    required this.name,
    required this.shortName,
    required this.calcParams,
  });

  /// record.$1 : min value
  /// record.$2: max value
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV);

  TextSpan? drawFigure(CandleEntity value, int precision, ChartColors chartColor);

  List<FigureItem> drawChart(CandleEntity lastPoint, CandleEntity curPoint, ChartColors chartColors);

  void calc(List<KLineEntity> dataList);
}
