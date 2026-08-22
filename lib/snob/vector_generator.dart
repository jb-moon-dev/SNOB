import 'spot_vector.dart';
import 'region_vector.dart';
import 'tourism_spot.dart';

class VectorGenerator {
  // ============================================================
  // TourismSpot → SpotVector
  // ============================================================

  static SpotVector generateSpotVector(
    TourismSpot spot,
  ) {
    double nature = 50;
    double hidden = 50;
    double healing = 50;

    // ============================================================
    // 🌿 1차 분류 (lclsSystm1)
    // ============================================================

    switch (spot.lclsSystm1) {
      // 자연관광
      case "NA":
        nature += 30;
        healing += 20;
        break;

      // 역사관광
      case "HS":
        hidden += 20;
        healing += 20;
        break;

      // 체험관광
      case "EX":
        hidden += 10;
        healing += 10;
        break;

      // 레저스포츠
      case "VE":
        nature += 20;
        healing -= 10;
        break;
    }

    // ============================================================
    // 🔍 2차 분류 (lclsSystm2)
    // ============================================================

    switch (spot.lclsSystm2) {
      // 산/산림
      case "NA01":
        nature += 20;
        healing += 20;
        hidden += 10;
        break;

      // 바다/해변
      case "NA02":
        nature += 30;
        healing += 20;
        break;

      // 자연휴양
      case "NA04":
        nature += 20;
        healing += 30;
        hidden += 10;
        break;

      // 역사
      case "HS01":
        hidden += 20;
        healing += 10;
        break;

      // 자연 경관
      case "HS03":
        nature += 20;
        healing += 20;
        hidden += 20;
        break;

      // 체험
      case "EX07":
        hidden += 20;
        break;

      // 레저
      case "VE03":
        nature += 10;
        break;
    }

    // ============================================================
    // 🌙 3차 분류 (lclsSystm3)
    // ============================================================

    switch (spot.lclsSystm3) {
      // 산
      case "NA010100":
        nature += 20;
        healing += 20;
        break;

      // 폭포
      case "NA010300":
        nature += 20;
        healing += 20;
        break;

      // 약수터
      case "NA010500":
        healing += 30;
        break;

      // 항구
      case "NA020700":
        nature += 20;
        break;

      // 해변
      case "NA020900":
        nature += 30;
        healing += 20;
        break;

      // 온천
      case "HS030100":
        healing += 40;
        break;

      // 문화재
      case "HS010900":
        hidden += 20;
        healing += 10;
        break;
    }

    // ============================================================
    // 범위 제한
    // ============================================================

    nature = nature.clamp(0, 100).toDouble();
    hidden = hidden.clamp(0, 100).toDouble();
    healing = healing.clamp(0, 100).toDouble();

    // ============================================================
    // SpotVector 생성
    // ============================================================

    return SpotVector(
      spotName: spot.title,
      regionName: extractRegion(spot.address),
      nature: nature,
      hidden: hidden,
      healing: healing,
      congestion: 0,
    );
  }

  // ============================================================
  // 주소 → 지역명 추출
  //
  // 예:
  // "서울특별시 종로구 ..." → "서울특별시 종로구"
  // "부산광역시 해운대구 ..." → "부산광역시 해운대구"
  //
  // 추천 시스템에서는 같은 시군구끼리 묶기 위해 사용
  // ============================================================

  static String extractRegion(
    String address,
  ) {
    if (address.trim().isEmpty) {
      return "";
    }

    final parts = address
        .trim()
        .split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return address.trim();
    }

    String sido = parts[0];
    String sigungu = parts[1];

    // ============================================================
    // 시도명 표준화
    // ============================================================

    switch (sido) {
      case "서울":
        sido = "서울특별시";
        break;

      case "부산":
        sido = "부산광역시";
        break;

      case "대구":
        sido = "대구광역시";
        break;

      case "인천":
        sido = "인천광역시";
        break;

      case "광주":
        sido = "광주광역시";
        break;

      case "대전":
        sido = "대전광역시";
        break;

      case "울산":
        sido = "울산광역시";
        break;

      case "세종":
        sido = "세종특별자치시";
        break;

      case "경기":
        sido = "경기도";
        break;

      case "강원":
        sido = "강원특별자치도";
        break;

      case "충북":
        sido = "충청북도";
        break;

      case "충남":
        sido = "충청남도";
        break;

      case "전북":
        sido = "전북특별자치도";
        break;

      case "전남":
        sido = "전라남도";
        break;

      case "경북":
        sido = "경상북도";
        break;

      case "경남":
        sido = "경상남도";
        break;

      case "제주":
        sido = "제주특별자치도";
        break;
    }

    return "$sido $sigungu";
  }

  // ============================================================
  // SpotVector → RegionVector
  //
  // 같은 지역의 관광지 SpotVector들을 평균하여
  // 지역 성향 벡터를 생성한다.
  //
  // congestion은 현재 SpotVector에서 사용하지 않으므로
  // 기본값 0을 유지한다.
  // 실제 혼잡도 데이터 연결은 별도 단계에서 처리한다.
  // ============================================================

  static List<RegionVector> generateRegions(
    List<SpotVector> spots,
  ) {
    final Map<String, List<SpotVector>> grouped = {};

    // ============================================================
    // 지역별 그룹화
    // ============================================================

    for (final spot in spots) {
      if (spot.regionName.trim().isEmpty) {
        continue;
      }

      grouped.putIfAbsent(
        spot.regionName,
        () => [],
      );

      grouped[spot.regionName]!.add(spot);
    }

    // ============================================================
    // 지역별 평균 계산
    // ============================================================

    final List<RegionVector> regions = [];

    grouped.forEach(
      (regionName, spotList) {
        if (spotList.isEmpty) {
          return;
        }

        double nature = 0;
        double hidden = 0;
        double healing = 0;

        for (final spot in spotList) {
          nature += spot.nature;
          hidden += spot.hidden;
          healing += spot.healing;
        }

        final double count =
            spotList.length.toDouble();

        regions.add(
          RegionVector(
            regionName: regionName,
            nature: nature / count,
            hidden: hidden / count,
            healing: healing / count,
            congestion: 0,
          ),
        );
      },
    );

    return regions;
  }

  // ============================================================
  // TourismSpot List → SpotVector List
  //
  // API에서 받아온 관광지 전체를 한 번에 벡터화할 때 사용
  // ============================================================

  static List<SpotVector> generateSpotVectors(
    List<TourismSpot> spots,
  ) {
    final List<SpotVector> vectors = [];

    for (final spot in spots) {
      vectors.add(
        generateSpotVector(spot),
      );
    }

    return vectors;
  }

  // ============================================================
  // TourismSpot List → RegionVector List
  //
  // API 데이터에서 바로 지역 벡터까지 생성
  //
  // Tourism API
  //     ↓
  // TourismSpot
  //     ↓
  // SpotVector
  //     ↓
  // RegionVector
  // ============================================================

  static List<RegionVector> generateRegionsFromTourismSpots(
    List<TourismSpot> spots,
  ) {
    final spotVectors =
        generateSpotVectors(spots);

    return generateRegions(spotVectors);
  }
}