import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_plus/entity/k_line_entity.dart';
import 'package:k_chart_plus/indicator/indicator_template.dart';

void main() {
  test('ZigZag Calculation Logic', () {
    // Create synthetic data
    // A simple V shape: 10, 20, 10
    List<KLineEntity> dataList = [
      KLineEntity.fromCustom(
          open: 10, high: 10, low: 10, close: 10, vol: 100, time: 1000),
      KLineEntity.fromCustom(
          open: 12, high: 15, low: 12, close: 15, vol: 100, time: 2000),
      KLineEntity.fromCustom(
          open: 20, high: 20, low: 18, close: 20, vol: 100, time: 3000), // Peak
      KLineEntity.fromCustom(
          open: 15, high: 15, low: 15, close: 15, vol: 100, time: 4000),
      KLineEntity.fromCustom(
          open: 10,
          high: 10,
          low: 10,
          close: 10,
          vol: 100,
          time: 5000), // Valley
      KLineEntity.fromCustom(
          open: 12, high: 12, low: 12, close: 12, vol: 100, time: 6000),
    ];

    // Params: Depth=2, Backstep=1, Deviation=1(%)?
    // We implemented strictly High/Low checks in Depth logic.
    // Let's us small params for small data.

    // Depth=2 means we check 2 bars back.
    // Index 2 (High=20) is max of [0, 1, 2] -> 10, 15, 20. Yes.
    // Index 4 (Low=10) is min of [2, 3, 4] -> 18, 15, 10. Yes.

    ZigZagIndicator zigzag =
        ZigZagIndicator(calcParams: [2, 0, 0]); // Depth 2, strict
    zigzag.calc(dataList);

    // Index 0: Start point (10)
    // Index 2: Peak (20)
    // Index 4: Valley (10)

    // Interpolation:
    // Index 1 should be mid point between 10 (idx 0) and 20 (idx 2).
    // Steps = 2. Slope = (20-10)/2 = 5.
    // Index 1 zigzag = 10 + 5 = 15.

    // Because Depth=2, the first two bars (idx 0, 1) cannot be confirmed as pivots by the loop.
    // So zigzag for 0 and 1 might be null.
    expect(dataList[0].zigzag, null);
    expect(dataList[1].zigzag, null);

    // Index 2 is the first Peak
    expect(dataList[2].zigzag, 20.0);

    // Index 4 is the Valley
    expect(dataList[4].zigzag, 10.0);

    // Interpolation between 20 (idx2) and 10 (idx4)
    // Distance = 2. Slope = (10-20)/2 = -5.
    // idx3 = 20 - 5 = 15.
    expect(dataList[3].zigzag, 15.0);
  });
}
