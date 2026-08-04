class TourismSpot {


  // 관광지 ID (detailCommon2 호출용)
  final String contentId;


  // 관광지명
  final String title;


  // 주소
  final String address;


  // 지역명
  final String areaName;


  // 관광 타입
  final String contentTypeId;


  // 카테고리
  final String cat1;

  final String cat2;

  final String cat3;


  // 지역 코드
  final String areaCode;

  final String sigunguCode;


  // 수정일
  final String modifiedTime;



  const TourismSpot({

    required this.contentId,

    required this.title,

    required this.address,

    required this.areaName,

    required this.contentTypeId,

    required this.cat1,

    required this.cat2,

    required this.cat3,

    required this.areaCode,

    required this.sigunguCode,

    required this.modifiedTime,

  });



  @override
  String toString(){

    return """

===== Tourism Spot =====

이름 : $title

주소 : $address

지역 : $areaName

contentId : $contentId

contentTypeId : $contentTypeId

cat1 : $cat1

cat2 : $cat2

cat3 : $cat3

========================

""";

  }


}