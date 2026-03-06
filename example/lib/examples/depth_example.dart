import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

class DepthExample extends StatefulWidget {
  const DepthExample({super.key});

  @override
  State<DepthExample> createState() => _DepthExampleState();
}

class _DepthExampleState extends State<DepthExample> {
  bool showLoading = true;
  List<DepthEntity>? _bids, _asks;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/depth.json').then((result) {
      final parseJson = json.decode(result);
      final tick = parseJson['tick'] as Map<String, dynamic>;
      final List<DepthEntity> bids = (tick['bids'] as List<dynamic>)
          .map<DepthEntity>(
              (item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      final List<DepthEntity> asks = (tick['asks'] as List<dynamic>)
          .map<DepthEntity>(
              (item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      initDepth(bids, asks);
    });
  }

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;
    _bids = [];
    _asks = [];
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    for (var item in bids.reversed) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    for (var item in asks) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Depth chart')),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: DepthChart(
              _bids!,
              _asks!,
              const DepthChartColors(),
              chartTranslations: const DepthChartTranslations(
                price: 'Price',
                amount: 'Amount',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
