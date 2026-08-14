import 'dart:convert';
import 'package:flutter/services.dart';

class CourseCongestionData {
  final String cd;
  final String name;
  final double absoluteScore;
  final double normalCompare;
  final String levelStr;

  CourseCongestionData({
    required this.cd,
    required this.name,
    required this.absoluteScore,
    required this.normalCompare,
    required this.levelStr,
  });
}

class CongestionService {
  final Map<String, CourseCongestionData> _dataByCode = {};
  final Map<String, CourseCongestionData> _dataByName = {};

  Future<void> loadData() async {
    final csvString =
        await rootBundle.loadString('congestion_final.csv');

    final lines = const LineSplitter().convert(csvString);

    _dataByCode.clear();
    _dataByName.clear();

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final cols = lines[i].split(',');

      if (cols.length < 8) continue;

      final cd = cols[0].trim();
      final name = cols[1].trim();

      final data = CourseCongestionData(
        cd: cd,
        name: name,
        absoluteScore:
            double.tryParse(cols[6].trim()) ?? 0,
        normalCompare:
            double.tryParse(cols[4].trim()) ?? 0,
        levelStr: cols[7].trim(),
      );

      if (cd.isNotEmpty) {
        _dataByCode[cd] = data;
      }

      _dataByName[name] = data;
    }
  }

  CourseCongestionData? getByCode(String code) {
    return _dataByCode[code];
  }

  CourseCongestionData? getByName(String name) {
    return _dataByName[name];
  }

  bool isCrowded(String code) {
    final data = getByCode(code);

    if (data == null) {
      return false;
    }

    return data.absoluteScore >= 60;
  }
}