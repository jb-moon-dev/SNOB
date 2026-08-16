import 'services/congestion_service.dart';

Future<void> main() async {
  print('');
  print('========================================');
  print('관광지 집중률 API 테스트');
  print('========================================');

  final service = CongestionService();

  try {
    final result = await service.getCongestion(
      areaCd: '26',
      signguCd: '26350',
      touristSpotName: '해운대해수욕장',
    );

    print('');
    print('========================================');
    print('조회 결과');
    print('데이터 수: ${result.length}');
    print('========================================');

    for (int i = 0; i < result.length; i++) {
      print('');
      print('[${i + 1}]');
      print(result[i]);
    }

    print('');
    print('========================================');
    print('테스트 종료');
    print('========================================');
  } catch (e) {
    print('');
    print('========================================');
    print('오류 발생');
    print(e);
    print('========================================');
  }
}