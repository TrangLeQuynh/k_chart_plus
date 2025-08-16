part of '../indicator_template.dart';

class CCIIndicator extends SecondaryIndicator<MACDEntity, CCIStyle> {
  late final Paint _linePaint;

  CCIIndicator([ CCIStyle indicatorStyle = const CCIStyle() ]): super(
    name: 'commodityChannelIndex',
    shortName: 'CCI',
    calcParams: const [20],
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;
  }

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.cci != null) {
      minV = min(minV, entity.cci!);
      maxV = max(maxV, entity.cci!);
    }
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, KChartColors chartColors) {
    if (entity.cci == null) return null;
    return TextSpan(
      text: "CCI(14):${formatNumber(entity.cci!, precision)}",
      style: getTextStyle(indicatorStyle.cciColor),
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
    if (curPoint.cci == null || lastPoint.cci == null) return;
    canvas.drawLine(
      Offset(curX, getY(curPoint.cci!)),
      Offset(lastX, getY(lastPoint.cci!)),
      _linePaint..color = indicatorStyle.cciColor,
    );
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
