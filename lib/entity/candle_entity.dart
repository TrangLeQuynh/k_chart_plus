import 'package:k_chart_plus/indicator/indicator_template.dart';

mixin CandleEntity {
  late double open;
  late double high;
  late double low;
  late double close;

  // movingAverage
  List<double>? maValueList;

  List<double>? emaValueList;

  // stopAndReverse
  double? sar;

  // bollingerBands
  Boll? boll;
}
