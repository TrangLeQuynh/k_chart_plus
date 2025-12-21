part of '../indicator_template.dart';

class WRIndicator extends SecondaryIndicator<MACDEntity, WRStyle> {
  late final Paint _linePaint;

  WRIndicator({ WRStyle indicatorStyle = const WRStyle() }): super(
    name: 'volumeRatio',
    shortName: 'WR',
    calcParams: const [26, 6],
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;
  }

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (-100, 0);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, KChartColors chartColors) {
    if (entity.r == null) return null;
    return TextSpan(
      text: "WR(14):${formatNumber(entity.r!, precision)}",
      style: getTextStyle(indicatorStyle.wrColor),
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
    if (curPoint.r == null || lastPoint.r == null) return;
    canvas.drawLine(
      Offset(curX, getY(curPoint.r!)),
      Offset(lastX, getY(lastPoint.r!)),
      _linePaint..color = indicatorStyle.wrColor,
    );
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
