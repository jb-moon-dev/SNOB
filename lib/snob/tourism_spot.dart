class TourismSpot {
  /// 관광지 ID
  final String contentId;

  /// 관광지명
  final String title;

  /// 주소
  final String address;

  /// 관광 타입
  final String contentTypeId;

  /// 법정동 시도 코드
  final String lDongRegnCd;

  /// 법정동 시군구 코드
  final String lDongSignguCd;

  /// 관광 분류체계
  final String lclsSystm1;
  final String lclsSystm2;
  final String lclsSystm3;

  /// 수정일
  final String modifiedTime;

  const TourismSpot({
    required this.contentId,
    required this.title,
    required this.address,
    required this.contentTypeId,
    required this.lDongRegnCd,
    required this.lDongSignguCd,
    required this.lclsSystm1,
    required this.lclsSystm2,
    required this.lclsSystm3,
    required this.modifiedTime,
  });

  @override
  String toString() {
    return """

===== Tourism Spot =====

이름 : $title

주소 : $address

contentId : $contentId

contentTypeId : $contentTypeId

법정동 시도 : $lDongRegnCd
법정동 시군구 : $lDongSignguCd

분류1 : $lclsSystm1
분류2 : $lclsSystm2
분류3 : $lclsSystm3

========================

""";
  }
}