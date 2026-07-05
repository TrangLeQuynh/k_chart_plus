part of '../indicator_template.dart';

class CCIIndicator extends SecondaryIndicator<MACDEntity, CCIStyle> {
  late final Paint _linePaint;

  CCIIndicator({ CCIStyle indicatorStyle = const CCIStyle() }): super(
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
      text: "CCI(${calcParams.first}):${formatNumber(entity.cci!, precision)}",
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
    double jumpStep = maxValue - minValue;
    late int jumpValue;
    if (jumpStep >= 100) {
      jumpValue = 100;
    } else if (jumpStep >= 10) {
      jumpValue = 10;
    } else {
      jumpValue = 1;
    }

    /// max
    TextPainter maxTp = TextPainter(
      text: TextSpan(
        text: "${NumberUtil.formatFixed(
          (maxValue / jumpValue).round() * jumpValue,
          0,
        ) ?? ''}",
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    maxTp.layout();
    maxTp.paint(
      canvas,
      Offset(
        chartRect.width - maxTp.width,
        chartRect.top,
      ),
    );

    /// min
    TextPainter minTp = TextPainter(
      text: TextSpan(
        text: "${NumberUtil.formatFixed(
          (minValue / jumpValue).round() * jumpValue,
          0,
        ) ?? ''}",
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    minTp.layout();
    minTp.paint(
      canvas,
      Offset(
        chartRect.width - minTp.width,
        chartRect.bottom - minTp.height,
      ),
    );
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors, double scaleX) {
    if (curPoint.cci == null || lastPoint.cci == null) return;
    canvas.drawLine(
      Offset(curX, getY(curPoint.cci!)),
      Offset(lastX, getY(lastPoint.cci!)),
      _linePaint..color = indicatorStyle.cciColor,
    );
  }

  @override
  void calc(List<KLineEntity> dataList) {
    final periods = calcParams.first;
    final p = periods - 1;
    double tpSum = 0;
    final tpList = [];
    for (int i = 0; i < dataList.length; i++) {
      final kline = dataList[i];
      kline.cci = null;
      final tp = (kline.high + kline.low + kline.close) / 3;
      tpSum += tp;
      tpList.add(tp);
      if (i >= p) {
        final maTp = tpSum / periods;
        final sliceTpList = tpList.sublist(i - p, i + 1);
        final sum = sliceTpList.fold(0.0, (s, tp) {
          s += (tp - maTp).abs();
          return s;
        });
        final md = sum / periods;
        kline.cci = md != 0 ? ((tp - maTp) / md / 0.015) : 0;
        final agoTp = (dataList[i - p].high + dataList[i - p].low + dataList[i - p].close) / 3;
        tpSum -= agoTp;
      }
    }
  }
}
