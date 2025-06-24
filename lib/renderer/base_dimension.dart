import '../k_chart_widget.dart';

/// Base Dimension
class BaseDimension {
  // the height of base chart
  double _mBaseHeight = 380;
  // default: 0
  // the height of volume chart
  double _mVolumeHeight = 0;
  // default: 0
  // the height of a secondary chart
  double _mSecondaryHeight = 0;
  double _totalSecondaryHeight = 0;

  double _mLabelHeight = 12;
  double _totalLabelHeight = 12;

  // total height of chart: _mBaseHeight + _mVolumeHeight + (_mSecondaryHeight * n)
  // n : number of secondary charts
  //
  double _mDisplayHeight = 0;

  // getter the vol height
  double get mVolumeHeight => _mVolumeHeight;

  // getter the secondary height
  double get mSecondaryHeight => _mSecondaryHeight;
  double get totalSecondaryHeight => _totalSecondaryHeight;

  double get mLabelHeight => _mLabelHeight;
  double get totalLabelHeight => _totalLabelHeight;

  // getter the total height
  double get mDisplayHeight => _mDisplayHeight;

  /// constructor
  ///
  /// BaseDimension
  /// set _mBaseHeight
  /// compute value of _mVolumeHeight, _mSecondaryHeight, _mDisplayHeight
  BaseDimension({
    required double mBaseHeight,
    required bool volHidden,
    required Set<SecondaryState> secondaryStateLi,
    required Set<MainState> mainStateLi,
  }) {
    _mBaseHeight = mBaseHeight;
    _mVolumeHeight = volHidden != true ? _mBaseHeight * 0.2 : 0;
    _mSecondaryHeight = _mBaseHeight * 0.2;
    _totalSecondaryHeight = _mSecondaryHeight * secondaryStateLi.length;
    _totalLabelHeight = _mLabelHeight * mainStateLi.length;

    _mDisplayHeight = _mBaseHeight +
        _mVolumeHeight +
        _totalSecondaryHeight +
        _totalLabelHeight;
  }
}
