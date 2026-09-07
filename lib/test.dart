import 'package:snob/region_mapping/region_mapping_service.dart';
import 'package:snob/services/congestion_service.dart';

Future<void> main() async {
  final CongestionService congestionService =
      CongestionService();

  // ============================================================
  // 테스트할 현재 지역
  // ============================================================

  final List<Map<String, String>> testRegions = [
    // ------------------------------------------------------------
    // 인천
    // ------------------------------------------------------------

    {
      'regionCode': '23',
      'sigunguCode': '11',
      'regionName': '인천광역시 영종구',
    },
    {
      'regionCode': '23',
      'sigunguCode': '11',
      'regionName': '인천광역시 제물포구',
    },
    {
      'regionCode': '23',
      'sigunguCode': '26',
      'regionName': '인천광역시 서해구',
    },
    {
      'regionCode': '23',
      'sigunguCode': '26',
      'regionName': '인천광역시 검단구',
    },

    // ------------------------------------------------------------
    // 화성시
    // ------------------------------------------------------------

    {
      'regionCode': '41',
      'sigunguCode': '00',
      'regionName': '경기도 화성시 만세구',
    },
    {
      'regionCode': '41',
      'sigunguCode': '00',
      'regionName': '경기도 화성시 효행구',
    },
    {
      'regionCode': '41',
      'sigunguCode': '00',
      'regionName': '경기도 화성시 병점구',
    },
    {
      'regionCode': '41',
      'sigunguCode': '00',
      'regionName': '경기도 화성시 동탄구',
    },

    // ------------------------------------------------------------
    // 전남광주통합특별시 - 기존 광주광역시
    // ------------------------------------------------------------

    {
      'regionCode': '24',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 광산구',
    },
    {
      'regionCode': '24',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 동구',
    },
    {
      'regionCode': '24',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 서구',
    },
    {
      'regionCode': '24',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 남구',
    },
    {
      'regionCode': '24',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 북구',
    },

    // ------------------------------------------------------------
    // 전남광주통합특별시 - 기존 전라남도
    // ------------------------------------------------------------

    {
      'regionCode': '46',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 목포시',
    },
    {
      'regionCode': '46',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 여수시',
    },
    {
      'regionCode': '46',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 순천시',
    },
    {
      'regionCode': '46',
      'sigunguCode': '00',
      'regionName': '전남광주통합특별시 나주시',
    },
  ];

  // ============================================================
  // 1. 지역별 매핑 확인
  // ============================================================

  print('');
  print('==========================================');
  print('SNOB 지역 매핑 + API 전체 테스트');
  print('==========================================');
  print('테스트 지역 : ${testRegions.length}개');
  print('');

  // ============================================================
  // 같은 집중률 API 지역은 한 번만 조회하기 위한 Map
  //
  // 예:
  // 영종구   → 28 / 28110
  // 제물포구 → 28 / 28110
  //
  // 같은 API 지역이므로 실제 API 호출은 한 번만 수행
  // ============================================================

  final Map<String, List<String>> mappedRegions = {};

  for (final Map<String, String> region in testRegions) {
    final String regionCode =
        region['regionCode']!;

    final String sigunguCode =
        region['sigunguCode']!;

    final String regionName =
        region['regionName']!;

    final List<RegionQuery> queries =
        RegionMappingService.getQueryRegions(
      regionCode: regionCode,
      sigunguCode: sigunguCode,
      regionName: regionName,
    );

    print('------------------------------------------');
    print('현재 지역 : $regionName');

    if (queries.isEmpty) {
      print('❌ 매핑 결과 없음');
      print('');
      continue;
    }

    for (final RegionQuery query in queries) {
      print('→ 집중률 areaCd   : ${query.areaCd}');
      print('→ 집중률 signguCd : ${query.signguCd}');
      print('→ 이유            : ${query.reason}');

      final String key =
          '${query.areaCd}|${query.signguCd}';

      mappedRegions.putIfAbsent(
        key,
        () => [],
      );

      mappedRegions[key]!.add(
        regionName,
      );
    }

    print('');
  }

  // ============================================================
  // 2. 실제 API 조회
  // ============================================================

  print('');
  print('==========================================');
  print('실제 집중률 API 조회');
  print('==========================================');
  print('중복 지역 코드는 1번만 조회합니다.');
  print('');

  int successCount = 0;
  int emptyCount = 0;
  int errorCount = 0;

  for (final MapEntry<String, List<String>> entry
      in mappedRegions.entries) {
    final String key = entry.key;

    final List<String> currentRegions =
        entry.value;

    final List<String> code =
        key.split('|');

    final String areaCd = code[0];
    final String signguCd = code[1];

    print('');
    print('==========================================');
    print('집중률 API 지역');
    print('==========================================');
    print('areaCd   : $areaCd');
    print('signguCd : $signguCd');
    print('');
    print('연결되는 현재 지역');

    for (final String regionName
        in currentRegions) {
      print(' - $regionName');
    }

    print('');
    print('API 조회 시작');

    try {
      final List<Map<String, dynamic>> data =
          await congestionService.getAllCongestion(
        areaCd: areaCd,
        signguCd: signguCd,
      );

      // ----------------------------------------------------------
      // 데이터가 없는 경우
      // ----------------------------------------------------------

      if (data.isEmpty) {
        print('');
        print('⚠️ 조회 데이터 없음');

        emptyCount++;

        continue;
      }

      // ----------------------------------------------------------
      // 데이터가 있는 경우
      // ----------------------------------------------------------

      successCount++;

      print('');
      print('✅ 조회 성공');
      print('데이터 개수 : ${data.length}개');

      // ----------------------------------------------------------
      // 실제 API 지역 정보
      // ----------------------------------------------------------

      final Set<String> responseRegions = {};

      for (final Map<String, dynamic> item
          in data) {
        final String responseAreaCd =
            item['areaCd']?.toString().trim() ?? '';

        final String responseSignguCd =
            item['signguCd']?.toString().trim() ?? '';

        final String responseAreaNm =
            item['areaNm']?.toString().trim() ?? '';

        final String responseSignguNm =
            item['signguNm']?.toString().trim() ?? '';

        responseRegions.add(
          '$responseAreaCd | '
          '$responseSignguCd | '
          '$responseAreaNm | '
          '$responseSignguNm',
        );
      }

      print('');
      print('실제 API 지역');

      for (final String region
          in responseRegions) {
        print(' - $region');
      }

      // ----------------------------------------------------------
      // 관광지 샘플
      // ----------------------------------------------------------

      print('');
      print('관광지 샘플');

      final int sampleCount =
          data.length > 5
              ? 5
              : data.length;

      for (int i = 0;
          i < sampleCount;
          i++) {
        final Map<String, dynamic> item =
            data[i];

        print(
          ' ${i + 1}. '
          '${item['tAtsNm']} '
          '| 집중률: ${item['cnctrRate']} '
          '| 기준일: ${item['baseYmd']}',
        );
      }
    } catch (e) {
      print('');
      print('❌ API 조회 오류');
      print('오류 : $e');

      errorCount++;
    }
  }

  // ============================================================
  // 3. 최종 결과
  // ============================================================

  print('');
  print('');
  print('==========================================');
  print('최종 테스트 결과');
  print('==========================================');

  print(
    '테스트 현재 지역 : '
    '${testRegions.length}개',
  );

  print(
    '고유 API 지역    : '
    '${mappedRegions.length}개',
  );

  print(
    '조회 성공        : '
    '$successCount개',
  );

  print(
    '데이터 없음      : '
    '$emptyCount개',
  );

  print(
    'API 오류         : '
    '$errorCount개',
  );

  print('');

  // ============================================================
  // 4. 매핑 결과 요약
  // ============================================================

  print('==========================================');
  print('매핑 결과 요약');
  print('==========================================');

  for (final MapEntry<String, List<String>> entry
      in mappedRegions.entries) {
    final List<String> code =
        entry.key.split('|');

    final String areaCd = code[0];
    final String signguCd = code[1];

    print('');
    print(
      '집중률 API : '
      '$areaCd / $signguCd',
    );

    print('현재 지역 :');

    for (final String regionName
        in entry.value) {
      print(' - $regionName');
    }
  }

  print('');
  print('==========================================');
  print('테스트 종료');
  print('==========================================');
}