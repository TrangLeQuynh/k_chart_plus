part of '../indicator_template.dart';

class EMAIndicator extends MainIndicator<CandleEntity, MAStyle> {
  late final Paint _linePaint;

  EMAIndicator({
    List<int> calcParams = const [5, 10, 30, 60],
    MAStyle indicatorStyle = const MAStyle(),
  }): super(
    name: 'exponentialMovingAverage',
    shortName: 'EMA',
    calcParams: calcParams,
    indicatorStyle: indicatorStyle,
  ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = indicatorStyle.lineWidth;
  }

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
  TextSpan? drawFigure(CandleEntity entity, int precision, KChartColors chartColors) {
    List<InlineSpan> result = [];
    if (entity.emaValueList?.isEmpty ?? true) return null;
    for (int i = 0; i < (entity.emaValueList!.length); i++) {
      if (entity.emaValueList?[i] != 0) {
        var item = TextSpan(
          text: "EMA${calcParams[i]}:${formatNumber(entity.emaValueList![i], precision)}  ",
          style: TextStyle(
            fontSize: 10,
            color: indicatorStyle.getMAColor(i),
          ),
        );
        result.add(item);
      }
    }
    return TextSpan(children: result);
  }


  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors) {
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
          _linePaint..color = indicatorStyle.getMAColor(i),
        );
      }
    }
  }

  @override
  void calc(List<KLineEntity> dataList) {
    /// Formula:
    ///   Multiplier = 2 / (period + 1)
    ///   EMA = (Closing Price - Previous EMA) * Multiplier + Previous EMA
    List<double> emaValues = List<double>.filled(calcParams.length, 0);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      List<double> ema = List<double>.filled(calcParams.length, 0);
      for (int j = 0; j < calcParams.length; ++j) {
        final p = calcParams[j];
        double multiplier = 2 / (p + 1);
        if (i == 0) {
          emaValues[j] = entity.close;
        } else {
          emaValues[j] = (entity.close - emaValues[j]) * multiplier + emaValues[j];
        }
        ema[j] = emaValues[j];
      }

      entity.emaValueList = ema;
    }
  }
}
