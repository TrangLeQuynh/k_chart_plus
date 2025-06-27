part of '../indicator_template.dart';

class SARIndicator extends MainIndicator<CandleEntity> {
  SARIndicator(): super(
    name: 'stopAndReverse',
    shortName: 'SAR',
    calcParams: const [2, 2, 20],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.sar == null) return (minV, maxV);
    return (
      min(entity.sar!, minV),
      max(entity.sar!, maxV),
    );
  }

  @override
  TextSpan? drawFigure(CandleEntity entity, int precision) {
    double? value = entity.sar;
    if (value == null) return null;
    return TextSpan(
      text: "SAR: ${formatNumber(value, precision)}",
      style: TextStyle(
        fontSize: 10,
        color: chartColors.sarColor,
      ),
    );
  }

  @override
  List<FigureItem> drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX, double curX, GetYFunction getY) {
    final sar = curPoint.sar;
    if (sar == null) return [];
    final halfHL = (curPoint.high + curPoint.low) / 2;
    late final color;
    if (sar == halfHL) {
      color = chartColors.avgColor;
    } else if (sar < halfHL) {
      color = chartColors.upColor;
    } else {
      color = chartColors.dnColor;
    }
    return [
      FigureItem(
        type: FigureType.circle,
        color: color,
        cur: Offset(curX, getY(sar)),
        paint: _linePaint,
      ),
    ];
  }

  @override
  void calc(List<KLineEntity> dataList) {
    final startAf = calcParams[0] / 100;
    final step = calcParams[1] / 100;
    final maxAf = calcParams[2] / 100;

    // Acceleration factor
    double af = startAf;
    // Extreme point
    double ep = -100;
    // Determine trend direction — false: downtrend
    bool isIncreasing = false;
    double sar = 0;

    for (int i = 0; i < dataList.length; ++i) {
      // the previous period SAR
      final preSar = sar;
      final high = dataList[i].high;
      final low = dataList[i].low;

      if (isIncreasing) {
        // Uptrend
        if (ep == -100 || ep < high) {
          // Reinitialize parameters
          ep = high;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final lowMin = min(dataList[max(1, i) - 1].low, low);
        if (sar > dataList[i].low) {
          sar = ep;
          // Reinitialize parameters
          af = startAf;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar > lowMin) {
          sar = lowMin;
        }
      } else {
        if (ep == -100 || ep > low) {
          // Reinitialize parameters
          ep = low;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final highMax = max(dataList[max(1, i) - 1].high, high);
        if (sar < dataList[i].high) {
          sar = ep;
          // Reinitialize parameters
          af = 0;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar < highMax) {
          sar = highMax;
        }
      }

      dataList[i].sar = sar;
    }
  }
}
