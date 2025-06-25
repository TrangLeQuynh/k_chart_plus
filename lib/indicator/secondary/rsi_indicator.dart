part of '../indicator_template.dart';

/**
 * RSI
 * RSI = SUM(MAX(CLOSE - REF(CLOSE,1),0),N) / SUM(ABS(CLOSE - REF(CLOSE,1)),N) × 100
 */
class RSIIndicator extends IndicatorTemplate<MACDEntity> {
  const RSIIndicator(): super(
    name: 'relativeStrengthIndex',
    shortName: 'RSI',
    calcParams: const [6, 12, 24],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, ChartColors chartColors) {
    if (entity.rsi == null) return null;
    return TextSpan(
      text: "RSI(14):${formatNumber(entity.rsi!, precision)}",
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
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }
}
