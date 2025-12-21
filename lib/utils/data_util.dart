import 'package:k_chart_plus/indicator/indicator_template.dart';
import '../entity/index.dart';

class DataUtil {
  static calculateAll(List<KLineEntity> dataList, List<MainIndicator> mainLi, List<SecondaryIndicator> secondaryLi) {
    calcVolumeMA(dataList);
    calculateIndicators(dataList, mainLi, secondaryLi);
  }

  static calculateIndicators(List<KLineEntity> dataList, List<MainIndicator> mainLi, List<SecondaryIndicator> secondaryLi) {
    /// calculate main state
    mainLi.forEach((e) {
      e.calc(dataList);
    });

    /// calculate secondary state
    secondaryLi.forEach((e) {
      e.calc(dataList);
    });
  }

  static calculateIndicator(List<KLineEntity> dataList, IndicatorTemplate indicator) {
    indicator.calc(dataList);
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }
}
