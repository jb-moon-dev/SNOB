import 'snob/region_data.dart';

void main() {
  print('Region 데이터 테스트 시작');
  print('지역 수: ${regions.length}');

  // 세종 검색
  final sejongRegions = regions.where(
    (region) => region.regionName.contains('세종'),
  ).toList();

  print('');
  print('=== 세종 테스트 ===');
  print('세종 지역 수: ${sejongRegions.length}');

  for (final region in sejongRegions) {
    print('');
    print('지역명: ${region.regionName}');
    print('자연: ${region.nature}');
    print('숨은: ${region.hidden}');
    print('힐링: ${region.healing}');
    print('혼잡도: ${region.congestion}');
  }
}