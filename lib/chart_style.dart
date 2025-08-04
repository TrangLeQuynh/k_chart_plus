import 'package:flutter/material.dart' show Color;

/// ChartColors
///
/// Note:
/// If you need to apply multi theme, you need to change at least the colors related to the text, border and background color
/// Ex:
/// Background: bgColor, selectFillColor
/// Border
/// Text
///
class ChartColors {
  /// the background color of base chart
  final Color bgColor;

  final Color kLineColor;

  ///
  final Color lineFillColor;

  ///
  final Color lineFillInsideColor;

  final Color ma5Color;
  final Color ma10Color;
  final Color upColor;
  final Color dnColor;
  final Color volColor;

  /// default text color: apply for text at grid
  final Color defaultTextColor;

  /// color of the current price
  final Color nowPriceUpColor;
  final Color nowPriceDnColor;
  final Color nowPriceTextColor;

  /// trend color
  final Color trendLineColor;

  /// depth color
  final Color depthBuyColor; //upColor
  final Color depthBuyPathColor;
  final Color depthSellColor; //dnColor
  final Color depthSellPathColor;

  ///value border color after selection
  final Color selectBorderColor;

  ///background color when value selected
  final Color selectFillColor;

  ///color of grid
  final Color gridColor;

  ///color of annotation content
  final Color infoWindowNormalColor;
  final Color infoWindowTitleColor;
  final Color infoWindowUpColor;
  final Color infoWindowDnColor;

  /// color of the horizontal & vertical cross line
  final Color crossColor;

  /// text color
  final Color crossTextColor;

  ///The color of the maximum and minimum values in the current display
  final Color maxColor;
  final Color minColor;

  /// constructor chart color
  const ChartColors({
    this.bgColor = const Color(0xffffffff),
    this.kLineColor = const Color(0xff4C86CD),

    ///
    this.lineFillColor = const Color(0x554C86CD),

    ///
    this.lineFillInsideColor = const Color(0x00000000),

    ///
    this.ma5Color = const Color(0xFFFFC634),
    this.ma10Color = const Color(0xff35cdac),
    this.upColor = const Color(0xFF14AD8F),
    this.dnColor = const Color(0xFFD5405D),
    this.volColor = const Color(0xff2f8fd5),
    this.defaultTextColor = const Color(0xFF909196),
    this.nowPriceUpColor = const Color(0xFF14AD8F),
    this.nowPriceDnColor = const Color(0xFFD5405D),
    this.nowPriceTextColor = const Color(0xffffffff),

    /// trend color
    this.trendLineColor = const Color(0xFFF89215),

    ///depth color
    this.depthBuyColor = const Color(0xFF14AD8F),
    this.depthBuyPathColor = const Color(0x3314AD8F),
    this.depthSellColor = const Color(0xFFD5405D),
    this.depthSellPathColor = const Color(0x33D5405D),

    ///value border color after selection
    this.selectBorderColor = const Color(0xFF222223),

    ///background color when value selected
    this.selectFillColor = const Color(0xffffffff),

    ///color of grid
    this.gridColor = const Color(0xFFD1D3DB),

    ///color of annotation content
    this.infoWindowNormalColor = const Color(0xFF222223),
    this.infoWindowTitleColor = const Color(0xFF4D4D4E), //0xFF707070
    this.infoWindowUpColor = const Color(0xFF14AD8F),
    this.infoWindowDnColor = const Color(0xFFD5405D),
    this.crossColor = const Color(0xFF191919),
    this.crossTextColor = const Color(0xFF222223),

    ///The color of the maximum and minimum values in the current display
    this.maxColor = const Color(0xFF222223),
    this.minColor = const Color(0xFF222223),
  });
}

class ChartStyle {
  final double topPadding = 20.0;

  final double bottomPadding = 20.0;

  final double childPadding = 12.0;

  ///point-to-point distance
  final double pointWidth = 11.0;

  ///candle width
  final double candleWidth = 8.5;
  final double candleLineWidth = 1.0;

  ///vol column width
  final double volWidth = 8.5;

  ///macd column width
  final double macdWidth = 8.5;

  ///vertical-horizontal cross line width
  final double crossWidth = 0.5;

  ///(line length - space line - thickness) of the current price
  final double nowPriceLineLength = 4.5;
  final double nowPriceLineSpan = 3.5;
  final double nowPriceLineWidth = 1;

  final int gridRows = 4;
  final int gridColumns = 4;

  ///customize the time below
  final List<String>? dateTimeFormat;

  const ChartStyle([this.dateTimeFormat]);
}
