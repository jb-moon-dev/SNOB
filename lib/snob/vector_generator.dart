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
    // 1차 분류
    // ============================================================

    switch (spot.lclsSystm1) {
      case "NA":
        nature += 30;
        healing += 20;
        break;

      case "HS":
        hidden += 20;
        healing += 20;
        break;

      case "EX":
        hidden += 10;
        healing += 10;
        break;

      case "VE":
        nature += 20;
        healing -= 10;
        break;
    }

    // ============================================================
    // 2차 분류
    // ============================================================

    switch (spot.lclsSystm2) {
      case "NA01":
        nature += 20;
        healing += 20;
        hidden += 10;
        break;

      case "NA02":
        nature += 30;
        healing += 20;
        break;

      case "NA04":
        nature += 20;
        healing += 30;
        hidden += 10;
        break;

      case "HS01":
        hidden += 20;
        healing += 10;
        break;

      case "HS03":
        nature += 20;
        healing += 20;
        hidden += 20;
        break;

      case "EX07":
        hidden += 20;
        break;

      case "VE03":
        nature += 10;
        break;
    }

    // ============================================================
    // 3차 분류
    // ============================================================

    switch (spot.lclsSystm3) {
      case "NA010100":
        nature += 20;
        healing += 20;
        break;

      case "NA010300":
        nature += 20;
        healing += 20;
        break;

      case "NA010500":
        healing += 30;
        break;

      case "NA020700":
        nature += 20;
        break;

      case "NA020900":
        nature += 30;
        healing += 20;
        break;

      case "HS030100":
        healing += 40;
        break;

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
    // ⭐ 지역명 생성
    //
    // API가 준 지역 코드 + 관광지 주소를 사용한다.
    //
    // 주소의 첫 번째 지역명은 사용하지 않는다.
    //
    // 예:
    //
    // 코드 : 46
    // 주소 : 전남광주통합특별시 목포시 ...
    //
    // → 전라남도 목포시
    //
    // 코드 : 29
    // 주소 : 광주광역사 동구 ...
    //
    // → 광주광역시 동구
    //
    // 코드 : 36
    // → 세종특별자치시
    // ============================================================

    final String regionName =
        getExactRegionName(
      spot.lDongRegnCd,
      spot.lDongSignguCd,
      spot.address,
    );

    return SpotVector(
      spotName: spot.title,
      regionName: regionName,
      nature: nature,
      hidden: hidden,
      healing: healing,
      congestion: 0,
    );
  }

  // ============================================================
  // ⭐ 지역 코드 → 시도명
  //
  // lDongRegnCd만 사용해서
  // 시도 이름을 정확하게 결정한다.
  //
  // 주소에 잘못된 시도명이 들어와 있어도 무시한다.
  // ============================================================

  static String getSidoName(
    String regnCd,
  ) {
    final String code =
        regnCd.trim().padLeft(2, "0");

    switch (code) {
      case "11":
        return "서울특별시";

      case "26":
        return "부산광역시";

      case "27":
        return "대구광역시";

      case "28":
        return "인천광역시";

      case "29":
        return "광주광역시";

      case "30":
        return "대전광역시";

      case "31":
        return "울산광역시";

      case "36":
        return "세종특별자치시";

      case "41":
        return "경기도";

      case "42":
        return "강원특별자치도";

      case "43":
        return "충청북도";

      case "44":
        return "충청남도";

      case "45":
        return "전북특별자치도";

      case "46":
        return "전라남도";

      case "47":
        return "경상북도";

      case "48":
        return "경상남도";

      case "50":
        return "제주특별자치도";

      default:
        return "";
    }
  }

  // ============================================================
  // ⭐ 정확한 지역명 생성
  //
  // 핵심:
  //
  // 1. 시도명은 지역 코드로 결정
  // 2. 시군구명은 address의 두 번째 항목 사용
  // 3. 주소 첫 번째 항목은 절대 사용하지 않음
  //
  // 따라서 API 주소 데이터의 시도명이 이상해도
  // 지역 코드가 정확하면 정상적인 지역명이 만들어진다.
  // ============================================================

  static String getExactRegionName(
    String regnCd,
    String signguCd,
    String address,
  ) {
    final String sido =
        getSidoName(regnCd);

    if (sido.isEmpty) {
      return "";
    }

    // ==========================================================
    // 세종
    //
    // 세종은 일반적인 "시도 + 시군구" 구조가 아니다.
    //
    // 36 + 36110
    // → 세종특별자치시
    // ==========================================================

    if (regnCd.trim().padLeft(2, "0") == "36") {
      return "세종특별자치시";
    }

    // ==========================================================
    // 주소 정리
    // ==========================================================

    final String trimmed =
        address.trim();

    if (trimmed.isEmpty) {
      return "";
    }

    final List<String> parts =
        trimmed.split(RegExp(r'\s+'));

    // ==========================================================
    // 일반적인 주소
    //
    // "서울특별시 종로구 ..."
    // "광주광역시 동구 ..."
    // "전남광주통합특별시 목포시 ..."
    //
    // 어떤 시도명이 앞에 있든
    // 두 번째 항목을 시군구명으로 사용한다.
    // ==========================================================

    if (parts.length >= 2) {
      String sigungu =
          parts[1].trim();

      // ========================================================
      // 혹시 주소가 이상하게 들어와서
      // 두 번째 항목이 시군구가 아닌 경우 방어
      // ========================================================

      if (_isSigunguName(sigungu)) {
        return "$sido $sigungu";
      }

      // ========================================================
      // 예외적으로 첫 번째 항목이 시군구인 경우
      // ========================================================

      if (_isSigunguName(parts[0])) {
        return "$sido ${parts[0].trim()}";
      }
    }

    // ==========================================================
    // 주소에서 시군구를 찾지 못한 경우
    // ==========================================================
    //
    // 여기서는 잘못된 지역명을 만들어내지 않는다.
    // 빈 문자열을 반환하면 generateRegions()에서 제외된다.
    // ==========================================================

    return "";
  }

  // ============================================================
  // 시군구 이름인지 확인
  //
  // 예:
  // 종로구
  // 해운대구
  // 목포시
  // 수원시
  // 담양군
  // 제주도 예외 처리
  // ============================================================

  static bool _isSigunguName(
    String value,
  ) {
    final String text =
        value.trim();

    if (text.isEmpty) {
      return false;
    }

    return text.endsWith("시") ||
        text.endsWith("군") ||
        text.endsWith("구");
  }

  // ============================================================
  // SpotVector → RegionVector
  //
  // 같은 지역의 관광지를 하나의 지역으로 묶는다.
  //
  // 예:
  //
  // 광주광역시 동구
  // 광주광역시 동구
  // 광주광역시 동구
  //
  // ↓
  //
  // 광주광역시 동구
  //
  // 그리고 관광지 벡터의 평균을 계산한다.
  // ============================================================

  static List<RegionVector> generateRegions(
    List<SpotVector> spots,
  ) {
    final Map<String, List<SpotVector>> grouped =
        {};

    // ==========================================================
    // 지역별 그룹화
    // ==========================================================

    for (final SpotVector spot in spots) {
      final String region =
          spot.regionName.trim();

      if (region.isEmpty) {
        continue;
      }

      grouped.putIfAbsent(
        region,
        () => [],
      );

      grouped[region]!.add(spot);
    }

    // ==========================================================
    // 지역별 평균 계산
    // ==========================================================

    final List<RegionVector> regions = [];

    grouped.forEach(
      (
        String regionName,
        List<SpotVector> spotList,
      ) {
        if (spotList.isEmpty) {
          return;
        }

        double nature = 0;
        double hidden = 0;
        double healing = 0;

        for (final SpotVector spot
            in spotList) {
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

    // ==========================================================
    // 지역명 기준 정렬
    //
    // JSON을 만들 때 항상 일정한 순서로 저장되도록 한다.
    // ==========================================================

    regions.sort(
      (a, b) => a.regionName.compareTo(
        b.regionName,
      ),
    );

    return regions;
  }

  // ============================================================
  // TourismSpot List → SpotVector List
  // ============================================================

  static List<SpotVector> generateSpotVectors(
    List<TourismSpot> spots,
  ) {
    return spots
        .map(
          (spot) =>
              generateSpotVector(spot),
        )
        .toList();
  }

  // ============================================================
  // TourismSpot List → RegionVector List
  //
  // API에서 받은 관광지 전체를
  // 바로 지역 벡터로 변환할 때 사용
  // ============================================================

  static List<RegionVector>
      generateRegionsFromTourismSpots(
    List<TourismSpot> spots,
  ) {
    final List<SpotVector> spotVectors =
        generateSpotVectors(spots);

    return generateRegions(
      spotVectors,
    );
  }
}