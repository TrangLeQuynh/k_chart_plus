part of '../indicator_template.dart';

class Boll {
  double? up;
  double? mid;
  double? dn;
  double? BOLLMA;
}

class BOLLIndicator extends IndicatorTemplate<CandleEntity> {
  const BOLLIndicator(): super(
    name: 'bollingerBands',
    shortName: 'BOLL',
    calcParams: const [20, 2],
  );

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    if (entity.boll == null) return (minV, maxV);
    double minValue = minV;
    if (entity.boll!.dn != null) {
      minValue = min(minValue, entity.boll!.dn!);
    }
    double maxValue = maxV;
    if (entity.boll!.up != null) {
      maxValue = max(maxValue, entity.boll!.up!);
    }
    return (minValue, maxValue);
  }

  @override
  TextSpan? drawFigure(CandleEntity entity, int precision, ChartColors chartColors) {
    if (entity.boll == null) return null;
    Boll value = entity.boll!;
    return TextSpan(
      children: [
        if (value.mid != null && value.mid != 0)
          TextSpan(
            text: "BOLL:${value.mid!.toStringAsFixed(precision)}    ",
            style: TextStyle(
              fontSize: 10,
              color: chartColors.bollColor,
            ),
          ),
        if (value.up != null && value.up != 0)
          TextSpan(
            text: "UB:${value.up!.toStringAsFixed(precision)}    ",
            style: TextStyle(
              fontSize: 10,
              color: chartColors.ubColor,
            ),
          ),
        if (value.dn != null && value.dn != 0)
          TextSpan(
            text: "LB:${value.dn!.toStringAsFixed(precision)} ",
            style: TextStyle(
              fontSize: 10,
              color: chartColors.lbColor,
            ),
          ),
      ],
    );
  }
  @override
  List<FigureItem> drawChart(CandleEntity lastPoint, CandleEntity curPoint, ChartColors chartColors) {
    if (lastPoint.boll == null || curPoint.boll == null) return [];
    List<FigureItem> li = [];
    /// BOLL
    li.add(
      FigureItem(
        type: FigureType.line,
        color: chartColors.bollColor,
        curY: curPoint.boll!.mid,
        lastY: lastPoint.boll!.mid,
      ),
    );

    /// UB
    li.add(
      FigureItem(
        type: FigureType.line,
        color: chartColors.ubColor,
        curY: curPoint.boll!.up,
        lastY: lastPoint.boll!.up,
      ),
    );
    /// LB
    li.add(
      FigureItem(
        type: FigureType.line,
        color: chartColors.lbColor,
        curY: curPoint.boll!.dn,
        lastY: lastPoint.boll!.dn,
      ),
    );

    return li;
  }

  @override
  void calc(List<KLineEntity> dataList) {
    int n = calcParams[0];
    int k = calcParams[1];
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.boll!.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.boll!.mid = entity.boll!.BOLLMA!;
        entity.boll!.up = entity.boll!.mid! + k * md;
        entity.boll!.dn = entity.boll!.mid! - k * md;
      }
    }
  }

  void _calcBOLLMA(int day, List<KLineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      ma += entity.close;
      entity.boll = Boll();
      if (i == day - 1) {
        entity.boll!.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.boll!.BOLLMA = ma / day;
      } else {
        entity.boll!.BOLLMA = null;
      }
    }
  }
}
