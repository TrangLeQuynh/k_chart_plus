part of '../indicator_template.dart';

class ZigZagIndicator extends MainIndicator<CandleEntity, ZigZagStyle> {
  late final Paint _linePaint;

  ZigZagIndicator({
    // depth, backstep, deviation
    List<int> calcParams = const [12, 2, 5],
    ZigZagStyle indicatorStyle = const ZigZagStyle(),
  }) : super(
          name: 'ZIGZAG',
          shortName: 'ZIGZAG',
          calcParams: calcParams,
          indicatorStyle: indicatorStyle,
        ) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = indicatorStyle.lineWidth
      ..color = indicatorStyle.zigzagColor;
  }

  @override
  (double, double) getMaxMinValue(
      KLineEntity entity, double minV, double maxV) {
    if (entity.zigzag == null || entity.zigzag == 0) return (minV, maxV);
    return (min(minV, entity.zigzag!), max(maxV, entity.zigzag!));
  }

  @override
  TextSpan? drawFigure(
      CandleEntity entity, int precision, KChartColors chartColors) {
    if (entity is! ZigZagEntity) return null;
    final zEntity = entity as ZigZagEntity;

    if (zEntity.zigzag == null || zEntity.zigzag == 0) return null;
    return TextSpan(
      text:
          "${shortName}(${calcParams[0]},${calcParams[1]},${calcParams[2]}): ${formatNumber(zEntity.zigzag!, precision)}    ",
      style: getTextStyle(indicatorStyle.zigzagColor),
    );
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors) {
    if (lastPoint is! ZigZagEntity || curPoint is! ZigZagEntity) return;
    final lastZ = lastPoint as ZigZagEntity;
    final curZ = curPoint as ZigZagEntity;

    if (lastZ.zigzag == null ||
        curZ.zigzag == null ||
        lastZ.zigzag == 0 ||
        curZ.zigzag == 0) {
      return;
    }

    canvas.drawLine(
      Offset(lastX, getY(lastZ.zigzag!)),
      Offset(curX, getY(curZ.zigzag!)),
      _linePaint,
    );
  }

  @override
  void calc(List<KLineEntity> dataList) {
    if (dataList.isEmpty) return;

    final depth = calcParams[0];
    final backstep = calcParams[1];
    // final deviation = calcParams[2];

    // Reset
    for (var item in dataList) {
      item.zigzag = null;
    }

    // 1. Find local Highs and Lows in Depth.
    List<int> zagHighs = List.filled(dataList.length, 0);
    List<int> zagLows = List.filled(dataList.length, 0);

    for (int i = depth; i < dataList.length; i++) {
      double valH = dataList[i].high;
      bool isMax = true;
      for (int k = 1; k <= depth; k++) {
        if (dataList[i - k].high > valH) {
          isMax = false;
          break;
        }
      }

      if (isMax) {
        for (int k = 1; k <= backstep; k++) {
          if (i + k < dataList.length && dataList[i + k].high > valH) {
            isMax = false;
            break;
          }
        }
      }
      if (isMax) zagHighs[i] = 1;

      double valL = dataList[i].low;
      bool isMin = true;
      for (int k = 1; k <= depth; k++) {
        if (dataList[i - k].low < valL) {
          isMin = false;
          break;
        }
      }
      if (isMin) {
        for (int k = 1; k <= backstep; k++) {
          if (i + k < dataList.length && dataList[i + k].low < valL) {
            isMin = false;
            break;
          }
        }
      }
      if (isMin) zagLows[i] = 1;
    }

    // 2. Connect
    List<List<int>> pivots = []; // [index, type] (1=High, -1=Low)

    int lastDir = 0;
    int lastIdx = 0;

    // Find first pivot
    for (int i = 0; i < dataList.length; i++) {
      if (zagHighs[i] == 1 && zagLows[i] == 0) {
        lastDir = 1;
        lastIdx = i;
        pivots.add([i, 1]);
        break;
      }
      if (zagLows[i] == 1 && zagHighs[i] == 0) {
        lastDir = -1;
        lastIdx = i;
        pivots.add([i, -1]);
        break;
      }
    }

    for (int i = lastIdx + 1; i < dataList.length; i++) {
      if (lastDir == 1) {
        // We are at a High, valid next is Low.
        if (zagLows[i] == 1) {
          if (zagHighs[i] == 1 && dataList[i].high > dataList[lastIdx].high) {
            // Update High
            pivots.last[0] = i;
            lastIdx = i;
          } else {
            // New Low
            pivots.add([i, -1]);
            lastDir = -1;
            lastIdx = i;
          }
        } else if (zagHighs[i] == 1 &&
            dataList[i].high > dataList[lastIdx].high) {
          // Update High
          pivots.last[0] = i;
          lastIdx = i;
        }
      } else {
        // We are at a Low, valid next is High
        if (zagHighs[i] == 1) {
          if (zagLows[i] == 1 && dataList[i].low < dataList[lastIdx].low) {
            // Update Low
            pivots.last[0] = i;
            lastIdx = i;
          } else {
            // New High
            pivots.add([i, 1]);
            lastDir = 1;
            lastIdx = i;
          }
        } else if (zagLows[i] == 1 && dataList[i].low < dataList[lastIdx].low) {
          // Update Low
          pivots.last[0] = i;
          lastIdx = i;
        }
      }
    }

    // 3. Interpolate
    for (int k = 0; k < pivots.length - 1; k++) {
      int idx1 = pivots[k][0];
      int type1 = pivots[k][1];
      int idx2 = pivots[k + 1][0];

      double val1 = type1 == 1 ? dataList[idx1].high : dataList[idx1].low;
      double val2 = type1 == 1 ? dataList[idx2].low : dataList[idx2].high;

      // Fill exact points
      dataList[idx1].zigzag = val1;
      dataList[idx2].zigzag = val2;

      // Linear Interpolation
      int dist = idx2 - idx1;
      if (dist > 1) {
        double slope = (val2 - val1) / dist;
        for (int j = 1; j < dist; j++) {
          dataList[idx1 + j].zigzag = val1 + slope * j;
        }
      }
    }
    // Last point
    if (pivots.isNotEmpty) {
      int lastI = pivots.last[0];
      int type = pivots.last[1];
      dataList[lastI].zigzag =
          type == 1 ? dataList[lastI].high : dataList[lastI].low;
    }
  }
}
