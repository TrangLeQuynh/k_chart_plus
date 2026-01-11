import 'package:flutter/material.dart';

class KChartController extends ChangeNotifier {
  // 0: default, 1: reset, 2: zoom, 3: scroll
  // Map<String, dynamic> params = {};
  int _action = 0;
  int get action => _action;

  double _zoom = 1.0;
  double get zoom => _zoom;

  void reset() {
    _action = 1;
    notifyListeners();
  }

  void zoomIn() {
    _action = 2;
    _zoom = 0.1; // Zoom step
    notifyListeners();
  }

  void zoomOut() {
    _action = 2;
    _zoom = -0.1;
    notifyListeners();
  }
}
