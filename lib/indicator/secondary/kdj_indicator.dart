part of '../indicator_template.dart';

class KDJIndicator extends IndicatorTemplate<MACDEntity> {
  const KDJIndicator(): super(
    name: 'stoch',
    shortName: 'KDJ',
    calcParams: const [9, 3, 3],
  );

  @override
  (double, double) getMaxMinValue(MACDEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }

  @override
  TextSpan? drawFigure(MACDEntity entity, int precision, ChartColors chartColors) {
    return TextSpan(
      children: [
        TextSpan(
          text: "KDJ(9,1,3)    ",
          style: getTextStyle(chartColors.defaultTextColor),
        ),
        if (entity.k != null && entity.k != 0)
          TextSpan(
            text: "K:${formatNumber(entity.k!, precision)}    ",
            style: getTextStyle(chartColors.kColor),
          ),
        if (entity.d != null && entity.d != 0)
          TextSpan(
            text: "D:${formatNumber(entity.d!, precision)}    ",
            style: getTextStyle(chartColors.dColor),
          ),
        if (entity.j != null && entity.j != 0)
          TextSpan(
            text: "J:${formatNumber(entity.j!, precision)}    ",
            style: getTextStyle(chartColors.jColor),
          ),
      ],
    );
  }
  @override
  List<FigureItem> drawChart(MACDEntity lastPoint, MACDEntity curPoint, ChartColors chartColors) {
    List<FigureItem> li = [];
    return li;
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
