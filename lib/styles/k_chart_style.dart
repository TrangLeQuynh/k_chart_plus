import 'package:flutter/material.dart' show Color;

/// KChartColors
///
/// Note:
/// If you need to apply multi theme, you need to change at least the colors related to the text, border and background color
/// Ex:
/// Background: bgColor, selectFillColor
/// Border
/// Text
///
class KChartColors {
  /// the background color of base chart
  final Color bgColor;

  /// Line chart
  final Color kLineColor;
  final List<Color> kLineFillColors;

  final Color ma5Color;
  final Color ma10Color;

  final Color upColor;
  final Color dnColor;

  final Color volColor;
  final Color volUpColor;
  final Color volDnColor;

  /// default text color: apply for text at grid
  final Color defaultTextColor;

  /// color of the current price
  final Color nowPriceUpColor;
  final Color nowPriceDnColor;

  /// trend color
  final Color trendLineColor;

  ///value border color after selection
  final Color selectBorderColor;

  ///background color when value selected
  final Color selectFillColor;

  ///color of grid
  final Color gridColor;

  /// color of the horizontal & vertical cross line
  final Color crossColor;

  /// text color
  final Color crossTextColor;

  ///The color of the maximum and minimum values in the current display
  final Color maxColor;
  final Color minColor;

  /// constructor chart color
  const KChartColors({
    this.bgColor = const Color(0xffffffff),
    this.kLineColor = const Color(0xff217AFF),
    this.kLineFillColors = const [
      Color(0x80217aff),
      Color(0x00217AFF),
    ],

    ///
    this.ma5Color = const Color(0xFFFFC634),
    this.ma10Color = const Color(0xff35cdac),
    this.upColor = const Color(0xFF14AD8F),
    this.dnColor = const Color(0xFFD5405D),
    this.volColor = const Color(0xff2f8fd5),
    this.volUpColor = const Color(0xFF14AD8F),
    this.volDnColor = const Color(0xFFD5405D),
    this.defaultTextColor = const Color(0xFF909196),
    this.nowPriceUpColor = const Color(0xFF14AD8F),
    this.nowPriceDnColor = const Color(0xFFD5405D),

    /// trend color
    this.trendLineColor = const Color(0xFFF89215),

    ///value border color after selection
    this.selectBorderColor = const Color(0xFF222223),

    ///background color when value selected
    this.selectFillColor = const Color(0xffffffff),

    ///color of grid
    this.gridColor = const Color(0xFFD1D3DB),

    ///color of annotation content
    this.crossColor = const Color(0xFF191919),
    this.crossTextColor = const Color(0xFF222223),

    ///The color of the maximum and minimum values in the current display
    this.maxColor = const Color(0xFF222223),
    this.minColor = const Color(0xFF222223),
  });
}

class KChartStyle {
  final double topPadding = 20.0;

  final double bottomPadding = 16.0;

  final double childPadding = 12.0;

  final double space = 4.0;

  ///point-to-point distance
  final double pointWidth = 11.0;

  ///candle width
  final double candleWidth = 8.5;
  final double candleLineWidth = 1.0;

  ///vol column width
  final double volWidth = 8.5;

  ///vertical-horizontal cross line width
  final double crossWidth = 0.8;

  ///(line length - space line - thickness) of the current price
  // final double nowPriceLineLength = 4.5;
  // final double nowPriceLineSpan = 3.5;
  final double nowPriceLineWidth = 0.8;

  /// Border width : apply for cross & now price
  final double borderWidth = 0.5;

  final int gridRows = 4;
  final int gridColumns = 4;

  ///customize the time below
  final List<String>? dateTimeFormat;

  const KChartStyle([this.dateTimeFormat]);
}
