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

      if (table == null) {
        continue;
      }

      for (final row in table.rows) {
        if (row.length < 4) {
          continue;
        }

        final String? areaCd =
            row[0]?.value?.toString().trim();

        final String? areaNm =
            row[1]?.value?.toString().trim();

        final String? sigunguCd =
            row[2]?.value?.toString().trim();

        final String? sigunguNm =
            row[3]?.value?.toString().trim();

        if (areaNm == null ||
            sigunguNm == null ||
            areaCd == null ||
            sigunguCd == null) {
          continue;
        }

        // ================================================
        // 시도 + 시군구 이름으로 비교
        //
        // 예:
        //
        // areaNm    = 대구광역시
        // sigunguNm = 서구
        //
        // fullRegionName
        //           = 대구광역시 서구
        // ================================================

        final String fullRegionName =
            '$areaNm $sigunguNm';

        if (fullRegionName == regionName.trim()) {
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