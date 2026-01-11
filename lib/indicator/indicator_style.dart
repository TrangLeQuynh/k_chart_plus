part of 'indicator_template.dart';

class IndicatorStyle {
  final double lineWidth;
  final double strokeWidth;

  const IndicatorStyle({
    this.lineWidth = 1.0,
    this.strokeWidth = 0.8,
  });
}

class MAStyle extends IndicatorStyle {
  final List<Color> maColors;
  const MAStyle({
    this.maColors = const [
      Color(0xFFFFC634),
      Color(0xff35cdac),
      Color(0xffb48ee3),
      Color(0xffE11D74),
      Color(0xFFF7931A),
      Color(0xFF127ECC),
    ],
  });

  /// get MA color via index
  Color getMAColor(int index) {
    if (index >= maColors.length) {
      return maColors[index % maColors.length];
    }
    return maColors[index];
  }
}

class BOLLStyle extends IndicatorStyle {
  final Color bollColor;
  final Color ubColor;
  final Color lbColor;
  final Color fillColor;

  const BOLLStyle({
    this.bollColor = const Color(0xFFF7931A),
    this.ubColor = const Color(0xFFFFC634),
    this.lbColor = const Color(0xFFFFC634),
    this.fillColor = const Color(0x12FFC634),
  });
}

class SARStyle extends IndicatorStyle {
  final Color sarColor;

  final double radius;

  const SARStyle({
    this.sarColor = const Color(0xFFFFC634),
    this.radius = 2.0,
    super.strokeWidth = 0.8,
  });
}

class CCIStyle extends IndicatorStyle {
  final Color cciColor;

  const CCIStyle({
    this.cciColor = const Color(0xFFFFC634),
  });
}

class RSIStyle extends IndicatorStyle {
  final Color rsiColor;

  const RSIStyle({
    this.rsiColor = const Color(0xFFFFC634),
  });
}

class WRStyle extends IndicatorStyle {
  final Color wrColor;

  const WRStyle({
    this.wrColor = const Color(0xFFFFC634),
  });
}

class KDJStyle extends IndicatorStyle {
  final Color kColor;
  final Color dColor;
  final Color jColor;

  const KDJStyle({
    this.kColor = const Color(0xFFFFC634),
    this.dColor = const Color(0xff35cdac),
    this.jColor = const Color(0xffb48ee3),
  });
}

class MACDStyle extends IndicatorStyle {
  final Color upColor;
  final Color dnColor;

  final Color macdColor;
  final Color difColor;
  final Color deaColor;

  final double macdWidth;

  const MACDStyle({
    this.upColor = const Color(0xFF14AD8F),
    this.dnColor = const Color(0xFFD5405D),
    this.macdColor = const Color(0xFFFFC634),
    this.difColor = const Color(0xff35cdac),
    this.deaColor = const Color(0xffb48ee3),
    this.macdWidth = 8.5,
  });
}

class ZigZagStyle extends IndicatorStyle {
  final Color zigzagColor;

  const ZigZagStyle({
    this.zigzagColor = const Color(0xFFFFC634),
    super.lineWidth = 1.0,
  });
}
