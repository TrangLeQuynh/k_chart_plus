part of '../indicator_template.dart';

/**
 * MACD：参数快线移动平均、慢线移动平均、移动平均，
 * 默认参数值12、26、9。
 * 公式：⒈首先分别计算出收盘价12日指数平滑移动平均线与26日指数平滑移动平均线，分别记为EMA(12）与EMA(26）。
 * ⒉求这两条指数平滑移动平均线的差，即：DIFF = EMA(SHORT) － EMA(LONG)。
 * ⒊再计算DIFF的M日的平均的指数平滑移动平均线，记为DEA。
 * ⒋最后用DIFF减DEA，得MACD。MACD通常绘制成围绕零轴线波动的柱形图。MACD柱状大于0涨颜色，小于0跌颜色。
 */
class MACDIndicator extends SecondaryIndicator<MACDEntity> {
  final Paint _rectPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..style = PaintingStyle.fill;

  MACDIndicator(): super(
    name: 'movingAverageConvergenceDivergence',
    shortName: 'MACD',
    calcParams: const [12, 26, 9],
    chartStyle: const ChartStyle(),
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.macd != null) {
      minV = min(minV, entity.macd!);
      maxV = max(maxV, entity.macd!);
    }
    if (entity.dea != null) {
      minV = min(minV, entity.dea!);
      maxV = max(maxV, entity.dea!);
    }
    if (entity.dif != null) {
      minV = min(minV, entity.dif!);
      maxV = max(maxV, entity.dif!);
    }
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision) {
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
  List<FigureItem> drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, GetYFunction getY) {
    final mMACDWidth = chartStyle!.macdWidth;
    final macd = curPoint.macd ?? 0;
    double macdY = getY(macd);
    double r = mMACDWidth / 2;
    double zeroy = getY(0);

    List<FigureItem> li = [];
    if (macd > 0) {
      li.add(
        FigureItem(
          type: FigureType.rect,
          color: chartColors.upColor,
          rect: Rect.fromLTRB(curX - r, macdY, curX + r, zeroy),
          paint: _linePaint,
        ),
      );

    } else {
      li.add(
        FigureItem(
          type: FigureType.rect,
          color: chartColors.dnColor,
          rect: Rect.fromLTRB(curX - r, zeroy, curX + r, macdY),
          paint: _linePaint,
        ),
      );
    }
    if (lastPoint.dif != null && lastPoint.dif != 0 && curPoint.dif != null) {
      li.add(
        FigureItem(
          type: FigureType.line,
          color: chartColors.difColor,
          cur: Offset(curX, getY(curPoint.dif!)),
          last: Offset(lastX, getY(lastPoint.dif!)),
          paint: _linePaint,
        ),
      );
    }
    if (lastPoint.dea != null && lastPoint.dea != 0 && curPoint.dea != null) {
      li.add(
        FigureItem(
          type: FigureType.line,
          color: chartColors.deaColor,
          cur: Offset(curX, getY(curPoint.dea!)),
          last: Offset(lastX, getY(lastPoint.dea!)),
          paint: _linePaint,
        ),
      );
    }
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
