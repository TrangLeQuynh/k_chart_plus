part of '../indicator_template.dart';

/**
 * RSI
 * RSI = SUM(MAX(CLOSE - REF(CLOSE,1),0),N) / SUM(ABS(CLOSE - REF(CLOSE,1)),N) × 100
 */
class RSIIndicator extends SecondaryIndicator<MACDEntity, RSIStyle> {
  late final Paint _linePaint;

  RSIIndicator({ RSIStyle indicatorStyle = const RSIStyle() }): super(
    name: 'relativeStrengthIndex',
    shortName: 'RSI',
    calcParams: const [6, 12, 24],
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;
  }

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.rsi != null) {
      minV = min(minV, entity.rsi!);
      maxV = max(maxV, entity.rsi!);
    }
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, KChartColors chartColors) {
    if (entity.rsi == null) return null;
    return TextSpan(
      text: "RSI(14):${formatNumber(entity.rsi!, precision)}",
      style: getTextStyle(indicatorStyle.rsiColor),
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
    if (curPoint.rsi == null || lastPoint.rsi == null) return;
    canvas.drawLine(
      Offset(curX, getY(curPoint.rsi!)),
      Offset(lastX, getY(lastPoint.rsi!)),
      _linePaint..color = indicatorStyle.rsiColor,
    );
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
