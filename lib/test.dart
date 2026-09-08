import 'dart:io';

import 'package:excel/excel.dart';
import 'package:snob/services/tourism_api_service.dart';

Future<void> main() async {
  print('');
  print('==========================================');
  print('SNOB TourAPI 지역 코드 XLSX 생성');
  print('==========================================');

  // ============================================================
  // 결과 저장
  // ============================================================

  final List<Map<String, String>> result = [];

  // ============================================================
  // 1. 시도 조회
  // ============================================================

  print('');
  print('시도 코드 조회 중...');

  final regions =
      await TourismApiService.getRegions();

  print(
    '조회된 시도 수 : ${regions.length}개',
  );

  if (regions.isEmpty) {
    print('❌ 시도 데이터를 가져오지 못했습니다.');
    return;
  }

  // ============================================================
  // 2. 시도 → 시군구 조회
  // ============================================================

  for (int i = 0;
      i < regions.length;
      i++) {
    final String regionCode =
        regions[i]['code'] ?? '';

    final String regionName =
        regions[i]['name'] ?? '';

    print('');
    print(
      '[${i + 1}/${regions.length}] '
      '$regionCode / $regionName',
    );

    final sigungus =
        await TourismApiService.getSigungus(
      regionCode,
    );

    print(
      '시군구 : ${sigungus.length}개',
    );

    // ----------------------------------------------------------
    // 시군구 데이터 저장
    // ----------------------------------------------------------

    for (final sigungu in sigungus) {
      final String sigunguCode =
          sigungu['code'] ?? '';

      final String sigunguName =
          sigungu['name'] ?? '';

      if (sigunguCode.isEmpty ||
          sigunguName.isEmpty) {
        continue;
      }

      result.add({
        'regionCode': regionCode,
        'regionName': regionName,
        'sigunguCode': sigunguCode,
        'sigunguName': sigunguName,
      });
    }
  }

  // ============================================================
  // 3. XLSX 생성
  // ============================================================

  print('');
  print('==========================================');
  print('XLSX 생성');
  print('==========================================');

  final Excel excel =
      Excel.createExcel();

  final Sheet sheet =
      excel['TourAPI_지역코드'];

  // ------------------------------------------------------------
  // 헤더
  // ------------------------------------------------------------

  final headers = [
    'regionCode',
    'regionName',
    'sigunguCode',
    'sigunguName',
  ];

  for (int col = 0;
      col < headers.length;
      col++) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      ),
      TextCellValue(
        headers[col],
      ),
    );
  }

  // ------------------------------------------------------------
  // 데이터
  // ------------------------------------------------------------

  for (int row = 0;
      row < result.length;
      row++) {
    final data = result[row];

    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: row + 1,
      ),
      TextCellValue(
        data['regionCode'] ?? '',
      ),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: 1,
        rowIndex: row + 1,
      ),
      TextCellValue(
        data['regionName'] ?? '',
      ),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: 2,
        rowIndex: row + 1,
      ),
      TextCellValue(
        data['sigunguCode'] ?? '',
      ),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: 3,
        rowIndex: row + 1,
      ),
      TextCellValue(
        data['sigunguName'] ?? '',
      ),
    );
  }

  // ============================================================
  // 4. 열 너비
  // ============================================================

  sheet.setColumnWidth(
    0,
    15,
  );

  sheet.setColumnWidth(
    1,
    20,
  );

  sheet.setColumnWidth(
    2,
    18,
  );

  sheet.setColumnWidth(
    3,
    25,
  );

  // ============================================================
  // 5. 저장
  // ============================================================

  final List<int>? bytes =
      excel.save();

  if (bytes == null) {
    print('');
    print('❌ XLSX 생성 실패');
    return;
  }

  final String filePath =
      '${Directory.current.path}'
      '${Platform.pathSeparator}'
      'tourapi_region_codes.xlsx';

  final File file =
      File(filePath);

  await file.writeAsBytes(
    bytes,
  );

  // ============================================================
  // 6. 완료
  // ============================================================

  print('');
  print('==========================================');
  print('✅ XLSX 생성 완료');
  print('==========================================');

  print(
    '전체 시군구 수 : ${result.length}개',
  );

  print(
    '파일 위치 : $filePath',
  );

  print('');
  print('엑셀 컬럼');
  print(
    'regionCode | regionName | '
    'sigunguCode | sigunguName',
  );

  print('');
  print('==========================================');
  print('테스트 종료');
  print('==========================================');
}