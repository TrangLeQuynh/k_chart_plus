part of '../indicator_template.dart';

class MAIndicator extends MainIndicator<CandleEntity, MAStyle> {
  late final Paint _linePaint;

  MAIndicator({
    List<int> calcParams = const [5, 10, 30, 60],
    MAStyle indicatorStyle = const MAStyle(),
  }): super(
    name: 'movingAverage',
    shortName: 'MA',
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
    if (entity.maValueList?.isEmpty ?? true) return (minV, maxV);
    double minValue = minV;
    double maxValue = maxV;
    for (double value in entity.maValueList!) {
      if (value == 0) continue;
      minValue = min(value, minValue); // min(result, i == 0 ? double.maxFinite : i);
      maxValue = max(value, maxValue);
    }
    return (minValue, maxValue);
  }

  @override
  TextSpan? drawFigure(CandleEntity entity, int precision, KChartColors chartColors) {
    List<InlineSpan> result = [];
    if (entity.maValueList?.isEmpty ?? true) return null;
    for (int i = 0; i < (entity.maValueList!.length); i++) {
      if (entity.maValueList?[i] != 0) {
        var item = TextSpan(
          text: "MA${calcParams[i]}:${formatNumber(entity.maValueList![i], precision)}  ",
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
    if (curPoint.maValueList == null ||
        lastPoint.maValueList == null ||
        curPoint.maValueList!.length != lastPoint.maValueList!.length) {
      return;
    }
    for (int i = 0; i < curPoint.maValueList!.length; i++) {
      if (lastPoint.maValueList?[i] != 0) {
        canvas.drawLine(
          Offset(curX, getY(curPoint.maValueList![i])),
          Offset(lastX, getY(lastPoint.maValueList![i])),
          _linePaint..color = indicatorStyle.getMAColor(i),
        );
      }
    }
  }

  @override
  void calc(List<KLineEntity> dataList) {
    List<double> ma = List<double>.filled(calcParams.length, 0);
    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.maValueList = List<double>.filled(calcParams.length, 0);

        for (int j = 0; j < calcParams.length; j++) {
          ma[j] += closePrice;
          if (i == calcParams[j] - 1) {
            entity.maValueList?[j] = ma[j] / calcParams[j];
          } else if (i >= calcParams[j]) {
            ma[j] -= dataList[i - calcParams[j]].close;
            entity.maValueList?[j] = ma[j] / calcParams[j];
          }
        }
      }
    }
  }
}
