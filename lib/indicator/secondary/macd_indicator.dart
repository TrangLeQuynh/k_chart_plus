part of '../indicator_template.dart';

/**
 * MACD：参数快线移动平均、慢线移动平均、移动平均，
 * 默认参数值12、26、9。
 * 公式：⒈首先分别计算出收盘价12日指数平滑移动平均线与26日指数平滑移动平均线，分别记为EMA(12）与EMA(26）。
 * ⒉求这两条指数平滑移动平均线的差，即：DIFF = EMA(SHORT) － EMA(LONG)。
 * ⒊再计算DIFF的M日的平均的指数平滑移动平均线，记为DEA。
 * ⒋最后用DIFF减DEA，得MACD。MACD通常绘制成围绕零轴线波动的柱形图。MACD柱状大于0涨颜色，小于0跌颜色。
 */
class MACDIndicator extends SecondaryIndicator<MACDEntity, MACDStyle> {
  late final Paint _linePaint;
  late final Paint _rectPaint;

  MACDIndicator({ MACDStyle indicatorStyle = const MACDStyle() }): super(
    name: 'movingAverageConvergenceDivergence',
    shortName: 'MACD',
    calcParams: const [12, 26, 9],
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;

    _rectPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.strokeWidth;
  }

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
  TextSpan? drawFigure(MACDEntity entity, int precision, KChartColors chartColors) {
    return TextSpan(
      children: [
        TextSpan(
          text: "MACD(12,26,9) ",
          style: getTextStyle(chartColors.defaultTextColor),
        ),
        if (entity.macd != null && entity.macd != 0)
          TextSpan(
            text: "MACD:${formatNumber(entity.macd!, precision)}  ",
            style: getTextStyle(indicatorStyle.macdColor),
          ),
        if (entity.dif != null && entity.dif != 0)
          TextSpan(
            text: "DIF:${formatNumber(entity.dif!, precision)}  ",
            style: getTextStyle(indicatorStyle.difColor),
          ),
        if (entity.dea != null && entity.dea != 0)
          TextSpan(
            text: "DEA:${formatNumber(entity.dea!, precision)}",
            style: getTextStyle(indicatorStyle.deaColor),
          ),
      ],
    );
  }

  @override
  void drawVerticalText({
    required Canvas canvas,
    required TextStyle style,
    required double maxValue,
    required double minValue,
    required int fixedLength,
    required Rect chartRect,
  }) {
    TextPainter maxTp = TextPainter(
      text: TextSpan(
        text: "${NumberUtil.formatFixed(maxValue, fixedLength) ?? ''}",
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    maxTp.layout();

    TextPainter minTp = TextPainter(
      text: TextSpan(
        text: "${NumberUtil.formatFixed(minValue, fixedLength) ?? ''}",
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    minTp.layout();

    maxTp.paint(
      canvas,
      Offset(chartRect.width - maxTp.width, chartRect.top),
    );
    minTp.paint(
      canvas,
      Offset(chartRect.width - minTp.width, chartRect.bottom - minTp.height),
    );
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors) {
    final prevMacd = lastPoint.macd;
    final macd = curPoint.macd;
    if (curPoint.macd != null) {
      final mMACDWidth = indicatorStyle.macdWidth;
      double r = mMACDWidth / 2;
      double zeroy = getY(0);
      double macdY = getY(macd!);
      _rectPaint.style = (prevMacd == null || prevMacd <= macd) ? PaintingStyle.stroke : PaintingStyle.fill;
      if (macd > 0) {
        canvas.drawRect(
          Rect.fromLTRB(curX - r, macdY, curX + r, zeroy),
          _rectPaint
            ..color = indicatorStyle.upColor,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTRB(curX - r, zeroy, curX + r, macdY),
          _rectPaint
            ..color = indicatorStyle.dnColor,
        );
      }
    }
    if (lastPoint.dif != null && lastPoint.dif != 0 && curPoint.dif != null) {
      canvas.drawLine(
        Offset(curX, getY(curPoint.dif!)),
        Offset(lastX, getY(lastPoint.dif!)),
        _linePaint..color = indicatorStyle.difColor,
      );
    }
    if (lastPoint.dea != null && lastPoint.dea != 0 && curPoint.dea != null) {
      canvas.drawLine(
        Offset(curX, getY(curPoint.dea!)),
        Offset(lastX, getY(lastPoint.dea!)),
        _linePaint..color = indicatorStyle.deaColor,
      );
    }
  }

  @override
  void calc(List<KLineEntity> dataList) {
    final params = calcParams;
    double closeSum = 0;
    double emaShort = 0;
    double emaLong = 0;
    double dif = 0;
    double difSum = 0;
    double dea = 0;
    final maxPeriod = max(params[0], params[1]);

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final close = entity.close;
      closeSum += close;
      if (i >= params[0] - 1) {
        if (i > params[0] - 1) {
          emaShort = (2 * close + (params[0] - 1) * emaShort) / (params[0] + 1);
        } else {
          emaShort = closeSum / params[0];
        }
      }

      if (i >= params[1] - 1) {
        if (i > params[1] - 1) {
          emaLong = (2 * close + (params[1] - 1) * emaLong) / (params[1] + 1);
        } else {
          emaLong = closeSum / params[1];
        }
      }
      if (i >= maxPeriod - 1) {
        dif = emaShort - emaLong;
        entity.dif = dif;
        difSum += dif;
        if (i >= maxPeriod + params[2] - 2) {
          if (i > maxPeriod + params[2] - 2) {
            dea = (dif * 2 + dea * (params[2] - 1)) / (params[2] + 1);
          } else {
            dea = difSum / params[2];
          }
          entity.macd = (dif - dea) * 2;
          entity.dea = dea;
        }
      }
    }
  }
}
