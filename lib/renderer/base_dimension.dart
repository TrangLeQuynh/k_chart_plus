import '../k_chart_widget.dart';

class BaseDimension {
  double _mBaseHeight = 380;
  double _mVolumeHeight = 0;
  double _mSecondaryHeight = 0;
  double _mDisplayHeight = 0;

  double get mVolumeHeight => _mVolumeHeight;
  double get mSecondaryHeight => _mSecondaryHeight;
  double get mDisplayHeight => _mDisplayHeight;

  BaseDimension({
    required double mBaseHeight,
    required bool volHidden,
    required Set<SecondaryState> secondaryStateLi,
  }) {
    _mBaseHeight = mBaseHeight;
    _mVolumeHeight = volHidden != true ? _mBaseHeight * 0.2 : 0;
    _mSecondaryHeight = _mBaseHeight * 0.2;
    _mDisplayHeight = _mBaseHeight + _mVolumeHeight + (_mSecondaryHeight * secondaryStateLi.length);
  }
}
