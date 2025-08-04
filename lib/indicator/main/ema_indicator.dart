part of '../indicator_template.dart';

class EMAIndicator extends MainIndicator<CandleEntity> {
  EMAIndicator([List<int> calcParams = const [6, 12, 20]]): super(
    name: 'exponentialMovingAverage',
    shortName: 'EMA',
    calcParams: calcParams,
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.emaValueList?.isEmpty ?? true) return (minV, maxV);
    double minValue = minV;
    double maxValue = maxV;
    for (double value in entity.emaValueList!) {
      if (value == 0) continue;
      minValue = min(value, minValue);
      maxValue = max(value, maxValue);
    }
    return (minValue, maxValue);
  }

  @override
  TextSpan? drawFigure(CandleEntity entity, int precision) {
    List<InlineSpan> result = [];
    if (entity.emaValueList?.isEmpty ?? true) return null;
    for (int i = 0; i < (entity.emaValueList!.length); i++) {
      if (entity.emaValueList?[i] != 0) {
        var item = TextSpan(
          text: "EMA${calcParams[i]}:${formatNumber(entity.emaValueList![i], precision)}    ",
          style: TextStyle(
            fontSize: 10,
            color: chartColors.getMAColor(i),
          ),
        );
        result.add(item);
      }
    }
    return TextSpan(children: result);
  }


  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas) {
    if (
      curPoint.emaValueList == null ||
      lastPoint.emaValueList == null ||
      curPoint.emaValueList!.length != lastPoint.emaValueList!.length
    ) {
      return;
    }
    for (int i = 0; i < curPoint.emaValueList!.length; i++) {
      if (lastPoint.emaValueList?[i] != 0) {
        canvas.drawLine(
          Offset(curX, getY(curPoint.emaValueList![i])),
          Offset(lastX, getY(lastPoint.emaValueList![i])),
          _linePaint..color = chartColors.getMAColor(i),
        );
      }
    }
  }

  @override
  void calc(List<KLineEntity> dataList) {
    double closeSum = 0.0;
    List<double> emaValues = List<double>.filled(calcParams.length, 0);
    for (int i = 0; i < dataList.length; ++i) {
      KLineEntity entity = dataList[i];
      final close = entity.close;
      List<double> ema = List<double>.filled(calcParams.length, 0);
      closeSum += close;
      for (int j = 0; j < calcParams.length; ++j) {
        final p = calcParams[j];
        if (i >= p - 1) {
          if (i > p - 1) {
            emaValues[j] = (2 * close + (p - 1) * emaValues[j]) / (p + 1);
          } else {
            emaValues[j] = closeSum / p;
          }
          ema[j] = emaValues[j];
        }
      }
      entity.emaValueList = ema;
    }
  }
}
