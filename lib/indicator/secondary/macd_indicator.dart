part of '../indicator_template.dart';

class MACDIndicator extends IndicatorTemplate<MACDEntity> {
  const MACDIndicator(): super(
    name: 'movingAverageConvergenceDivergence',
    shortName: 'MACD',
    calcParams: const [12, 26, 9],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, ChartColors chartColors) {
    return TextSpan(
      children: [
        TextSpan(
          text: "MACD(12,26,9)    ",
          style: getTextStyle(chartColors.defaultTextColor),
        ),
        if (entity.macd != null && entity.macd != 0)
          TextSpan(
            text: "MACD:${formatNumber(entity.macd!, precision)}    ",
            style: getTextStyle(chartColors.macdColor),
          ),
        if (entity.dif != null && entity.dif != 0)
          TextSpan(
            text: "DIF:${formatNumber(entity.dif!, precision)}    ",
            style: getTextStyle(chartColors.difColor),
          ),
        if (entity.dea != null && entity.dea != 0)
          TextSpan(
            text: "DEA:${formatNumber(entity.dea!, precision)}    ",
            style: getTextStyle(chartColors.deaColor),
          ),
      ],
    );
  }

  @override
  List<FigureItem> drawChart(MACDEntity lastPoint, MACDEntity curPoint, ChartColors chartColors) {
    List<FigureItem> li = [];
    return li;
  }

  @override
  void calc(List<KLineEntity> dataList) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }
}
