part of '../indicator_template.dart';

class KDJIndicator extends SecondaryIndicator<MACDEntity, KDJStyle> {
  late final Paint _linePaint;

  KDJIndicator({ KDJStyle indicatorStyle = const KDJStyle() }): super(
    name: 'stoch',
    shortName: 'KDJ',
    calcParams: const [],//[9, 3, 3], [9, 1, 3],
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;
  }

  @override
  (double, double) getMaxMinValue(MACDEntity entity, double minV, double maxV) {
    if (entity.k != null) {
      minV = min(minV, entity.k!);
      maxV = max(maxV, entity.k!);
    }
    if (entity.d != null) {
      minV = min(minV, entity.d!);
      maxV = max(maxV, entity.d!);
    }
    if (entity.j != null) {
      minV = min(minV, entity.j!);
      maxV = max(maxV, entity.j!);
    }
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, KChartColors chartColors) {
    return TextSpan(
      children: [
        TextSpan(
          text: "KDJ(9,1,3) ",
          style: getTextStyle(chartColors.defaultTextColor),
        ),
        if (entity.k != null && entity.k != 0)
          TextSpan(
            text: "K:${formatNumber(entity.k!, precision)}  ",
            style: getTextStyle(indicatorStyle.kColor),
          ),
        if (entity.d != null && entity.d != 0)
          TextSpan(
            text: "D:${formatNumber(entity.d!, precision)}  ",
            style: getTextStyle(indicatorStyle.dColor),
          ),
        if (entity.j != null && entity.j != 0)
          TextSpan(
            text: "J:${formatNumber(entity.j!, precision)}",
            style: getTextStyle(indicatorStyle.jColor),
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
    List<int> rangeValue = [80, 20];
    final spaceRange = maxValue - minValue;

    for (int i = 0; i < rangeValue.length; ++i) {
      final value = rangeValue[i];
      if (value < minValue || value > maxValue) continue;
      TextPainter tp = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: style,
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final ratio = (value - minValue) / spaceRange;
      final x = chartRect.width - tp.width;
      final y = chartRect.bottom - ratio * chartRect.height - tp.height / 2;
      tp.paint(
        canvas,
        Offset(x, y.clamp(chartRect.top, chartRect.bottom - tp.height)),
      );
    }
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors) {
    if (curPoint.k != null || lastPoint.k != null) {
      canvas.drawLine(
        Offset(curX, getY(curPoint.k!)),
        Offset(lastX, getY(lastPoint.k!)),
        _linePaint..color = indicatorStyle.kColor,
      );
    }
    if (curPoint.d != null || lastPoint.d != null) {
      canvas.drawLine(
        Offset(curX, getY(curPoint.d!)),
        Offset(lastX, getY(lastPoint.d!)),
        _linePaint..color = indicatorStyle.dColor,
      );
    }
    if (curPoint.j != null || lastPoint.j != null) {
      canvas.drawLine(
        Offset(curX, getY(curPoint.j!)),
        Offset(lastX, getY(lastPoint.j!)),
        _linePaint..color = indicatorStyle.jColor,
      );
    }
  }

  @override
  void calc(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }
}
