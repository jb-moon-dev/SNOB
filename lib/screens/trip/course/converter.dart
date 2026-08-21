import 'package:flutter/services.dart';
import 'package:excel/excel.dart';

class RegionCode {
  final String areaCd;
  final String sigunguCd;

  const RegionCode({
    required this.areaCd,
    required this.sigunguCd,
  });
}

class RegionCodeConverter {
  static const String excelPath =
      'assets/region_codes.xlsx';

  static Future<RegionCode?> getRegionCode(
    String regionName,
  ) async {
    final data = await rootBundle.load(excelPath);

    final bytes = data.buffer.asUint8List();

    final excel = Excel.decodeBytes(bytes);

    for (final sheet in excel.tables.keys) {
      final table = excel.tables[sheet];

      if (table == null) continue;

      for (final row in table.rows) {
        if (row.length < 4) continue;

        final areaCd = row[0]?.value?.toString();
        final areaNm = row[1]?.value?.toString();
        final sigunguCd = row[2]?.value?.toString();
        final sigunguNm = row[3]?.value?.toString();

        if (areaNm == null ||
            sigunguNm == null ||
            areaCd == null ||
            sigunguCd == null) {
          continue;
        }

        // RegionVector에는 "강릉시", "종로구"처럼
        // 시군구 이름만 저장되어 있으므로 시군구명으로 비교
        if (sigunguNm == regionName) {
          return RegionCode(
            areaCd: areaCd,
            sigunguCd: sigunguCd,
          );
        }
      }
    }

    return null;
  }
}