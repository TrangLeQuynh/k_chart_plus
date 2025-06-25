part of '../indicator_template.dart';

class WRIndicator extends IndicatorTemplate<MACDEntity> {
  const WRIndicator(): super(
    name: 'volumeRatio',
    shortName: 'WR',
    calcParams: const [26, 6],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, ChartColors chartColors) {
    if (entity.r == null) return null;
    return TextSpan(
      text: "WR(14):${formatNumber(entity.r!, precision)}",
      style: getTextStyle(chartColors.rsiColor),
    );
  }
  @override
  List<FigureItem> drawChart(MACDEntity lastPoint, MACDEntity curPoint, ChartColors chartColors) {
    List<FigureItem> li = [];
    return li;
  }

  @override
  void calc(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }
}
