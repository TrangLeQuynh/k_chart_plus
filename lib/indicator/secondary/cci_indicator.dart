part of '../indicator_template.dart';

class CCIIndicator extends IndicatorTemplate<MACDEntity> {
  const CCIIndicator(): super(
    name: 'commodityChannelIndex',
    shortName: 'CCI',
    calcParams: const [20],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, ChartColors chartColors) {
    if (entity.cci == null) return null;
    return TextSpan(
      text: "CCI(14):${formatNumber(entity.cci!, precision)}",
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
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount +=
            (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3)
                .abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }
}
